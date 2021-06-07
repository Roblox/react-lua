return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local getJestMatchers = require(Packages.Dev.Scheduler).getJestMatchers
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

	beforeAll(function()
		jestExpect.extend(getJestMatchers(jestExpect))
		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)
end
