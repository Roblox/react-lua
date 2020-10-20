--!nolint LocalShadow

type Array = { [number]: any }

-- Implements equivalent functionality to JavaScript's `array.splice`, including
-- the interface and behaviors defined at:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/splice
return function(array: Array, start: number, deleteCount: number?, ...): Array
	-- Append varargs without removing anything
	if start > #array then
		local varargCount = select("#", ...)
		for i = 1, varargCount do
			local toInsert = select(i, ...)
			table.insert(array, toInsert)
		end
		return {}
	else
		local length = #array
		-- In the JS impl, a negative fromIndex means we should use length -
		-- index; with Lua, of course, this means that 0 is still valid, but
		-- refers to the end of the array the way that '-1' would in JS
		if start < 1 then
			start = math.max(length - math.abs(start), 1)
		end

		local deletedItems = {}
		-- If no deleteCount was provided, we want to delete the rest of the
		-- array starting with `start`
		local deleteCount: number = deleteCount or length
		if deleteCount > 0 then
			local lastIndex = math.min(length, start + math.max(0, deleteCount - 1))

			for i = start, lastIndex do
				local deleted = table.remove(array, start)
				table.insert(deletedItems, deleted)
			end
		end

		local varargCount = select("#", ...)
		-- Do this in reverse order so we can always insert in the same spot
		for i = varargCount, 1, -1 do
			local toInsert = select(i, ...)
			table.insert(array, start, toInsert)
		end

		return deletedItems
	end
end
