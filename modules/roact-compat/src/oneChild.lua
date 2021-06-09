local Packages = script.Parent.Parent
local React = require(Packages.React)

local warnOnce = require(script.Parent.warnOnce)

local function oneChild(children)
	if _G.__DEV__ then
		warnOnce(
			"oneChild",
			"You likely don't need this at all! If you were assigning children "
				.. "via `React.oneChild(someChildren)`, you can simply use "
				.. "`someChildren` directly."
		)
	end

	-- FIXME: Port `ReactChildren`
	return ((React :: any).Children :: any).only(children)
end

return oneChild
