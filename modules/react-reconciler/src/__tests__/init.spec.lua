return function()
	local Workspace = script.Parent.Parent.Parent
	local Packages = Workspace.Parent.Parent.Packages
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local RobloxJest = require(Workspace.RobloxJest)
	local getTestRendererJestMatchers = require(Workspace.JestReact["getJestMatchers.roblox"])
	local getSchedulerJestMatchers = require(Workspace.Scheduler["getJestMatchers.roblox"])

	beforeAll(function()
		jestExpect.extend(getTestRendererJestMatchers(jestExpect))
		jestExpect.extend(getSchedulerJestMatchers(jestExpect))

		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)
end
