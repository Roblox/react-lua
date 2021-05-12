local LazyModule = require(script.Parent.Parent.Parent)

return LazyModule(function(exports)
	local Foo = require(script.Parent.Foo) :: any
	local addOne = Foo.addOne

	local function multiplyByTwo(value)
		return value * 2
	end
	exports.multiplyByTwo = multiplyByTwo

	local function multiplyThenAdd(value)
		return addOne(multiplyByTwo(value))
	end
	exports.multiplyThenAdd = multiplyThenAdd
end)