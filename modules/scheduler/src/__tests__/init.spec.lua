return function()
	local Workspace = script.Parent.Parent.Parent
	local Packages = Workspace.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

	local getJestMatchers = require(script.Parent.Parent["getJestMatchers.roblox"])

	beforeAll(function()
		jestExpect.extend(getJestMatchers(jestExpect))
	end)
end