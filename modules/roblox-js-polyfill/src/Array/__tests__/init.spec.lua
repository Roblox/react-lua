-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
-- use custom matchers added via `expect.extend`
--!nocheck
return function()
	local Workspace = script.Parent.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)

	beforeAll(function()
		expect.extend({
			toEqual = RobloxJest.Matchers.toEqual,
			toThrow = RobloxJest.Matchers.toThrow,
		})
	end)
end