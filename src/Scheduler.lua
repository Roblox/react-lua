-- import {
-- enableSchedulerDebugging,
-- enableProfiling,
-- } from './SchedulerFeatureFlags';
-- import {
-- requestHostCallback,
-- requestHostTimeout,
-- cancelHostTimeout,
-- shouldYieldToHost,
-- getCurrentTime,
-- forceFrameRate,
-- requestPaint,
-- } from './SchedulerHostConfig';
-- import {push, pop, peek} from './SchedulerMinHeap';

-- -- TODO: Use symbols?
-- import {
-- ImmediatePriority,
-- UserBlockingPriority,
-- NormalPriority,
-- LowPriority,
-- IdlePriority,
-- } from './SchedulerPriorities';
-- import {
-- sharedProfilingBuffer,
-- markTaskRun,
-- markTaskYield,
-- markTaskCompleted,
-- markTaskCanceled,
-- markTaskErrored,
-- markSchedulerSuspended,
-- markSchedulerUnsuspended,
-- markTaskStart,
-- stopLoggingProfilingEvents,
-- startLoggingProfilingEvents,
-- } from './SchedulerProfiling';

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

local currentTask = null
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
			if enableProfiling then
				markTaskStart(timer, currentTime)
				timer.isQueued = true
			end
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
	if enableProfiling then
		markSchedulerUnsuspended(initialTime)
	end

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
		if enableProfiling then
			local ok, result = pcall(function()
				return workLoop(hasTimeRemaining, initialTime)
			end)

			if not ok then
				if currentTask ~= nil then
					local currentTime = getCurrentTime()
					markTaskErrored(currentTask, currentTime)
					currentTask.isQueued = false
				end
				error(result)
			end
		else
			-- No catch in prod code path.
			return workLoop(hasTimeRemaining, initialTime)
		end
	end)

	currentTask = null
	currentPriorityLevel = previousPriorityLevel
	isPerformingWork = false
	if enableProfiling then
		local currentTime = getCurrentTime()
		markSchedulerSuspended(currentTime)
	end

	if not ok then
		error(result)
	end
end

function workLoop(hasTimeRemaining, initialTime)
	local currentTime = initialTime
	advanceTimers(currentTime)
	currentTask = peek(taskQueue)
	while
		currentTask ~= nil and
		not (enableSchedulerDebugging and isSchedulerPaused)
	do
		if
			currentTask.expirationTime > currentTime and
			(not hasTimeRemaining or shouldYieldToHost())
		then
			-- This currentTask hasn't expired, and we've reached the deadline.
			break;
		end

		local callback = currentTask.callback
		if typeof(callback) == "function" then
			currentTask.callback = null
			currentPriorityLevel = currentTask.priorityLevel

			local didUserCallbackTimeout = currentTask.expirationTime <= currentTime
			markTaskRun(currentTask, currentTime)

			local continuationCallback = callback(didUserCallbackTimeout)
			currentTime = getCurrentTime()

			if typeof(continuationCallback) == "function" then
				currentTask.callback = continuationCallback
				markTaskYield(currentTask, currentTime)
			else
				if enableProfiling then
					markTaskCompleted(currentTask, currentTime)
					currentTask.isQueued = false
				end
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
			return callback.apply(this, arguments)
		end)

		currentPriorityLevel = previousPriorityLevel

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

	if enableProfiling then
		newTask.isQueued = false
	end

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
		if enableProfiling then
			markTaskStart(newTask, currentTime)
			newTask.isQueued = true
		end
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
	if enableProfiling then
		if task.isQueued then
			local currentTime = getCurrentTime()
			markTaskCanceled(task, currentTime)
			task.isQueued = false
		end
	end

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

-- export const unstable_Profiling = enableProfiling
-- ? {
-- 	startLoggingProfilingEvents,
-- 	stopLoggingProfilingEvents,
-- 	sharedProfilingBuffer,
-- 	end
-- : null;
