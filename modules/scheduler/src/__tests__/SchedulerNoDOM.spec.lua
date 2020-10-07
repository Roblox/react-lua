-- upstream https://github.com/facebook/react/blob/3e94bce765d355d74f6a60feb4addb6d196e3482/packages/scheduler/src/__tests__/SchedulerNoDOM-test.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @emails react-core
]]
-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
-- use custom matchers added via `expect.extend`
--!nocheck

return function()
	local Workspace = script.Parent.Parent.Parent
	local makeTimerImpl = require(Workspace.JSPolyfill.Timers.makeTimerImpl)
	local SchedulerHostConfig = require(script.Parent.Parent.SchedulerHostConfig)
	local Scheduler = require(script.Parent.Parent.Scheduler)

	local scheduleCallback
	local ImmediatePriority
	local UserBlockingPriority
	local NormalPriority

	local mockTime, timeouts

	local function runAllTimers()
		local timeoutsRemaining = true
		repeat
			mockTime += 16.67
			timeoutsRemaining = false
			for _, update in pairs(timeouts) do
				timeoutsRemaining = true
				update(mockTime)
			end
		until not timeoutsRemaining
	end

	local function mockDelay(delayTime, callback)
		local targetTime = mockTime + delayTime
		timeouts[callback] = function(currentTime: number)
			if currentTime >= targetTime then
				callback()
				timeouts[callback] = nil
			end
		end
	end

	beforeEach(function()
		mockTime = 0
		timeouts = {}
		local Timers = makeTimerImpl(mockDelay)
		local HostConfig = SchedulerHostConfig.makeDefaultWithArgs(Timers, function()
			return mockTime
		end)
		local SchedulerInstance = Scheduler.makeSchedulerWithArgs(HostConfig)

		scheduleCallback = SchedulerInstance.unstable_scheduleCallback
		ImmediatePriority = SchedulerInstance.unstable_ImmediatePriority
		UserBlockingPriority = SchedulerInstance.unstable_UserBlockingPriority
		NormalPriority = SchedulerInstance.unstable_NormalPriority
	end)

	it('runAllTimers flushes all scheduled callbacks', function()
		local log = {}
		scheduleCallback(NormalPriority, function()
			table.insert(log, 'A')
		end)
		scheduleCallback(NormalPriority, function()
			table.insert(log, 'B')
		end)
		scheduleCallback(NormalPriority, function()
			table.insert(log, 'C')
		end)

		expect(log).toEqual({})

		runAllTimers()

		expect(log).toEqual({'A', 'B', 'C'})
	end)

	it('executes callbacks in order of priority', function()
		local log = {}

		scheduleCallback(NormalPriority, function()
			table.insert(log, 'A')
		end)
		scheduleCallback(NormalPriority, function()
			table.insert(log, 'B')
		end)
		scheduleCallback(UserBlockingPriority, function()
			table.insert(log, 'C')
		end)
		scheduleCallback(UserBlockingPriority, function()
			table.insert(log, 'D')
		end)

		expect(log).toEqual({})
		runAllTimers()
		expect(log).toEqual({'C', 'D', 'A', 'B'})
	end)

	it('handles errors', function()
		local log = {}

		scheduleCallback(ImmediatePriority, function()
			table.insert(log, 'A')
			error('Oops A')
		end)
		scheduleCallback(ImmediatePriority, function()
			table.insert(log, 'B')
		end)
		scheduleCallback(ImmediatePriority, function()
			table.insert(log, 'C')
			error('Oops C')
		end)

		expect(runAllTimers).toThrow('Oops A')
		expect(log).toEqual({'A'})

		log = {}

		-- B and C flush in a subsequent event. That way, the second error is not
		-- swallowed.
		expect(function()
			runAllTimers()
		end).toThrow('Oops C')
		expect(log).toEqual({'B', 'C'})
	end)
end
