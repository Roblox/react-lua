local SchedulerHostConfig = require(script.Parent.SchedulerHostConfig)

local requestHostCallback = SchedulerHostConfig.requestHostCallback
local requestHostTimeout = SchedulerHostConfig.requestHostTimeout
local cancelHostTimeout = SchedulerHostConfig.cancelHostTimeout
local shouldYieldToHost = SchedulerHostConfig.shouldYieldToHost
local getCurrentTime = SchedulerHostConfig.getCurrentTime
local forceFrameRate = SchedulerHostConfig.forceFrameRate
local requestPaint = SchedulerHostConfig.requestPaint

-- TODO: Use symbols?
local SchedulerPriorities = require(script.Parent.SchedulerPriorities)

local ImmediatePriority = SchedulerPriorities.ImmediatePriority
local UserBlockingPriority = SchedulerPriorities.UserBlockingPriority
local NormalPriority = SchedulerPriorities.NormalPriority
local LowPriority = SchedulerPriorities.LowPriority
local IdlePriority = SchedulerPriorities.IdlePriority

-- TODO(align): Right now, this is mimicking the js as closely as possible;
-- typically, the lua-y way to do things would be to refer to these as members.
-- Which should we use?
local SchedulerMinHeap = require(script.Parent.SchedulerMinHeap)
local push, peek, pop = SchedulerMinHeap.push, SchedulerMinHeap.peek, SchedulerMinHeap.pop

-- Max 31 bit integer. The max integer size in V8 for 32-bit systems.
-- Math.pow(2, 30) - 1
-- 0b111111111111111111111111111111
local maxSigned31BitInt = 1073741823

-- Times out immediately
local IMMEDIATE_PRIORITY_TIMEOUT = -1
-- Eventually times out
local USER_BLOCKING_PRIORITY_TIMEOUT = 250
local NORMAL_PRIORITY_TIMEOUT = 5000
local LOW_PRIORITY_TIMEOUT = 10000
-- Never times out
local IDLE_PRIORITY_TIMEOUT = maxSigned31BitInt

-- Tasks are stored on a min heap
local taskQueue = {}
local timerQueue = {}

-- Incrementing id counter. Used to maintain insertion order.
local taskIdCounter = 1

-- Pausing the scheduler is useful for debugging.
local isSchedulerPaused = false

local currentTask = nil
local currentPriorityLevel = NormalPriority

-- This is set while performing work, to prevent re-entrancy.
local isPerformingWork = false

local isHostCallbackScheduled = false
local isHostTimeoutScheduled = false

local function advanceTimers(currentTime)
	-- Check for tasks that are no longer delayed and add them to the queue.
	local timer = peek(timerQueue)

	while timer ~= nil do
		if timer.callback == nil then
			-- Timer was cancelled, remove from queue
			pop(timerQueue)
		elseif timer.startTime <= currentTime then
			-- Timer fired. Transfer to the task queue.
			pop(timerQueue)
			timer.sortIndex = timer.expirationTime

			push(taskQueue, timer)
		else
			-- Remaining timers are pending.
			return;
		end

		timer = peek(timerQueue)
	end
end

local function handleTimeout(currentTime)
	isHostTimeoutScheduled = false
	advanceTimers(currentTime)

	if not isHostCallbackScheduled then
		if peek(taskQueue) ~= nil then
			isHostCallbackScheduled = true
			requestHostCallback(flushWork)
		else
			local firstTimer = peek(timerQueue)
			if firstTimer ~= nil then
				requestHostTimeout(handleTimeout, firstTimer.startTime - currentTime);
			end
		end
	end
end

function flushWork(hasTimeRemaining, initialTime)
	-- We'll need a host callback the next time work is scheduled.
	isHostCallbackScheduled = false
	if isHostTimeoutScheduled then
		-- We scheduled a timeout but it's no longer needed. Cancel it.
		isHostTimeoutScheduled = false
		cancelHostTimeout()
	end

	isPerformingWork = true
	local previousPriorityLevel = currentPriorityLevel
	-- TODO(align): Does this really just not care about the failure case?
	local ok, result = pcall(function()
		-- No catch in prod code path.
		return workLoop(hasTimeRemaining, initialTime)
	end)

	currentTask = nil
	currentPriorityLevel = previousPriorityLevel
	isPerformingWork = false

	if not ok then
		error(result)
	end
end

function workLoop(hasTimeRemaining, initialTime)
	local currentTime = initialTime
	advanceTimers(currentTime)
	currentTask = peek(taskQueue)
	while currentTask ~= nil and not isSchedulerPaused do
		if
			currentTask.expirationTime > currentTime and
			(not hasTimeRemaining or shouldYieldToHost())
		then
			-- This currentTask hasn't expired, and we've reached the deadline.
			break;
		end

		local callback = currentTask.callback
		if typeof(callback) == "function" then
			currentTask.callback = nil
			currentPriorityLevel = currentTask.priorityLevel

			local didUserCallbackTimeout = currentTask.expirationTime <= currentTime
			-- With `enableProfiling` flag logic removed, this is a no-op
			-- markTaskRun(currentTask, currentTime)

			local continuationCallback = callback(didUserCallbackTimeout)
			currentTime = getCurrentTime()

			if typeof(continuationCallback) == "function" then
				currentTask.callback = continuationCallback
				-- With `enableProfiling` flag logic removed, this is a no-op
				-- markTaskYield(currentTask, currentTime)
			else
				if currentTask == peek(taskQueue) then
					pop(taskQueue)
				end
			end
			advanceTimers(currentTime)
		else
			pop(taskQueue)
		end

		currentTask = peek(taskQueue)
	end

	-- Return whether there's additional work
	if currentTask ~= nil then
		return true
	else
		local firstTimer = peek(timerQueue)
		if firstTimer ~= nil then
			requestHostTimeout(handleTimeout, firstTimer.startTime - currentTime)
		end

		return false
	end
end

function unstable_runWithPriority(priorityLevel, eventHandler)
	if
		priorityLevel == ImmediatePriority or
		priorityLevel == UserBlockingPriority or
		priorityLevel == NormalPriority or
		priorityLevel == LowPriority or
		priorityLevel == IdlePriority
	then
		-- Leave priority alone if assigned
	else
		priorityLevel = NormalPriority
	end

	local previousPriorityLevel = currentPriorityLevel
	currentPriorityLevel = priorityLevel

	local ok, result = pcall(eventHandler)
	currentPriorityLevel = previousPriorityLevel

	if not ok then
		error(result)
	end

	return result
end

function unstable_next(eventHandler)
	local priorityLevel
	if
		currentPriorityLevel == ImmediatePriority or
		currentPriorityLevel == UserBlockingPriority or
		currentPriorityLevel == NormalPriority
	then
		-- Shift down to normal priority
		priorityLevel = NormalPriority
	else
		-- Anything lower than normal priority should remain at the current level.
		priorityLevel = currentPriorityLevel
	end

	local previousPriorityLevel = currentPriorityLevel
	currentPriorityLevel = priorityLevel

	local ok, result = pcall(eventHandler)
	currentPriorityLevel = previousPriorityLevel

	if not ok then
		error(result)
	end

	return result
end

function unstable_wrapCallback(callback)
	local parentPriorityLevel = currentPriorityLevel

	return function()
		-- This is a fork of runWithPriority, inlined for performance.
		local previousPriorityLevel = currentPriorityLevel
		currentPriorityLevel = parentPriorityLevel

		local ok, result = pcall(function()
			return callback()
		end)

		currentPriorityLevel = previousPriorityLevel

		-- (align): A bit unclear what to do in this case; original logic
		-- returns result regardless, but in our case it may be an error. Since
		-- the original code has no catch, this seems like the correct approach.
		if not ok then
			error(result)
		end

		return result
	end
end

function unstable_scheduleCallback(priorityLevel, callback, options)
	local currentTime = getCurrentTime()

	local startTime
	-- TODO(align): VALIDATE conversion from `typeof options === "table" && options !== null`
	if typeof(options) == "table" then
		local delay = options.delay
		if typeof(delay) == "number" and delay > 0 then
			startTime = currentTime + delay
		else
			startTime = currentTime
		end
	else
		startTime = currentTime
	end

	local timeout
	if priorityLevel == ImmediatePriority then
		timeout = IMMEDIATE_PRIORITY_TIMEOUT
	elseif priorityLevel == UserBlockingPriority then
		timeout = USER_BLOCKING_PRIORITY_TIMEOUT
	elseif priorityLevel == IdlePriority then
		timeout = IDLE_PRIORITY_TIMEOUT
	elseif priorityLevel == LowPriority then
		timeout = LOW_PRIORITY_TIMEOUT
	else
		timeout = NORMAL_PRIORITY_TIMEOUT
	end

	local expirationTime = startTime + timeout;

	local newTask = {
		id = taskIdCounter,
		callback = callback,
		priorityLevel = priorityLevel,
		startTime = startTime,
		expirationTime = expirationTime,
		sortIndex = -1,
	}
	taskIdCounter = taskIdCounter + 1

	if startTime > currentTime then
		-- This is a delayed task.
		newTask.sortIndex = startTime

		push(timerQueue, newTask)
		-- TODO(align): VALIDATE conversion from `peek(taskQueue) === null && newTask === peek(timerQueue)`
		if #taskQueue == 0 and newTask == peek(timerQueue) then
			-- All tasks are delayed, and this is the task with the earliest delay.
			if isHostTimeoutScheduled then
				-- Cancel an existing timeout.
				cancelHostTimeout()
			else
				isHostTimeoutScheduled = true
			end
			-- Schedule a timeout.
			requestHostTimeout(handleTimeout, startTime - currentTime)
		end
	else
		newTask.sortIndex = expirationTime
		push(taskQueue, newTask)
		-- Schedule a host callback, if needed. If we're already performing work,
		-- wait until the next time we yield.
		if not isHostCallbackScheduled and not isPerformingWork then
			isHostCallbackScheduled = true
			requestHostCallback(flushWork)
		end
	end

	return newTask
end

function unstable_pauseExecution()
	isSchedulerPaused = true
end

function unstable_continueExecution()
	isSchedulerPaused = false
	if not isHostCallbackScheduled and not isPerformingWork then
		isHostCallbackScheduled = true
		requestHostCallback(flushWork)
	end
end

function unstable_getFirstCallbackNode()
	return peek(taskQueue)
end

function unstable_cancelCallback(task)
	-- Null out the callback to indicate the task has been canceled. (Can't
	-- remove from the queue because you can't remove arbitrary nodes from an
	-- array based heap, only the first one.)
	task.callback = nil
end

function unstable_getCurrentPriorityLevel()
	return currentPriorityLevel
end

local unstable_requestPaint = requestPaint

return {
	unstable_ImmediatePriority = ImmediatePriority,
	unstable_UserBlockingPriority = UserBlockingPriority,
	unstable_NormalPriority = NormalPriority,
	unstable_IdlePriority = IdlePriority,
	unstable_LowPriority = LowPriority,
	unstable_runWithPriority = unstable_runWithPriority,
	unstable_next = unstable_next,
	unstable_scheduleCallback = unstable_scheduleCallback,
	unstable_cancelCallback = unstable_cancelCallback,
	unstable_wrapCallback = unstable_wrapCallback,
	unstable_getCurrentPriorityLevel = unstable_getCurrentPriorityLevel,
	unstable_shouldYield = shouldYieldToHost,
	unstable_requestPaint = unstable_requestPaint,
	unstable_continueExecution = unstable_continueExecution,
	unstable_pauseExecution = unstable_pauseExecution,
	unstable_getFirstCallbackNode = unstable_getFirstCallbackNode,
	unstable_now = getCurrentTime,
	unstable_forceFrameRate = forceFrameRate,
}
