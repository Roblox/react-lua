--!nocheck
return function()
	local Workspace = script.Parent.Parent.Parent.Parent
	local seal = require(script.Parent.Parent.seal)
	local RobloxJest = require(Workspace.RobloxJest)

	beforeAll(function()
		expect.extend({
			toEqual = RobloxJest.Matchers.toEqual,
		})
	end)

	it("should return the same table", function()
		local unsealed = {
			a = 1,
		}
		local sealed = seal(unsealed)

		expect(sealed).to.equal(unsealed)
	end)

	it("should allow access to any keys that were defined when it was sealed", function()
		local t = seal({
			a = 1,
		})

		expect(t.a).to.equal(1)
	end)

	it("should allow mutation of existing values", function()
		local t = seal({
			a = 1,
		})

		t.a = 2
		expect(t.a).to.equal(2)
	end)

	it("should preserve iteration functionality", function()
		local t = seal({
			a = 1,
			b = 2,
		})

		local tPairsCopy = {}
		for k, v in pairs(t) do
			tPairsCopy[k] = v
		end

		expect(tPairsCopy).toEqual(t)

		local a = seal({ "hello", "world" })

		local aIpairsCopy = {}
		for i, v in ipairs(a) do
			aIpairsCopy[i] = v
		end

		expect(aIpairsCopy).toEqual(a)
	end)

	it("should error when setting a nonexistent key", function()
		local t = seal({
			a = 1,
			b = 2,
		})

		expect(function()
			t.c = 3
		end).to.throw()
	end)
end