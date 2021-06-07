return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local getTestRendererJestMatchers = require(Packages.Dev.JestReact).getJestMatchers
	local getSchedulerJestMatchers = require(Packages.Scheduler).getJestMatchers

	beforeAll(function()
		jestExpect.extend(getTestRendererJestMatchers(jestExpect))
		jestExpect.extend(getSchedulerJestMatchers(jestExpect))

		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)
end
