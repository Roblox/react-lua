-- TODO: This module will deviate dramatically; we may need to reverse-engineer
-- the intent from tests, and implement equivalent behavior using Lua/Roblox's
-- stack structure

--!nolint LocalShadowPedantic
-- Unknown globals fail type checking (see "Unknown symbols" section of
-- https://roblox.github.io/luau/typecheck.html)
--!nolint UnknownGlobal
--!nocheck
local ReactFeatureFlags = require(script.Parent.ReactFeatureFlags)
local enableComponentStackLocations = ReactFeatureFlags.enableComponentStackLocations

local ReactSymbols = require(script.Parent.ReactSymbols)
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE

-- local ConsolePatchingDev = require(script.Parent["ConsolePatchingDev.roblox"])
-- local disableLogs = ConsolePatchingDev.disableLogs
-- local reenableLogs = ConsolePatchingDev.reenableLogs

-- local ReactSharedInternals = require(script.Parent.ReactSharedInternals)
-- local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher

-- local prefix
local describeComponentFrame, describeNativeComponentFrame, describeUnknownElementTypeFrameInDEV, describeFunctionComponentFrame

local function describeBuiltInComponentFrame(name, source, ownerFn)
	-- if enableComponentStackLocations then
	-- 	if prefix == undefined then
	-- 		-- Extract the VM specific prefix used by each line.
	-- 		try {
	-- 			throw Error()
	-- 		} catch (x) {
	-- 			local match = x.stack.trim().match(/\n( *(at )?)/)
	-- 			prefix = match and match[1] or ''
	-- 		}
	-- 	}
	-- 	-- We use the prefix to ensure our stacks line up with native stack frames.
	-- 	return '\n' + prefix + name
	-- else
	-- 	local ownerName = nil

	-- 	if __DEV__ and ownerFn then
	-- 		ownerName = ownerFn.displayName or ownerFn.name or nil
	-- 	end

	-- 	return describeComponentFrame(name, source, ownerName)
	-- end
end

-- local reentry = false
-- local componentFrameCache

-- if __DEV__ then
-- 	componentFrameCache = {}
-- end

describeNativeComponentFrame = function(fn, construct)
	-- If something asked for a stack inside a fake render, it should get ignored.
	-- if not fn or reentry then
	-- 	return ''
	-- end

	-- if __DEV__ then
	-- 	local frame = componentFrameCache[fn]

	-- 	if frame ~= undefined then
	-- 		return frame
	-- 	end
	-- end

	-- local control
	-- reentry = true
	-- local previousPrepareStackTrace = Error.prepareStackTrace
	-- -- $FlowFixMe It does accept undefined.
	-- Error.prepareStackTrace = undefined
	-- local previousDispatcher

	-- if __DEV__ then
	-- 	previousDispatcher = ReactCurrentDispatcher.current
	-- 	-- Set the dispatcher in DEV because this might be call in the render
	-- 	-- function for warnings.
	-- 	ReactCurrentDispatcher.current = nil
	-- 	disableLogs()
	-- end

	-- try {
	-- 	-- This should throw.
	-- 	if construct then
	-- 		-- Something should be setting the props in the constructor.
	-- 		local Fake = function()
	-- 			error()
	-- 		end

	-- 		-- $FlowFixMe
	-- 		Object.defineProperty(Fake.prototype, 'props', {
	-- 			set: function () {
	-- 				-- We use a throwing setter instead of frozen or non-writable props
	-- 				-- because that won't throw in a non-strict mode function.
	-- 				error()
	-- 			}
	-- 		})

	-- 		if typeof Reflect == 'object' and Reflect.construct then
	-- 			-- We construct a different control for this case to include any extra
	-- 			-- frames added by the construct call.
	-- 			try {
	-- 				Reflect.construct(Fake, [])
	-- 			} catch (x) {
	-- 				control = x
	-- 			}

	-- 			Reflect.construct(fn, [], Fake)
	-- 		} else {
	-- 			try {
	-- 				Fake.call()
	-- 			} catch (x) {
	-- 				control = x
	-- 			}

	-- 			fn.call(Fake.prototype)
	-- 		}
	-- 	} else {
	-- 		try {
	-- 			throw Error()
	-- 		} catch (x) {
	-- 			control = x
	-- 		}

	-- 		fn()
	-- 	}
	-- } catch (sample) {
	-- 	-- This is inlined manually because closure doesn't do it for us.
	-- 	if sample and control and typeof sample.stack == 'string' then
	-- 		-- This extracts the first frame from the sample that isn't also in the control.
	-- 		-- Skipping one frame that we assume is the frame that calls the two.
	-- 		local sampleLines = sample.stack.split('\n')
	-- 		local controlLines = control.stack.split('\n')
	-- 		local s = sampleLines.length - 1
	-- 		local c = controlLines.length - 1

	-- 		while (s >= 1 and c >= 0 and sampleLines[s] ~= controlLines[c]) {
	-- 			-- We expect at least one stack frame to be shared.
	-- 			-- Typically this will be the root most one. However, stack frames may be
	-- 			-- cut off due to maximum stack limits. In this case, one maybe cut off
	-- 			-- earlier than the other. We assume that the sample is longer or the same
	-- 			-- and there for cut off earlier. So we should find the root most frame in
	-- 			-- the sample somewhere in the control.
	-- 			c--
	-- 		}

	-- 		for (; s >= 1 and c >= 0; s--, c--) {
	-- 			-- Next we find the first one that isn't the same which should be the
	-- 			-- frame that called our sample function and the control.
	-- 			if sampleLines[s] ~= controlLines[c] then
	-- 				-- In V8, the first line is describing the message but other VMs don't.
	-- 				-- If we're about to return the first line, and the control is also on the same
	-- 				-- line, that's a pretty good indicator that our sample threw at same line as
	-- 				-- the control. I.e. before we entered the sample frame. So we ignore this result.
	-- 				-- This can happen if you passed a class to function component, or non-function.
	-- 				if s ~= 1 or c ~= 1 then
	-- 					do {
	-- 						s--
	-- 						c--; -- We may still have similar intermediate frames from the construct call.
	-- 						-- The next one that isn't the same should be our match though.

	-- 						if c < 0 or sampleLines[s] ~= controlLines[c] then
	-- 							-- V8 adds a "new" prefix for native classes. Let's remove it to make it prettier.
	-- 							local frame = '\n' + sampleLines[s].replace(' at new ', ' at ')

	-- 							if __DEV__ then
	-- 								if typeof fn == 'function' then
	-- 									componentFrameCache.set(fn, frame)
	-- 								}
	-- 							} -- Return the line we found.


	-- 							return frame
	-- 						}
	-- 					} while (s >= 1 and c >= 0)
	-- 				}

	-- 				break
	-- 			}
	-- 		}
	-- 	}
	-- } finally {
	-- 	reentry = false

	-- 	if __DEV__ then
	-- 		ReactCurrentDispatcher.current = previousDispatcher
	-- 		reenableLogs()
	-- 	}

	-- 	Error.prepareStackTrace = previousPrepareStackTrace
	-- } -- Fallback to just using the name if we couldn't make it throw.


	-- local name = function () {
	-- 	if fn then
	-- 		return fn.displayName or fn.name
	-- 	}

	-- 	return ''
	-- }()

	-- local syntheticFrame = function () {
	-- 	if name then
	-- 		return describeBuiltInComponentFrame(name)
	-- 	}

	-- 	return ''
	-- }()

	-- if __DEV__ then
	-- 	if typeof fn == 'function' then
	-- 		componentFrameCache.set(fn, syntheticFrame)
	-- 	}
	-- }

	-- return syntheticFrame
end

-- deviation: Lua's patterns work slightly differently than regexes
-- local BEFORE_SLASH_PATTERN = "^(.*)[\\/]"

-- deviation: FIXME: This function likely needs to work differently with Roblox
-- Lua modules than it does with js files. For now, it's directly translated.
describeComponentFrame = function(name, source, ownerName)
	-- local sourceInfo = ''

	-- if __DEV__ and source then
	-- 	local path = source.fileName
	-- 	local fileName = string.gsub(path, BEFORE_SLASH_PATTERN, '');

	-- 	-- In DEV, include code for a common special case:
	-- 	-- prefer "folder/index.js" instead of just "index.js".
	-- 	if string.sub(filename, 1, 6) == "index." then
	-- 		-- deviation: finding matching strings works differently in Lua
	-- 		local matches = {}
	-- 		for match in string.gfind(path, BEFORE_SLASH_PATTERN) do
	-- 			table.insert(matches, match)
	-- 		end

	-- 		if matches[2] ~= nil then
	-- 			local pathBeforeSlash = matches[2]

	-- 			local folderName = pathBeforeSlash.replace(BEFORE_SLASH_PATTERN, '')
	-- 			fileName = folderName .. '/' .. fileName
	-- 		end
	-- 	end

	-- 	sourceInfo = ' (at ' .. fileName .. ':' .. source.lineNumber .. ')'
	-- elseif ownerName then
	-- 	sourceInfo = ' (created by ' .. ownerName .. ')'
	-- end

	-- return '\n    in ' .. (name or 'Unknown') .. sourceInfo
end

local describeClassComponentFrame = function(ctor, source, ownerFn)
	if enableComponentStackLocations then
		return describeNativeComponentFrame(ctor, true)
	else
		return describeFunctionComponentFrame(ctor, source, ownerFn)
	end
end

describeFunctionComponentFrame = function(fn, source, ownerFn)
	if enableComponentStackLocations then
		return describeNativeComponentFrame(fn, false)
	else
		if not fn then
			return ''
		end

		local name = fn.displayName or fn.name or nil
		local ownerName = nil

		if __DEV__ and ownerFn then
			ownerName = ownerFn.displayName or ownerFn.name or nil
		end

		return describeComponentFrame(name, source, ownerName)
	end
end

function shouldConstruct(Component)
	-- deviation: FIXME: This will probably need to be implemented differently!
	local prototype = Component.prototype
	return not not (prototype and prototype.isReactComponent)
end

describeUnknownElementTypeFrameInDEV = function(type, source, ownerFn)
	if not __DEV__ then
		return ''
	end

	if type == nil then
		return ''
	end

	if typeof(type) == 'function' then
		if enableComponentStackLocations then
			return describeNativeComponentFrame(type, shouldConstruct(type))
		else
			return describeFunctionComponentFrame(type, source, ownerFn)
		end
	end

	if typeof(type) == 'string' then
		return describeBuiltInComponentFrame(type, source, ownerFn)
	end

	if type == REACT_SUSPENSE_TYPE then
		return describeBuiltInComponentFrame('Suspense', source, ownerFn)

	elseif type == REACT_SUSPENSE_LIST_TYPE then
		return describeBuiltInComponentFrame('SuspenseList', source, ownerFn)
	end

	if typeof(type) == 'table' then
		if type["$$typeof"] == REACT_FORWARD_REF_TYPE then
			return describeFunctionComponentFrame(type.render, source, ownerFn)

		elseif type["$$typeof"] == REACT_MEMO_TYPE then
				-- Memo may contain any component type so we recursively resolve it.
				return describeUnknownElementTypeFrameInDEV(type.type, source, ownerFn)

		elseif type["$$typeof"] == REACT_BLOCK_TYPE then
				return describeFunctionComponentFrame(type._render, source, ownerFn)

		elseif type["$$typeof"] == REACT_LAZY_TYPE then
			local lazyComponent = type
			local payload = lazyComponent._payload
			local init = lazyComponent._init

			local ok, result = pcall(function()
				-- Lazy may contain any component type so we recursively resolve it.
				return describeUnknownElementTypeFrameInDEV(init(payload), source, ownerFn)
			end)

			if ok then
				return result
			end
		end
	end

	return ''
end

return {
	describeBuiltInComponentFrame = describeBuiltInComponentFrame,
	describeNativeComponentFrame = describeNativeComponentFrame,
	describeClassComponentFrame = describeClassComponentFrame,
	describeFunctionComponentFrame = describeFunctionComponentFrame,
	describeUnknownElementTypeFrameInDEV = describeUnknownElementTypeFrameInDEV,
}
