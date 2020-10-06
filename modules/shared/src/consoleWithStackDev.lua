-- upstream: https://github.com/facebook/react/blob/cb141681750c8221ac799074df09df2bb448c7a4/packages/shared/consoleWithStackDev.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]
-- Unknown globals fail type checking (see "Unknown symbols" section of
-- https://roblox.github.io/luau/typecheck.html)
--!nolint UnknownGlobal
--!nocheck
local Workspace = script.Parent.Parent
local console = require(Workspace.JSPolyfill.console)

local ReactSharedInternals = require(script.Parent.ReactSharedInternals)
-- In DEV, calls to console.warn and console.error get replaced
-- by calls to these methods by a Babel plugin.
--
-- In PROD (or in packages without access to React internals),
-- they are left as they are instead.

-- deviation: declare this ahead of time so that `warn` and `error` are able to
-- reference it
local printWarning

local exports = {}
exports.warn = function(format, ...)
	if __DEV__ then
		-- deviation: varargs works differently in lua
		local argsLength = select("#", ...)
		local args = {}
		for _key = 2, argsLength do
			args[_key - 1] = select(_key, ...)
		end

		printWarning('warn', format, args)
	end
end
exports.error = function(format, ...)
	if __DEV__ then
		-- deviation: varargs works differently in lua
		local argsLength = select("#", ...)
		local args = {}
		for _key = 2, argsLength do
			args[_key - 1] = select(_key, ...)
		end

		printWarning('error', format, args)
	end
end

printWarning = function(level, format, args)
	-- When changing this logic, you might want to also
	-- update consoleWithStackDev.www.js as well.
	if __DEV__ then
		local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame
		local stack = ReactDebugCurrentFrame.getStackAddendum()

		if stack ~= '' then
			format = format .. '%s'
			-- deviation: no array `concat` function in lua
			for _, stackValue in ipairs(args) do
				table.insert(args, stackValue)
			end
		end

		-- deviation: no array `map` or `unshift` function in lua
		local argsWithFormat = {}
		-- Careful: RN currently depends on this prefix
		table.insert(argsWithFormat, 'Warning: ' .. format)
		for _, arg in ipairs(args) do
			table.insert(argsWithFormat, tostring(arg))
		end

		-- We intentionally don't use spread (or .apply) directly because it
		-- breaks IE9: https:--github.com/facebook/react/issues/13610
		-- eslint-disable-next-line react-internal/no-production-logging

		-- deviation: TODO: verify that this behavior maps correctly to:
		-- Function.prototype.apply.call(console[level], console, argsWithFormat)
		console[level](unpack(argsWithFormat))
	end
end

return exports
