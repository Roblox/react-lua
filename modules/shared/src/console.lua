-- deviation: this lets us have the same functionality as in React, without
-- having something like Babel to inject a different implementation of
-- console.warn and console.error into the code
-- Instead of using `LuauPolyfill.console`, React internals should use this
-- wrapper to be able to use consoleWithStackDev in dev mode
local Shared = script.Parent
local Packages = Shared.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local console = LuauPolyfill.console
local consoleWithStackDev = require(Shared.consoleWithStackDev)

if _G.__DEV__ then
	local newConsole = setmetatable({
		warn = consoleWithStackDev.warn,
		error = consoleWithStackDev.error,
	}, {
		__index = console,
	})
	return newConsole
end

return console
