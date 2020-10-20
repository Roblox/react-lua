-- upstream: https://github.com/facebook/react/blob/55cb0b7eeb0e539d89858b8ed69beabf7fe2fb46/packages/shared/checkPropTypes.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local Workspace = script.Parent.Parent
local console = require(Workspace.RobloxJSPolyfill.console)
local Error = require(Workspace.RobloxJSPolyfill.Error)

local loggedTypeFailures = {}

local ReactComponentStackFrame = require(script.Parent["ReactComponentStackFrame.roblox"])
local describeUnknownElementTypeFrameInDEV = ReactComponentStackFrame.describeUnknownElementTypeFrameInDEV

local ReactSharedInternals = require(script.Parent.ReactSharedInternals)

local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame

function setCurrentlyValidatingElement(element)
	if _G.__DEV__ then
		if element then
			local owner = element._owner
			local stack = describeUnknownElementTypeFrameInDEV(
				element.type,
				element._source,
				owner ~= nil and owner.type or nil
			)
			ReactDebugCurrentFrame.setExtraStackFrame(stack)
		else
			ReactDebugCurrentFrame.setExtraStackFrame(nil)
		end
	end
end

local function checkPropTypes(typeSpecs, values, location, componentName, element)
	if _G.__DEV__ then
		-- deviation: hasOwnProperty shouldn't be relevant to lua objects
		-- $FlowFixMe This is okay but Flow doesn't know it.
		-- local has = Function.call.bind(Object.prototype.hasOwnProperty)

		for typeSpecName, _ in pairs(typeSpecs) do
			-- deviation: since our loop won't hit metatable members, we don't
			-- need to worry about encountering inherited properties here
			-- if has(typeSpecs, typeSpecName) then

			-- Prop type validation may throw. In case they do, we don't want to
			-- fail the render phase where it didn't fail before. So we log it.
			-- After these have been cleaned up, we'll local them throw.
			local _, result = pcall(function()
				-- This is intentionally an invariant that gets caught. It's the same
				-- behavior as without this statement except with a better message.
				if typeof(typeSpecs[typeSpecName]) ~= 'function' then
					local err = Error(
						(componentName or 'React class') ..
						': ' ..
						location ..
						' type `' ..
						typeSpecName ..
						'` is invalid; ' ..
						'it must be a function, usually from the `prop-types` package, but received `' ..
						typeof(typeSpecs[typeSpecName]) ..
						'`.' ..
						'This often happens because of typos such as `PropTypes.function` instead of `PropTypes.func`.'
					)
					err.name = 'Invariant Violation'
					error(err)
				end

				return typeSpecs[typeSpecName](
					values,
					typeSpecName,
					componentName,
					location,
					nil,
					'SECRET_DO_NOT_PASS_THIS_OR_YOU_WILL_BE_FIRED'
				)
			end)

			-- deviation: FIXME: Can we expose something from JSPolyfill that
			-- will let us verify that this is specifically the Error object
			-- defined there?
			local isErrorObject = typeof(result) == "table"
			if result ~= nil and not isErrorObject then
				setCurrentlyValidatingElement(element)
				console.error(string.format(
					'%s: type specification of %s' ..
						' `%s` is invalid; the type checker ' ..
						'function must return `null` or an `Error` but returned a %s. ' ..
						'You may have forgotten to pass an argument to the type checker ' ..
						'creator (arrayOf, instanceOf, objectOf, oneOf, oneOfType, and ' ..
						'shape all require an argument).',
					componentName or 'React class',
					location,
					typeSpecName,
					typeof(result)
				))
				setCurrentlyValidatingElement(nil)
			end

			if isErrorObject and loggedTypeFailures[result.message] == nil then
				-- Only monitor this failure once because there tends to be a lot of the
				-- same error.
				loggedTypeFailures[result.message] = true
				setCurrentlyValidatingElement(element)
				warn(string.format('Failed %s type: %s', location, result.message))
				setCurrentlyValidatingElement(nil)
			end
		end
	end
end

return checkPropTypes
