local DEFAULT_NAME = "Error"

local function Error(message)
	return setmetatable({
		name = DEFAULT_NAME,
		message = message,
	}, {
		__tostring = function(self)
			return string.format("%s: %s", tostring(self.name), tostring(self.message))
		end,
	})
end

return Error