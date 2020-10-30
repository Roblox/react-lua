-- deviation: TODO: This is currently just a stub!
local Workspace = script.Parent.Parent
local ReactSharedInternals = require(script.Parent.ReactSharedInternals)
local ReactBaseClasses = require(script.Parent.ReactBaseClasses)
local ReactElement = require(script.Parent.ReactElement)
local ReactCreateRef = require(script.Parent.ReactCreateRef)
local ReactForwardRef = require(script.Parent.ReactForwardRef)
local ReactMemo = require(script.Parent.ReactMemo)
local ReactSymbols = require(Workspace.Shared.ReactSymbols)

return {
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = ReactSharedInternals,
	Component = ReactBaseClasses.Component,
	PureComponent = ReactBaseClasses.PureComponent,
	createElement = ReactElement.createElement,
	cloneElement = ReactElement.cloneElement,
	isValidElement = ReactElement.isValidElement,
	createRef = ReactCreateRef.createRef,
	forwardRef = ReactForwardRef.forwardRef,
	Fragment = ReactSymbols.REACT_FRAGMENT_TYPE,
	Profiler = ReactSymbols.REACT_PROFILER_TYPE,
	StrictMode = ReactSymbols.REACT_STRICT_MODE_TYPE,
	Suspense = ReactSymbols.REACT_SUSPENSE_TYPE,
	memo = ReactMemo.memo
}
