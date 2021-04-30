--!nolint LocalShadowPedantic
local FakeTimers = require(script.FakeTimers)
local Module = require(script.Module)

-- override require from now to make sure Matchers are
-- hitting the Module's cache
local require = Module.requireOverride

local createSpy = require(script.createSpy)
local RobloxJest = {
	createSpy = createSpy,
	-- This is the actual jest api
	fn = createSpy,
	Matchers = {
		toEqual = require(script.Matchers.toEqual),
		toThrow = require(script.Matchers.toThrow),
		toErrorDev = require(script.Matchers.toErrorDev),
		toWarnDev = require(script.Matchers.toWarnDev),
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
