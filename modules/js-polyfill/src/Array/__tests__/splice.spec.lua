-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
-- use custom matchers added via `expect.extend`
--!nocheck

-- Tests adapted directly from examples at:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/splice
return function()
	local splice = require(script.Parent.Parent.splice)
	it('Remove 0 (zero) elements before index 3, and insert "drum"', function()
		local myFish = {"angel", "clown", "mandarin", "sturgeon"}
		local removed = splice(myFish, 3, 0, "drum")

		expect(myFish).toEqual({"angel", "clown", "drum", "mandarin", "sturgeon"})
		expect(removed).toEqual({})
	end)

	it('Remove 0 (zero) elements before index 3, and insert "drum" and "guitar"', function()
		local myFish = {"angel", "clown", "mandarin", "sturgeon"}
		local removed = splice(myFish, 3, 0, "drum", "guitar")

		expect(myFish).toEqual({"angel", "clown", "drum", "guitar", "mandarin", "sturgeon"})
		expect(removed).toEqual({})
	end)

	it('Remove 1 element at index 4', function()
		local myFish = {"angel", "clown", "drum", "mandarin", "sturgeon"}
		local removed = splice(myFish, 4, 1)

		expect(myFish).toEqual({"angel", "clown", "drum", "sturgeon"})
		expect(removed).toEqual({"mandarin"})
	end)

	it('Remove 1 element at index 3, and insert "trumpet"', function()
		local myFish = {"angel", "clown", "drum", "sturgeon"}
		local removed = splice(myFish, 3, 1, "trumpet")

		expect(myFish).toEqual({"angel", "clown", "trumpet", "sturgeon"})
		expect(removed).toEqual({"drum"})
	end)

	it('Remove 2 elements from index 1, and insert "parrot", "anemone" and "blue"', function()
		local myFish = {'angel', 'clown', 'trumpet', 'sturgeon'}
		local removed = splice(myFish, 1, 2, 'parrot', 'anemone', 'blue')

		expect(myFish).toEqual({"parrot", "anemone", "blue", "trumpet", "sturgeon"} )
		expect(removed).toEqual({"angel", "clown"})
	end)

	it('Remove 2 elements from index 3', function()
		local myFish = {'parrot', 'anemone', 'blue', 'trumpet', 'sturgeon'}
		local removed = splice(myFish, 3, 2)

		expect(myFish).toEqual({"parrot", "anemone", "sturgeon"} )
		expect(removed).toEqual({"blue", "trumpet"})
	end)

	it('Remove 1 element from index -1', function()
		local myFish = {'angel', 'clown', 'mandarin', 'sturgeon'}
		local removed = splice(myFish, -1, 1)

		expect(myFish).toEqual({"angel", "clown", "sturgeon"} )
		expect(removed).toEqual({"mandarin"})
	end)

	it('Remove all elements from index 3', function()
		local myFish = {'angel', 'clown', 'mandarin', 'sturgeon'}
		local removed = splice(myFish, 3)

		expect(myFish).toEqual({"angel", "clown"})
		expect(removed).toEqual({"mandarin", "sturgeon"})
	end)
end