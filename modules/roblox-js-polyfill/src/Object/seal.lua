-- FIXME: We need to shore this up to be much closer to the actual
-- `Object.seal` functionality in JS
local function seal(t)
	local name = tostring(t)

	return setmetatable(t, {
		__newindex = function(self, key, value)
			local message = ("%q (%s) is not a valid member of %s"):format(
				tostring(key),
				typeof(key),
				name
			)

			error(message, 2)
		end,
		__metatable = false,
	})
end

return seal