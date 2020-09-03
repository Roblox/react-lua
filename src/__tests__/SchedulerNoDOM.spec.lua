--!strict
return function()
	local Timeout = require(script.Parent.Parent.Timeout)
	local makeHostConfig = require(script.Parent.Parent.SchedulerHostConfig)
	local makeScheduler = require(script.Parent.Parent.Scheduler)

	local scheduleCallback
	local ImmediatePriority
	local UserBlockingPriority
	local NormalPriority

	describe('SchedulerNoDOM', function()
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
			print("Running callback in", delayTime, "simulated seconds...")
			timeouts[callback] = function(time: number)
				if time >= targetTime then
					callback()
					timeouts[callback] = nil
				end
			end
		end

		local function shallowEqual(a, b)
			if a == b then
				return true
			end

			for key, value in pairs(a) do
				if b[key] ~= value then
					return false
				end
			end

			for key, value in pairs(b) do
				if a[key] ~= value then
					return false
				end
			end

			return true
		end

		beforeEach(function()
			mockTime = 0
			timeouts = {}
			getfenv(Timeout.setTimeout).delay = mockDelay

			local HostConfig = makeHostConfig(function()
				return mockTime
			end)
			local Scheduler = makeScheduler(HostConfig)

			scheduleCallback = Scheduler.unstable_scheduleCallback
			ImmediatePriority = Scheduler.unstable_ImmediatePriority
			UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
			NormalPriority = Scheduler.unstable_NormalPriority
		end)

		afterEach(function()
			getfenv(Timeout.setTimeout).delay = delay
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

			assert(shallowEqual(log, {}))

			runAllTimers()

			assert(shallowEqual(log, {'A', 'B', 'C'}))
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

			assert(shallowEqual(log, {}))
			runAllTimers()
			assert(shallowEqual(log, {'C', 'D', 'A', 'B'}))
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

			expect(runAllTimers).to.throw()
			assert(shallowEqual(log, {'A'}))

			log = {}

			-- B and C flush in a subsequent event. That way, the second error is not
			-- swallowed.
			expect(function()
				runAllTimers()
			end).to.throw()
			assert(shallowEqual(log, {'B', 'C'}))
		end)
	end)
end