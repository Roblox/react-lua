-- Tests partially based on examples from:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf
return function()
	local indexOf = require(script.Parent.Parent.indexOf)
	local beasts = { "ant", "bison", "camel", "duck", "bison" }

	it("returns the index of the first occurrence of an element", function()
		expect(indexOf(beasts, "bison")).to.equal(2)
	end)

	it("begins at the start index when provided", function()
		expect(indexOf(beasts, "bison", 3)).to.equal(5)
	end)

	it("returns -1 when the value isn't present", function()
		expect(indexOf(beasts, "giraffe")).to.equal(-1)
	end)

	it("returns -1 when the fromIndex is too large", function()
		expect(indexOf(beasts, "camel", 6)).to.equal(-1)
	end)

	it("accepts a negative fromIndex, and subtracts it from the total length", function()
		expect(indexOf(beasts, "bison", -4)).to.equal(2)
		expect(indexOf(beasts, "bison", -2)).to.equal(5)
		expect(indexOf(beasts, "ant", -2)).to.equal(-1)
	end)

	it("accepts a 0 fromIndex (special case for Lua's 1-index arrays) and starts at the end", function()
		expect(indexOf(beasts, "bison", 0)).to.equal(5)
	end)

	it("starts at the beginning when it receives a too-large negative fromIndex", function()
		expect(indexOf(beasts, "bison", -10)).to.equal(2)
		expect(indexOf(beasts, "ant", -10)).to.equal(1)
	end)

	it("uses strict equality", function()
		local firstObject = { x = 1 }
		local objects = {
			firstObject,
			{ x = 2 },
			{ x = 3 },
		}
		expect(indexOf(objects, { x = 2 })).to.equal(-1)
		expect(indexOf(objects, firstObject)).to.equal(1)
	end)
end