--!nonstrict
return function()
	local Error = require(script.Parent.Parent)

	it("accepts a message value as an argument", function()
		local err = Error("Some message")

		expect(err.message).to.equal("Some message")
	end)

	it("defaults the `name` field to 'Error'", function()
		local err = Error("")

		expect(err.name).to.equal("Error")
	end)

	it("gets passed through the `error` builtin properly", function()
		local err = Error("Throwing an error")
		local ok, result = pcall(function()
			error(err)
		end)

		expect(ok).to.equal(false)
		expect(result).to.equal(err)
	end)
end