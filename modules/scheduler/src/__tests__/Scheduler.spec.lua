-- upstream https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/__tests__/Scheduler-test.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @emails react-core
]]
-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
--use custom matchers added via `expect.extend`
--!nocheck

return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)

	local Scheduler
	local runWithPriority
	local ImmediatePriority
	local UserBlockingPriority
	local NormalPriority
	-- deviation: These are only used in a commented-out __DEV__-only test
	-- (commented out to silence lints)
	-- local LowPriority
	-- local IdlePriority
	local scheduleCallback
	local cancelCallback
	local wrapCallback
	local getCurrentPriorityLevel
	local shouldYield

	local function shift(list)
		local first = list[1]
		local newLength = #list - 1

		for i = 1, newLength do
			list[i] = list[i+1]
		end

		-- We need to explicitly nil out the end of the list
		list[newLength + 1] = nil

		return first
	end

	beforeEach(function()
		RobloxJest.resetModules()
		-- deviation: In react, this mock is applied by replacing the
		-- `SchedulerHostConfig.js` file during build scripts
		RobloxJest.mock(script.Parent.Parent.SchedulerHostConfig, function()
			return require(script.Parent.Parent.forks["SchedulerHostConfig.mock"])
		end)
		-- deviation: In react, jest mocks Scheduler -> unstable_mock; since
		-- unstable_mock depends on the real Scheduler, and our mock
		-- functionality isn't smart enough to prevent self-requires, we simply
		-- require the mock entry point directly for use in tests
		Scheduler = require(script.Parent.Parent.unstable_mock)

		runWithPriority = Scheduler.unstable_runWithPriority
		ImmediatePriority = Scheduler.unstable_ImmediatePriority
		UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
		NormalPriority = Scheduler.unstable_NormalPriority
		-- deviation: These are only used in a commented-out __DEV__-only
		-- test (commented out to silence lints)
		-- LowPriority = Scheduler.unstable_LowPriority
		-- IdlePriority = Scheduler.unstable_IdlePriority
		scheduleCallback = Scheduler.unstable_scheduleCallback
		cancelCallback = Scheduler.unstable_cancelCallback
		wrapCallback = Scheduler.unstable_wrapCallback
		getCurrentPriorityLevel = Scheduler.unstable_getCurrentPriorityLevel
		shouldYield = Scheduler.unstable_shouldYield
	end)

	it("flushes work incrementally", function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('A')
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('B')
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('C')
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('D')
		end)

		expect(Scheduler).toFlushAndYieldThrough({'A', 'B'})
		expect(Scheduler).toFlushAndYieldThrough({'C'})
		expect(Scheduler).toFlushAndYield({'D'})
	end)

	it("cancels work", function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('A')
		end)
		local callbackHandleB = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('B')
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('C')
		end)

		cancelCallback(callbackHandleB)

		expect(Scheduler).toFlushAndYield({
			'A',
			-- B should have been cancelled
			'C',
		})
	end)

	it("executes the highest priority callbacks first", function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('A')
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('B')
		end)

		-- Yield before B is flushed
		expect(Scheduler).toFlushAndYieldThrough({'A'})

		scheduleCallback(UserBlockingPriority, function()
			Scheduler.unstable_yieldValue('C')
		end)
		scheduleCallback(UserBlockingPriority, function()
			Scheduler.unstable_yieldValue('D')
		end)

		-- C and D should come first, because they are higher priority
		expect(Scheduler).toFlushAndYield({'C', 'D', 'B'})
	end)

	it("expires work", function()
		scheduleCallback(NormalPriority, function(didTimeout)
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue(("A (did timeout: %s)"):format(tostring(didTimeout)))
		end)
		scheduleCallback(UserBlockingPriority, function(didTimeout)
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue(("B (did timeout: %s)"):format(tostring(didTimeout)))
		end)
		scheduleCallback(UserBlockingPriority, function(didTimeout)
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue(("C (did timeout: %s)"):format(tostring(didTimeout)))
		end)

		-- Advance time, but not by enough to expire any work
		Scheduler.unstable_advanceTime(249)
		expect(Scheduler).toHaveYielded({})

		-- Schedule a few more callbacks
		scheduleCallback(NormalPriority, function(didTimeout)
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue(("D (did timeout: %s)"):format(tostring(didTimeout)))
		end)
		scheduleCallback(NormalPriority, function(didTimeout)
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue(("E (did timeout: %s)"):format(tostring(didTimeout)))
		end)

		-- Advance by just a bit more to expire the user blocking callbacks
		Scheduler.unstable_advanceTime(1)
		expect(Scheduler).toFlushExpired({
			'B (did timeout: true)',
			'C (did timeout: true)',
		})

		-- Expire A
		Scheduler.unstable_advanceTime(4600)
		expect(Scheduler).toFlushExpired({'A (did timeout: true)'})

		-- Flush the rest without expiring
		expect(Scheduler).toFlushAndYield({
			'D (did timeout: false)',
			'E (did timeout: true)',
		})
	end)

	it('has a default expiration of ~5 seconds', function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('A')
		end)

		Scheduler.unstable_advanceTime(4999)
		expect(Scheduler).toHaveYielded({})

		Scheduler.unstable_advanceTime(1)
		expect(Scheduler).toFlushExpired({'A'})
	end)

	it("continues working on same task after yielding", function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue('A')
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue('B')
		end)

		local didYield = false
		local tasks = {
			{'C1', 100},
			{'C2', 100},
			{'C3', 100},
		}
		local function C()
			while #tasks > 0 do
				local label, ms = unpack(shift(tasks))
				Scheduler.unstable_advanceTime(ms)
				Scheduler.unstable_yieldValue(label)
				if shouldYield() then
					didYield = true
					return C
				end
			end

			return nil
		end

		scheduleCallback(NormalPriority, C)

		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue('D')
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue('E')
		end)

		-- Flush, then yield while in the middle of C.
		expect(didYield).to.equal(false)
		expect(Scheduler).toFlushAndYieldThrough({'A', 'B', 'C1'})
		expect(didYield).to.equal(true)

		-- When we resume, we should continue working on C.
		expect(Scheduler).toFlushAndYield({'C2', 'C3', 'D', 'E'})
	end)

	it("continuation callbacks inherit the expiration of the previous callback", function()
		local tasks = {
			{'A', 125},
			{'B', 124},
			{'C', 100},
			{'D', 100},
		}
		local function work()
			while #tasks > 0 do
				local label, ms = unpack(shift(tasks))
				Scheduler.unstable_advanceTime(ms)
				Scheduler.unstable_yieldValue(label)
				if shouldYield() then
					return work
				end
			end

			return nil
		end

		-- Schedule a high priority callback
		scheduleCallback(UserBlockingPriority, work)

		-- Flush until just before the expiration time
		expect(Scheduler).toFlushAndYieldThrough({'A', 'B'})

		-- Advance time by just a bit more. This should expire all the remaining work.
		Scheduler.unstable_advanceTime(1)
		expect(Scheduler).toFlushExpired({'C', 'D'})
	end)

	it("continuations are interrupted by higher priority work", function()
		local tasks = {
			{'A', 100},
			{'B', 100},
			{'C', 100},
			{'D', 100},
		}
		local function work()
			while #tasks > 0 do
				local label, ms = unpack(shift(tasks))
				Scheduler.unstable_advanceTime(ms)
				Scheduler.unstable_yieldValue(label)
				if #tasks > 0 and shouldYield() then
					return work
				end
			end

			return nil
		end
		scheduleCallback(NormalPriority, work)
		expect(Scheduler).toFlushAndYieldThrough({'A'})

		scheduleCallback(UserBlockingPriority, function()
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue('High pri')
		end)

		expect(Scheduler).toFlushAndYield({'High pri', 'B', 'C', 'D'})
	end)

	it('continuations do not block higher priority work scheduled ' ..
			'inside an executing callback',
		function()
			local tasks = {
				{'A', 100},
				{'B', 100},
				{'C', 100},
				{'D', 100},
			}
			local function work()
				while #tasks > 0 do
					local task = shift(tasks)
					local label, ms = unpack(task)
					Scheduler.unstable_advanceTime(ms)
					Scheduler.unstable_yieldValue(label)
					if label == 'B' then
						-- Schedule high pri work from inside another callback
						Scheduler.unstable_yieldValue('Schedule high pri')
						scheduleCallback(UserBlockingPriority, function()
							Scheduler.unstable_advanceTime(100)
							Scheduler.unstable_yieldValue('High pri')
						end)
					end
					if #tasks > 0 then
						-- Return a continuation
						return work
					end
				end

				return nil
			end
			scheduleCallback(NormalPriority, work)
			expect(Scheduler).toFlushAndYield({
				'A',
				'B',
				'Schedule high pri',
				-- The high pri callback should fire before the continuation of the
				-- lower pri work
				'High pri',
				-- Continue low pri work
				'C',
				'D',
			})
		end
	)

	it("cancelling a continuation", function()
		local task = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue('Yield')
			return function()
				Scheduler.unstable_yieldValue('Continuation')
			end
		end)

		expect(Scheduler).toFlushAndYieldThrough({'Yield'})
		cancelCallback(task)
		expect(Scheduler).toFlushWithoutYielding()
	end)

	it('top-level immediate callbacks fire in a subsequent task', function()
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('A')
		end)
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('B')
		end)
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('C')
		end)
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('D')
		end)
		-- Immediate callback hasn't fired, yet.
		expect(Scheduler).toHaveYielded({})
		-- They all flush immediately within the subsequent task.
		expect(Scheduler).toFlushExpired({'A', 'B', 'C', 'D'})
	end)

	it("nested immediate callbacks are added to the queue of immediate callbacks", function()
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('A')
		end)
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('B')
			-- This callback should go to the end of the queue
			scheduleCallback(ImmediatePriority, function()
				Scheduler.unstable_yieldValue('C')
			end)
		end)
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('D')
		end)
		expect(Scheduler).toHaveYielded({})
		-- C should flush at the end
		expect(Scheduler).toFlushExpired({'A', 'B', 'D', 'C'})
	end)

	it("wrapped callbacks have same signature as original callback", function()
		local wrappedCallback = wrapCallback(function(...)
			return {
				args = {...}
			}
		end)
		local result = wrappedCallback('a', 'b')
		expect(#result.args).to.equal(2)
		expect(result.args).toEqual({'a', 'b'})
	end)

	it("wrapped callbacks inherit the current priority", function()
		local wrappedCallback = runWithPriority(NormalPriority, function()
			return wrapCallback(function()
				Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
			end)
		end)

		local wrappedUserBlockingCallback = runWithPriority(
			UserBlockingPriority,
			function()
				return wrapCallback(function()
					Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
				end)
			end
		)

		wrappedCallback()
		expect(Scheduler).toHaveYielded({NormalPriority})

		wrappedUserBlockingCallback()
		expect(Scheduler).toHaveYielded({UserBlockingPriority})
	end)

	it("wrapped callbacks inherit the current priority even when nested", function()
		local wrappedCallback
		local wrappedUserBlockingCallback

		runWithPriority(NormalPriority, function()
			wrappedCallback = wrapCallback(function()
				Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
			end)
			wrappedUserBlockingCallback = runWithPriority(UserBlockingPriority, function()
				return wrapCallback(function()
					Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
				end)
			end)
		end)

		wrappedCallback()
		expect(Scheduler).toHaveYielded({NormalPriority})

		wrappedUserBlockingCallback()
		expect(Scheduler).toHaveYielded({UserBlockingPriority})
	end)

	it("immediate callbacks fire even if there's an error", function()
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('A')
			error('Oops A')
		end)
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('B')
		end)
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue('C')
			error('Oops C')
		end)

		expect(function()
			expect(Scheduler).toFlushExpired()
		end).toThrow('Oops A')
		expect(Scheduler).toHaveYielded({'A'})

		-- B and C flush in a subsequent event. That way, the second error is not
		-- swallowed.
		expect(function()
			expect(Scheduler).toFlushExpired()
		end).toThrow('Oops C')
		expect(Scheduler).toHaveYielded({'B', 'C'})
	end)

	it("multiple immediate callbacks can throw and there will be an error for each one", function()
		scheduleCallback(ImmediatePriority, function()
			error('First error')
		end)
		scheduleCallback(ImmediatePriority, function()
			error('Second error')
		end)
		expect(function()
			Scheduler.unstable_flushAll()
		end).toThrow('First error')
		-- The next error is thrown in the subsequent event
		expect(function()
			Scheduler.unstable_flushAll()
		end).toThrow('Second error')
	end)

	it("exposes the current priority level", function()
		Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
		runWithPriority(ImmediatePriority, function()
			Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
			runWithPriority(NormalPriority, function()
				Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
				runWithPriority(UserBlockingPriority, function()
					Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
				end)
			end)
			Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
		end)

		expect(Scheduler).toHaveYielded({
			NormalPriority,
			ImmediatePriority,
			NormalPriority,
			UserBlockingPriority,
			ImmediatePriority,
		})
	end)

	-- if __DEV__ then
		-- TODO(align): Re-enable this test if it's useful
		--
		-- Function names are minified in prod, though you could still infer the
		-- priority if you have sourcemaps.
		-- TODO: Feature temporarily disabled while we investigate a bug in one of
		-- our minifiers.
		-- it.skip('adds extra function to the JS stack whose name includes the priority level', function()
		-- 	function inferPriorityFromCallstack()
		-- 		try {
		-- 			throw Error()
		-- 		} catch (e) {
		-- 			local stack = e.stack
		-- 			local lines = stack.split('\n')
		-- 			for (local i = lines.length - 1 i >= 0 i--) {
		-- 				local line = lines[i]
		-- 				local found = line.match(
		-- 					/scheduler_flushTaskAtPriority_({A-Za-z]+)/,
		-- 				)
		-- 				if (found !== null) {
		-- 					local priorityStr = found[1]
		-- 					switch (priorityStr) {
		-- 						case 'Immediate':
		-- 							return ImmediatePriority
		-- 						case 'UserBlocking':
		-- 							return UserBlockingPriority
		-- 						case 'Normal':
		-- 							return NormalPriority
		-- 						case 'Low':
		-- 							return LowPriority
		-- 						case 'Idle':
		-- 							return IdlePriority
		-- 					}
		-- 				}
		-- 			}
		-- 			return null
		-- 		}
		-- 	end

		-- 	scheduleCallback(ImmediatePriority, () =>
		-- 		Scheduler.unstable_yieldValue(
		-- 			'Immediate: ' + inferPriorityFromCallstack(),
		-- 		),
		-- 	)
		-- 	scheduleCallback(UserBlockingPriority, () =>
		-- 		Scheduler.unstable_yieldValue(
		-- 			'UserBlocking: ' + inferPriorityFromCallstack(),
		-- 		),
		-- 	)
		-- 	scheduleCallback(NormalPriority, () =>
		-- 		Scheduler.unstable_yieldValue(
		-- 			'Normal: ' + inferPriorityFromCallstack(),
		-- 		),
		-- 	)
		-- 	scheduleCallback(LowPriority, () =>
		-- 		Scheduler.unstable_yieldValue('Low: ' + inferPriorityFromCallstack()),
		-- 	)
		-- 	scheduleCallback(IdlePriority, () =>
		-- 		Scheduler.unstable_yieldValue('Idle: ' + inferPriorityFromCallstack()),
		-- 	)

		-- 	expect(Scheduler).toFlushAndYield({
		-- 		'Immediate: ' + ImmediatePriority,
		-- 		'UserBlocking: ' + UserBlockingPriority,
		-- 		'Normal: ' + NormalPriority,
		-- 		'Low: ' + LowPriority,
		-- 		'Idle: ' + IdlePriority,
		-- 	})
		-- end)
	-- end

	describe("delayed tasks", function()
		it("schedules a delayed task", function()
			scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('A')
				end,
				{
					delay = 1000,
				}
			)

			-- Should flush nothing, because delay hasn't elapsed
			expect(Scheduler).toFlushAndYield({})

			-- Advance time until right before the threshold
			Scheduler.unstable_advanceTime(999)
			-- Still nothing
			expect(Scheduler).toFlushAndYield({})

			-- Advance time past the threshold
			Scheduler.unstable_advanceTime(1)

			-- Now it should flush like normal
			expect(Scheduler).toFlushAndYield({'A'})
		end)

		it("schedules multiple delayed tasks", function()
			scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('C')
				end,
				{
					delay = 300,
				}
			)

			scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('B')
				end,
				{
					delay = 200,
				}
			)

			scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('D')
				end,
				{
					delay = 400,
				}
			)

			scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('A')
				end,
				{
					delay = 100,
				}
			)

			-- Should flush nothing, because delay hasn't elapsed
			expect(Scheduler).toFlushAndYield({})

			-- Advance some time.
			Scheduler.unstable_advanceTime(200)
			-- Both A and B are no longer delayed. They can now flush incrementally.
			expect(Scheduler).toFlushAndYieldThrough({'A'})
			expect(Scheduler).toFlushAndYield({'B'})

			-- Advance the rest
			Scheduler.unstable_advanceTime(200)
			expect(Scheduler).toFlushAndYield({'C', 'D'})
		end)

		it("interleaves normal tasks and delayed tasks", function()
			-- Schedule some high priority callbacks with a delay. When their delay
			-- elapses, they will be the most important callback in the queue.
			scheduleCallback(
				UserBlockingPriority,
				function()
					Scheduler.unstable_yieldValue('Timer 2')
				end,
				{
					delay = 300
				}
			)
			scheduleCallback(
				UserBlockingPriority,
				function()
					Scheduler.unstable_yieldValue('Timer 1')
				end,
				{
					delay = 100
				}
			)

			-- Schedule some tasks at default priority.
			scheduleCallback(NormalPriority, function()
				Scheduler.unstable_yieldValue('A')
				Scheduler.unstable_advanceTime(100)
			end)
			scheduleCallback(NormalPriority, function()
				Scheduler.unstable_yieldValue('B')
				Scheduler.unstable_advanceTime(100)
			end)
			scheduleCallback(NormalPriority, function()
				Scheduler.unstable_yieldValue('C')
				Scheduler.unstable_advanceTime(100)
			end)
			scheduleCallback(NormalPriority, function()
				Scheduler.unstable_yieldValue('D')
				Scheduler.unstable_advanceTime(100)
			end)

			-- Flush all the work. The timers should be interleaved with the
			-- other tasks.
			expect(Scheduler).toFlushAndYield({
				'A',
				'Timer 1',
				'B',
				'C',
				'Timer 2',
				'D',
			})
		end)

		it('interleaves delayed tasks with time-sliced tasks', function()
			-- Schedule some high priority callbacks with a delay. When their delay
			-- elapses, they will be the most important callback in the queue.
			scheduleCallback(
				UserBlockingPriority,
				function()
					Scheduler.unstable_yieldValue('Timer 2')
				end,
				{
					delay = 300
				}
			)
			scheduleCallback(
				UserBlockingPriority,
				function()
					Scheduler.unstable_yieldValue('Timer 1')
				end,
				{
					delay = 100
				}
			)

			-- Schedule a time-sliced task at default priority.
			local tasks = {
				{'A', 100},
				{'B', 100},
				{'C', 100},
				{'D', 100},
			}
			local function work()
				while #tasks > 0 do
					local task = shift(tasks)
					local label, ms = unpack(task)
					Scheduler.unstable_advanceTime(ms)
					Scheduler.unstable_yieldValue(label)
					if #tasks > 0 then
						return work
					end
				end

				return nil
			end
			scheduleCallback(NormalPriority, work)

			-- Flush all the work. The timers should be interleaved with the
			-- other tasks.
			expect(Scheduler).toFlushAndYield({
				'A',
				'Timer 1',
				'B',
				'C',
				'Timer 2',
				'D',
			})
		end)

		it("cancels a delayed task", function()
			-- Schedule several tasks with the same delay
			local options = {
				delay = 100
			}

			scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('A')
				end,
				options
			)
			local taskB = scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('B')
				end,
				options
			)
			local taskC = scheduleCallback(
				NormalPriority,
				function()
					Scheduler.unstable_yieldValue('C')
				end,
				options
			)

			-- Cancel B before its delay has elapsed
			expect(Scheduler).toFlushAndYield({})
			cancelCallback(taskB)

			-- Cancel C after its delay has elapsed
			Scheduler.unstable_advanceTime(500)
			cancelCallback(taskC)

			-- Only A should flush
			expect(Scheduler).toFlushAndYield({'A'})
		end)

		it("gracefully handles scheduled tasks that are not a function", function()
			scheduleCallback(ImmediatePriority, nil)
			expect(Scheduler).toFlushWithoutYielding()

			scheduleCallback(ImmediatePriority, {})
			expect(Scheduler).toFlushWithoutYielding()

			scheduleCallback(ImmediatePriority, 42)
			expect(Scheduler).toFlushWithoutYielding()
		end)
	end)
end