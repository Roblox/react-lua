--!nocheck
local LazyModule = require(script.Parent.Parent.Parent)

return LazyModule(function(exports)
	local Bar = require(script.Parent.Bar)
	local multiplyByTwo = Bar.multiplyByTwo

	local function addOne(value)
		return value + 1
	end
	exports.addOne = addOne

	local function addThenMultiply(value)
		return multiplyByTwo(addOne(value))
	end
	exports.addThenMultiply = addThenMultiply
end)
