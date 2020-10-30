return function()
	local toEqual = require(script.Parent.Parent.toEqual)

	it("should fail with a message when args are not equal", function()
		local result = toEqual(1, 2)

		expect(result.pass).to.equal(false)
		expect(result.message).to.equal("received (1) ~= expected (2)")

		result = toEqual({
			foo = 1,
		}, {
			foo = 2,
		})

		expect(result.pass).to.equal(false)
		expect(result.message:find("received%[foo%] %(1%) ~= expected%[foo%] %(2%)")).to.be.ok()
	end)

	it("should compare non-table values using standard '==' equality", function()
		assert(toEqual(1, 1).pass)
		assert(toEqual("hello", "hello").pass)
		assert(toEqual(nil, nil).pass)

		local someFunction = function() end
		local theSameFunction = someFunction

		assert(toEqual(someFunction, theSameFunction).pass)

		local A = {
			foo = someFunction
		}
		local B = {
			foo = theSameFunction
		}

		assert(toEqual(A, B).pass)
	end)

	it("should fail when types differ", function()
		local result = toEqual(1, "1")

		expect(result.pass).to.equal(false)
		expect(result.message).to.equal("received: value of type 'number'\nexpected: value of type 'string'")
	end)

	it("should compare (and report about) nested tables", function()
		local A = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 2,
			}
		}
		local B = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 2,
			}
		}

		assert(toEqual(A, B).pass)

		local C = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 3,
			}
		}

		local result = toEqual(A, C)

		expect(result.pass).to.equal(false)
		expect(result.message:find("received%[nested%]%[bar%] %(2%) ~= expected%[nested%]%[bar%] %(3%)")).to.be.ok()
	end)

	it("should be commutative", function()
		local equalArgsA = {
			foo = "bar",
			hello = "world",
		}
		local equalArgsB = {
			foo = "bar",
			hello = "world",
		}

		assert(toEqual(equalArgsA, equalArgsB).pass)
		assert(toEqual(equalArgsB, equalArgsA).pass)

		local nonEqualArgs = {
			foo = "bar",
		}

		local result = toEqual(equalArgsA, nonEqualArgs)
		assert(not result.pass)
		expect(result.message:find("received%[hello%] ~= expected%[hello%]"))

		result = toEqual(nonEqualArgs, equalArgsA)
		assert(not result.pass)
		expect(result.message:find("received%[hello%] ~= expected%[hello%]"))
	end)
end