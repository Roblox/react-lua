type Timeout = {
	time: number,
	callback: () -> ()
}

local realDelay = delay
local realTick = tick

local timeouts: { [number]: Timeout } = {}
local mockTime = 0

local function runAllTimers()
	for _, timeout in pairs(timeouts) do
		-- Move mockTime to target time, in case the callback reads it via
		-- `tick`
		mockTime = timeout.time
		timeout.callback()
	end

	timeouts = {}
end

local function mockDelay(_, delayTime, callback)
	local targetTime = mockTime + delayTime
	local timeout = {
		time = targetTime,
		callback = callback,
	}
	local insertIndex = 1
	for i = 1, #timeouts do
		-- Timeouts are inserted in time order. As soon as we encounter a
		-- timeout that's _after_ our targetTime, we place ours in the list
		-- immediately before it. This way, timeouts with the exact same time
		-- will be queued up in insertion order to break ties
		if timeouts[i].time > targetTime then
			insertIndex = i
		end
	end

	table.insert(timeouts, insertIndex, timeout)
end

local function mockTick(_)
	return mockTime
end

local delayOverride = {}
delayOverride.__call = realDelay

local tickOverride = {}
tickOverride.__call = realTick

local function useFakeTimers()
	delayOverride.__call = mockDelay
	tickOverride.__call = mockTick
end

local function useRealTimers()
	delayOverride.call = realDelay
	tickOverride.__call = realTick
end

return {
	delayOverride = setmetatable({}, delayOverride),
	tickOverride = setmetatable({}, tickOverride),
	runAllTimers = runAllTimers,
	useFakeTimers = useFakeTimers,
	useRealTimers = useRealTimers,
}