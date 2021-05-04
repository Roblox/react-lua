return function()
	local Workspace = script.Parent.Parent.Parent.Parent.Parent
	local Packages = Workspace.Parent
	local jestModule = require(Packages.Dev.JestRoblox)
	local jestExpect = jestModule.Globals.expect
	local getDefaultInstanceProperty = require(script.Parent.Parent.getDefaultInstanceProperty)

	it("should get default name string values", function()
		local _, defaultName = getDefaultInstanceProperty("StringValue", "Name")

		jestExpect(defaultName).toBe("Value")
	end)

	it("should get default empty string values", function()
		local _, defaultValue = getDefaultInstanceProperty("StringValue", "Value")

		jestExpect(defaultValue).toBe("")
	end)

	it("should get default number values", function()
		local _, defaultValue = getDefaultInstanceProperty("IntValue", "Value")

		jestExpect(defaultValue).toBe(0)
	end)

	it("should get nil default values", function()
		local _, defaultValue = getDefaultInstanceProperty("ObjectValue", "Value")

		jestExpect(defaultValue).toBe(nil)
	end)

	it("should get bool default values", function()
		local _, defaultValue = getDefaultInstanceProperty("BoolValue", "Value")

		jestExpect(defaultValue).toBe(false)
	end)
end