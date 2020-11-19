return function()
	local Workspace = script.Parent.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)
	local Foo, Bar

	beforeEach(function()
		RobloxJest.resetModules()
	end)

	it("avoids cycles when Foo is required before Bar", function()
		Foo = require(script.Parent.TestModules.Foo)
		Bar = require(script.Parent.TestModules.Bar)

		expect(Foo.addThenMultiply(3)).to.equal(8)
		expect(Bar.multiplyThenAdd(3)).to.equal(7)
	end)

	it("avoids cycles when Bar is required before Foo", function()
		Bar = require(script.Parent.TestModules.Bar)
		Foo = require(script.Parent.TestModules.Foo)
	
		expect(Bar.multiplyThenAdd(3)).to.equal(7)
		expect(Foo.addThenMultiply(3)).to.equal(8)
	end)
end