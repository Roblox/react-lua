return function()
	local Workspace = script.Parent.Parent.Parent.Parent
	local Packages = Workspace.Parent
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Error = LuauPolyfill.Error

	local toThrow = require(script.Parent.Parent.toThrow)

	it("should pass when the function throws", function()
		local result = toThrow(function()
			error(Error("some error"))
		end)

		assert(result.pass)
		-- Message should be the inverse here for when users add a `.never`
		expect(result.message).to.equal("Expected function not to throw")
	end)

	it("should pass when the function throws with a matching message", function()
		local result = toThrow(function()
			error(Error("some error"))
		end, "some error")

		assert(result.pass)
		-- Message should be the inverse here for when users add a `.never`
		expect(result.message).to.equal("Expected function not to throw with 'some error'")
	end)

	it("should pass when the function throws with a message matching the given substring", function()
		local result = toThrow(function()
			error(Error("A long and more detailed error message"))
		end, "and more detailed")

		assert(result.pass)
		-- Message should be the inverse here for when users add a `.never`
		expect(result.message).to.equal("Expected function not to throw with 'and more detailed'")
	end)

	it("should pass when the function throws with a matching string instead of an Error object", function()
		local result = toThrow(function()
			error("just a string")
		end, "just a string")

		assert(result.pass)
		-- Message should be the inverse here for when users add a `.never`
		expect(result.message).to.equal("Expected function not to throw with 'just a string'")
	end)

	it("should fail when the function throws with a non-matching error", function()
		local result = toThrow(function()
			error(Error("Some error message"))
		end, "non-matching substring")

		assert(not result.pass)
		expect(result.message).to.equal("Expected function to throw with 'non-matching substring'")
	end)

	it("should fail when the function throws with an invalid type", function()
		local result = toThrow(function()
			error({ key = "not an error" })
		end, "some error")

		assert(not result.pass)
		expect(result.message:find("to throw a string or an Error")).to.be.ok()
		expect(result.message:find("but it threw an error of type 'table'.")).to.be.ok()
	end)
end