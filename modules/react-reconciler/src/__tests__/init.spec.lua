-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
--use custom matchers added via `expect.extend`
--!nocheck
return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)
	local getJestMatchers = require(Workspace.Scheduler["getJestMatchers.roblox"])

	beforeAll(function()
		expect.extend(getJestMatchers(expect))

		expect.extend({
			toEqual = RobloxJest.Matchers.toEqual,
			toThrow = RobloxJest.Matchers.toThrow,
		})
	end)
end