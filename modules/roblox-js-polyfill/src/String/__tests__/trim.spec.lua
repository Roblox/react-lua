return function()
	local trim = require(script.Parent.Parent.trim)

	it("removes spaces at begining", function()
		expect(trim("  abc")).to.equal("abc")
	end)

	it("removes spaces at end", function()
		expect(trim("abc   ")).to.equal("abc")
	end)

	it("removes spaces at both ends", function()
		expect(trim("  abc   ")).to.equal("abc")
	end)

	it("does not remove spaces in the middle", function()
		expect(trim("a b c")).to.equal("a b c")
	end)

	it("removes all types of spaces", function()
		expect(trim("\r\n\t\f\vabc")).to.equal("abc")
	end)

	it("returns an empty string if there are only spaces", function()
		expect(trim("    ")).to.equal("")
	end)
end
