local FakeTimers = require(script.FakeTimers)
local Module = require(script.Module)

local RobloxJest = {
	createSpy = require(script.createSpy),
	Matchers = {
		toEqual = require(script.Matchers.toEqual),
		toThrow = require(script.Matchers.toThrow),
	},

	resetModules = Module.resetModules,
	mock = Module.mock,
	unmock = Module.unmock,

	useFakeTimers = FakeTimers.useFakeTimers,
	useRealTimers = FakeTimers.useRealTimers,
	runAllTimers = FakeTimers.runAllTimers,

	testEnv = {
		require = Module.requireOverride,
		delay = FakeTimers.delayOverride,
		tick = FakeTimers.tickOverride,
	},
}

return RobloxJest
