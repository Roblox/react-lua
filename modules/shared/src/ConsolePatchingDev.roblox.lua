-- deviation: Lua objects don't have any special properties the way that JS
-- Objects do; this has been modified from the JS, which uses
-- `Object.defineProperties` to ensure that properties are modifiable. In Lua,
-- these operations are as simple as assigning to functions.
local Workspace = script.Parent.Parent
local console = require(Workspace.RobloxJSPolyfill.console)

 -- Helpers to patch console.logs to avoid logging during side-effect free
-- replaying on render function. This currently only patches the object
-- lazily which won't cover if the log function was extracted eagerly.
-- We could also eagerly patch the method.
local disabledDepth = 0
local prevLog
local prevInfo
local prevWarn
local prevError
local prevGroup
local prevGroupCollapsed
local prevGroupEnd

local disabledLog = function() end

local exports = {}
exports.disableLogs = function()
	if _G.__DEV__ then
		if disabledDepth == 0 then
			prevLog = console.log
			prevInfo = console.info
			prevWarn = console.warn
			prevError = console.error
			prevGroup = console.group
			prevGroupCollapsed = console.groupCollapsed
			prevGroupEnd = console.groupEnd

			console.info = disabledLog
			console.log = disabledLog
			console.warn = disabledLog
			console.error = disabledLog
			console.group = disabledLog
			console.groupCollapsed = disabledLog
			console.groupEnd = disabledLog
		end

		disabledDepth = disabledDepth + 1
	end
end

exports.reenableLogs = function()
	if _G.__DEV__ then
		disabledDepth = disabledDepth - 1

		if disabledDepth == 0 then
			console.log = prevLog
			console.info = prevInfo
			console.warn = prevWarn
			console.error = prevError
			console.group = prevGroup
			console.groupCollapsed = prevGroupCollapsed
			console.groupEnd = prevGroupEnd
		end

		if disabledDepth < 0 then
			console.error('disabledDepth fell below zero. ' + 'This is a bug in React. Please file an issue.')
		end
	end
end

return exports
