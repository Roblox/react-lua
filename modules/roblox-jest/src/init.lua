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

	testEnv = {
		require = Module.requireOverride,
	}
}

return RobloxJest
