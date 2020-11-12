--!strict
return function(source: string): string
	return source:gsub("^[%s]+", ""):gsub("[%s]+$", "")
end
