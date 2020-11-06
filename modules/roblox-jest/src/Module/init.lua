--!strict
local FakeTimers = require(script.Parent.FakeTimers)

local requiredModules: { [ModuleScript]: any } = {}
local mocks: { [ModuleScript]: () -> any } = {}

local function requireOverride(scriptInstance: ModuleScript): any
	-- This is crucial! We need to have an early out here so that we don't
	-- override requires of ourself; this would result in the module cache
	-- deviating into a bunch of separate ones.
	--
	-- TODO: This is a little janky, so we should find a way to do this that's a
	-- little more robust. We may want to apply it to anything in RobloxJest?
	if scriptInstance == script or scriptInstance == script.Parent then
		return require(scriptInstance)
	end

	-- If already loaded and cached, return cached module. This should behave
	-- similarly to normal `require` behavior
	if requiredModules[scriptInstance] ~= nil then
		return requiredModules[scriptInstance]
	end

	local moduleResult
	-- First, check the mock cache and see if this is being mocked
	if mocks[scriptInstance] ~= nil then
		moduleResult = mocks[scriptInstance]()

		if moduleResult == nil then
			error(string.format(
				"[Mock Error]: %s did not return a valid result\n" ..
				"\tmocks must return a non-nil value",
				tostring(scriptInstance)
			))
		end
	else
		-- Narrowing this type here lets us appease the type checker while still
		-- counting on types for the rest of this file
		local loadmodule: (ModuleScript) -> (any, string) = debug["loadmodule"]
		local moduleFunction, errorMessage = loadmodule(scriptInstance)
		assert(moduleFunction ~= nil, errorMessage)

		getfenv(moduleFunction).require = requireOverride
		getfenv(moduleFunction).delay = FakeTimers.delayOverride
		getfenv(moduleFunction).tick = FakeTimers.tickOverride
		moduleResult = moduleFunction()

		if moduleResult == nil then
			error(string.format(
				"[Module Error]: %s did not return a valid result\n" ..
				"\tModuleScripts must return a non-nil value",
				tostring(scriptInstance)
			))
		end
	end

	-- Load normally into the require cache
	requiredModules[scriptInstance] = moduleResult

	return moduleResult
end

local function resetModules()
	-- Clear all modules in the override require cache
	requiredModules = {}

	-- Clear any established mocks
	mocks = {}
end

local function mock(scriptInstance: ModuleScript, callback: () -> any)
	if mocks[scriptInstance] ~= nil then
		warn(string.format(
			"%s is already being mocked!",
			tostring(scriptInstance)
		))
	end

	-- If there's a cached actual value, clear it out so that a new require
	-- will get the mock
	if requiredModules[scriptInstance] ~= nil then
		requiredModules[scriptInstance] = nil
	end

	-- Silence type errors
	local getfenv: any = getfenv
	-- Make sure that the further requires used by this mock will also be using
	-- the require override
	getfenv(callback).require = requireOverride
	getfenv(callback).delay = FakeTimers.delayOverride
	getfenv(callback).tick = FakeTimers.tickOverride
	mocks[scriptInstance] = callback
end

local function unmock(scriptInstance: ModuleScript)
	if mocks[scriptInstance] == nil then
		warn(string.format(
			"Attempting to unmock %s, but it's not being mocked!",
			tostring(scriptInstance)
		))
	end

	-- If there's a cached mock value, clear it out so that a new require won't
	-- get the mock
	if requiredModules[scriptInstance] ~= nil then
		requiredModules[scriptInstance] = nil
	end

	mocks[scriptInstance] = nil
end

return {
	requireOverride = requireOverride,
	resetModules = resetModules,
	mock = mock,
	unmock = unmock,
}