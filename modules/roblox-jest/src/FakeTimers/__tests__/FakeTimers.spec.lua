
local Workspace = script.Parent.Parent.Parent.Parent
local RobloxJest
local Packages = Workspace.Parent
local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
return function()

	beforeEach(function()
        RobloxJest = require(Workspace.RobloxJest)
        RobloxJest.resetModules()
        RobloxJest.useFakeTimers()

		-- ROBLOX deviation: In react, jest _always_ mocks Scheduler -> unstable_mock;
		-- in our case, we need to do it anywhere we want to use the scheduler,
		-- until we have some form of bundling logic
		RobloxJest.mock(Workspace.Scheduler, function()
			return require(Workspace.Scheduler.unstable_mock)
		end)
	end)

	describe("advanceTimersByTime", function()
        it('one timer advances', function()
            local log = {}
            -- add timer
            RobloxJest.testEnv.delay(100, function()
                table.insert(log, "timer callback")
            end)

            -- advance timers but not beyond timer expiry
            RobloxJest.advanceTimersByTime(50)
            jestExpect(RobloxJest.testEnv.tick()).toEqual(50)
            jestExpect(log).toEqual({})

            -- advance timers to exactly timer expiry
            RobloxJest.advanceTimersByTime(50)
            jestExpect(RobloxJest.testEnv.tick()).toEqual(100)
            jestExpect(log).toEqual({"timer callback"})

            -- reset log
            log = {}

            -- ensure timer isn't triggered again
            RobloxJest.advanceTimersByTime(10000)
            jestExpect(log).toEqual({})
        end)
        it('multiple timers advance', function()
            local log = {}

            -- add timers
            RobloxJest.testEnv.delay(100, function()
                table.insert(log, "timer 1 callback")
            end)
            RobloxJest.testEnv.delay(100, function()
                table.insert(log, "timer 2 callback")
            end)
            RobloxJest.testEnv.delay(104, function()
                table.insert(log, "timer 3 callback")
            end)
            RobloxJest.testEnv.delay(50, function()
                table.insert(log, "timer 4 callback")
            end)
            RobloxJest.testEnv.delay(300, function()
                table.insert(log, "timer 5 callback")
            end)

            -- advance timers passed timer 4 expiry
            RobloxJest.advanceTimersByTime(70)
            jestExpect(log).toEqual({"timer 4 callback"})

            -- advance timers passed timer 1 and 2 expiry
            RobloxJest.advanceTimersByTime(31)
            jestExpect(log).toEqual({"timer 4 callback", "timer 1 callback", "timer 2 callback"})

            -- advance timers passed rest of expiries
            RobloxJest.advanceTimersByTime(1000)
            jestExpect(log).toEqual({
                "timer 4 callback", 
                "timer 1 callback", 
                "timer 2 callback",
                "timer 3 callback",
                "timer 5 callback"
            })
        end)

	end)
end
