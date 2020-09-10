--!strict
type Node = {
	id: number,
	sortIndex: number,
}
type Heap = { [number]: Node }

local function compare(a, b)
	-- Compare sort index first, then task id.
	local diff = a.sortIndex - b.sortIndex

	if diff == 0 then
		return a.id - b.id
	end

	return diff
end

local function siftUp(heap, node, index)
	while true do
		local parentIndex = math.floor(index / 2)
		local parent = heap[parentIndex];
		if parent ~= nil and compare(parent, node) > 0 then
			-- The parent is larger. Swap positions.
			heap[parentIndex] = node
			heap[index] = parent
			index = parentIndex
		else
			-- The parent is smaller. Exit.
			return
		end
	end
end

local function siftDown(heap, node, index)
	local length = #heap
	while (index < length) do
		local leftIndex = index * 2
		local left = heap[leftIndex]
		local rightIndex = leftIndex + 1
		local right = heap[rightIndex]

		-- If the left or right node is smaller, swap with the smaller of those.
		if left ~= nil and compare(left, node) < 0 then
			if right ~= nil and compare(right, left) < 0 then
				heap[index] = right
				heap[rightIndex] = node
				index = rightIndex
			else
				heap[index] = left
				heap[leftIndex] = node
				index = leftIndex
			end
		elseif right ~= nil and compare(right, node) < 0 then
			heap[index] = right
			heap[rightIndex] = node
			index = rightIndex
		else
			-- Neither child is smaller. Exit.
			return
		end
	end
end

return {
	push = function(heap: Heap, node: Node)
		local index = #heap + 1
		heap[index] = node
	
		siftUp(heap, node, index)
	end,

	peek = function(heap: Heap): Node?
		return heap[1]
	end,

	pop = function(heap: Heap): Node?
		local first = heap[1]
		if first ~= nil then
			local last = heap[#heap]
			heap[#heap] = nil
	
			if last ~= first then
				heap[1] = last
				siftDown(heap, last, 1)
			end
			return first
		else
			return nil
		end
	end,
}