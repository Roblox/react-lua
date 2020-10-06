local INDENT = "  "

return function()
	local console = {}
	local indentDepth = 0

	local function indent()
		return string.rep(INDENT, indentDepth)
	end

	function console.log(message, ...)
		print(indent() .. string.format(message, ...))
	end

	function console.info(message, ...)
		print(indent() .. string.format(message, ...))
	end

	function console.warn(message, ...)
		warn(indent() .. string.format(message, ...))
	end

	function console.error(message, ...)
		-- JS' `console.error` doesn't interrupt execution like Lua's `error`,
		-- which is more similar to throwing an exception in JS.
		warn(indent() .. string.format(message, ...))
	end

	function console.group(message, ...)
		print(indent() .. string.format(message, ...))
		indentDepth = indentDepth + 1
	end

	function console.groupCollapsed(message, ...)
		-- There's no smart console, so this is equivalent to `console.group`
		print(indent() .. string.format(message, ...))
		indentDepth = indentDepth + 1
	end

	function console.groupEnd()
		if indentDepth > 0 then
			indentDepth = indentDepth - 1
		end
	end

	return console
end