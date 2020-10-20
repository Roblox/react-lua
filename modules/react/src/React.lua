-- deviation: TODO: This is currently just a stub!
local ReactSharedInternals = require(script.Parent.ReactSharedInternals)
local ReactBaseClasses = require(script.Parent.ReactBaseClasses)

return {
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = ReactSharedInternals,
	Component = ReactBaseClasses.Component,
	PureComponent = ReactBaseClasses.PureComponent
}
