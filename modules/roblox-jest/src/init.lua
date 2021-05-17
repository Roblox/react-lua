--!nolint LocalShadowPedantic
local FakeTimers = require(script.FakeTimers)
local Module = require(script.Module)

-- override require from now to make sure Matchers are
-- hitting the Module's cache
local require = Module.requireOverride

local RobloxJest = {
	Matchers = {
		toErrorDev = require(script.Matchers.toErrorDev),
		toWarnDev = require(script.Matchers.toWarnDev),
	},

	resetModules = Module.resetModules,
	mock = Module.mock,
	unmock = Module.unmock,

	-- ROBLOX TODO: use roblox-jest fake timers impl and delete these
	useFakeTimers = FakeTimers.useFakeTimers,
	useRealTimers = FakeTimers.useRealTimers,
	runAllTimers = FakeTimers.runAllTimers,
	advanceTimersByTime = FakeTimers.advanceTimersByTime,

	testEnv = {
		require = Module.requireOverride,
		delay = FakeTimers.delayOverride,
		tick = FakeTimers.tickOverride,
	},
}

return RobloxJest
