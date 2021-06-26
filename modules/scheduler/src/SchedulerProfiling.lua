-- upstream https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/SchedulerProfiling.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local SchedulerPriorities = require(script.Parent.SchedulerPriorities)
type PriorityLevel = SchedulerPriorities.PriorityLevel

local ScheduleFeatureFlags = require(script.Parent.SchedulerFeatureFlags)
local enableProfiling = ScheduleFeatureFlags.enableProfiling

local NoPriority = SchedulerPriorities.NoPriority

local runIdCounter: number = 0
local mainThreadIdCounter: number = 0

-- local profilingStateSize = 4

-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. tostring(message))
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local exports = {}

if enableProfiling then
	exports.sharedProfilingBuffer = {}
else
	exports.sharedProfilingBuffer = nil
end

-- ROBLOX deviation: just use an array
-- local profilingState =
--   enableProfiling && sharedProfilingBuffer !== null
--     ? new Int32Array(sharedProfilingBuffer)
--     : []; // We can't read this but it helps save bytes for null checks

local profilingState = {}

local PRIORITY = 0
local CURRENT_TASK_ID = 1
local CURRENT_RUN_ID = 2
local QUEUE_SIZE = 3

if enableProfiling then
	profilingState[PRIORITY] = NoPriority
	-- This is maintained with a counter, because the size of the priority queue
	-- array might include canceled tasks.
	profilingState[QUEUE_SIZE] = 0
	profilingState[CURRENT_TASK_ID] = 0
end

-- Bytes per element is 4
local INITIAL_EVENT_LOG_SIZE = 131072
local MAX_EVENT_LOG_SIZE = 524288 -- Equivalent to 2 megabytes

local eventLogSize = 0
local eventLogBuffer = nil
local eventLog = nil
local eventLogIndex = 0

local TaskStartEvent = 1
local TaskCompleteEvent = 2
local TaskErrorEvent = 3
local TaskCancelEvent = 4
local TaskRunEvent = 5
local TaskYieldEvent = 6
local SchedulerSuspendEvent = 7
local SchedulerResumeEvent = 8

local function logEvent(entries)
	unimplemented("SchedulerProfiling:logEvent")
	if eventLog ~= nil then
		local offset = eventLogIndex
		eventLogIndex += #entries
		if eventLogIndex + 1 > eventLogSize then
			eventLogSize *= 2
			if eventLogSize > MAX_EVENT_LOG_SIZE then
				-- Using console['error'] to evade Babel and ESLint
				console["error"](
					"Scheduler Profiling: Event log exceeded maximum size. Don't "
						.. "forget to call `stopLoggingProfilingEvents()`."
				)
				exports.stopLoggingProfilingEvents()
				return
			end
			local newEventLog = {}
			table.insert(newEventLog, eventLog)
			eventLogBuffer = newEventLog.buffer
			eventLog = newEventLog
		end
		table.insert(eventLog, entries, offset)
	end
end

exports.startLoggingProfilingEvents = function()
	eventLogSize = INITIAL_EVENT_LOG_SIZE
	eventLogBuffer = {}
	eventLog = {}
	eventLogIndex = 0
end

exports.stopLoggingProfilingEvents = function()
	local buffer = eventLogBuffer
	eventLogSize = 0
	eventLogBuffer = nil
	eventLog = nil
	eventLogIndex = 0
	return buffer
end

exports.markTaskStart = function(task, ms: number)
	if enableProfiling then
		profilingState[QUEUE_SIZE] += 1

		if eventLog ~= nil then
			-- performance.now returns a float, representing milliseconds. When the
			-- event is logged, it's coerced to an int. Convert to microseconds to
			-- maintain extra degrees of precision.
			logEvent({ TaskStartEvent, ms * 1000, task.id, task.priorityLevel })
		end
	end
end

exports.markTaskCompleted = function(task, ms: number)
	if enableProfiling then
		profilingState[PRIORITY] = NoPriority
		profilingState[CURRENT_TASK_ID] = 0
		profilingState[QUEUE_SIZE] -= 1

		if eventLog ~= nil then
			-- performance.now returns a float, representing milliseconds. When the
			-- event is logged, it's coerced to an int. Convert to microseconds to
			-- maintain extra degrees of precision.
			logEvent({ TaskCompleteEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskCanceled = function(task, ms: number)
	if enableProfiling then
		profilingState[QUEUE_SIZE] -= 1

		if eventLog ~= nil then
			logEvent({ TaskCancelEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskErrored = function(task, ms: number)
	if enableProfiling then
		profilingState[PRIORITY] = NoPriority
		profilingState[CURRENT_TASK_ID] = 0
		profilingState[QUEUE_SIZE] -= 1

		if eventLog ~= nil then
			logEvent({ TaskErrorEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskRun = function(task, ms: number)
	if enableProfiling then
		runIdCounter += 1

		profilingState[PRIORITY] = task.priorityLevel
		profilingState[CURRENT_TASK_ID] = task.id
		profilingState[CURRENT_RUN_ID] = runIdCounter

		if eventLog ~= nil then
			logEvent({ TaskRunEvent, ms * 1000, task.id, runIdCounter })
		end
	end
end

exports.markTaskYield = function(task, ms: number)
	if enableProfiling then
		profilingState[PRIORITY] = NoPriority
		profilingState[CURRENT_TASK_ID] = 0
		profilingState[CURRENT_RUN_ID] = 0

		if eventLog ~= nil then
			logEvent({ TaskYieldEvent, ms * 1000, task.id, runIdCounter })
		end
	end
end

exports.markSchedulerSuspended = function(ms: number)
	if enableProfiling then
		mainThreadIdCounter += 1

		if eventLog ~= nil then
			logEvent({ SchedulerSuspendEvent, ms * 1000, mainThreadIdCounter })
		end
	end
end

exports.markSchedulerUnsuspended = function(ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ SchedulerResumeEvent, ms * 1000, mainThreadIdCounter })
		end
	end
end

return exports
