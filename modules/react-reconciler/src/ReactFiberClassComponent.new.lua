-- ROBLOX TODO: stub only what's needed by ReactChildFiber.new
local React = require(script.Parent.Parent.React)

local exports = {}

exports.emptyRefsObject = React.Component:extend("").refs

return exports