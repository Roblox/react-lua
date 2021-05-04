return function()
	local Workspace = script.Parent.Parent.Parent.Parent
	local Packages = Workspace.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local RobloxJest = require(Workspace.RobloxJest)
	local Foo, Bar

	beforeEach(function()
		RobloxJest.resetModules()
	end)

	it("avoids cycles when Foo is required before Bar", function()
		Foo = require(script.Parent.TestModules.Foo)
		Bar = require(script.Parent.TestModules.Bar)

		jestExpect(Foo.addThenMultiply(3)).toBe(8)
		jestExpect(Bar.multiplyThenAdd(3)).toBe(7)
	end)

	it("avoids cycles when Bar is required before Foo", function()
		Bar = require(script.Parent.TestModules.Bar)
		Foo = require(script.Parent.TestModules.Foo)

		jestExpect(Bar.multiplyThenAdd(3)).toBe(7)
		jestExpect(Foo.addThenMultiply(3)).toBe(8)
	end)
end