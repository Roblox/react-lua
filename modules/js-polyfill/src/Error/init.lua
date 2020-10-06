type ErrorObject = {
	name: string?,
	message: string?,
}

local DEFAULT_NAME = "Error"

local function Error(message): ErrorObject
	return {
		name = DEFAULT_NAME,
		message = message,
	}
end

return Error