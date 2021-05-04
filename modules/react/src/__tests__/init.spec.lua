return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)
	local getJestMatchers = require(Workspace.Scheduler["getJestMatchers.roblox"])
	local Packages = Workspace.Parent.Parent.Packages
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

	beforeAll(function()
		jestExpect.extend(getJestMatchers(jestExpect))
		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)
end
