local Packages = script.Parent.Parent
local ReactRobloxRenderer = require(Packages.ReactRobloxRenderer)

local warnOnce = require(script.Parent.warnOnce)

local function PortalComponent(props)
	if _G.__DEV__ then
		warnOnce("Roact.Portal", "Please use the createPortal API on ReactRobloxRenderer instead")
	end
	return ReactRobloxRenderer.createPortal(props.children, props.target)
end

return PortalComponent
