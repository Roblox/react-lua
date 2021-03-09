-- upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react/src/React.js
-- deviation: TODO: This is currently just a stub!
local React = script.Parent
local Workspace = React.Parent
local ReactSharedInternals = require(React.ReactSharedInternals)
local ReactBaseClasses = require(React.ReactBaseClasses)
local ReactElementValidator = require(React.ReactElementValidator)
local ReactElement = require(React.ReactElement)
local ReactCreateRef = require(React.ReactCreateRef)
local ReactForwardRef = require(React.ReactForwardRef)
local ReactHooks = require(React.ReactHooks)
local ReactMemo = require(React.ReactMemo)
local ReactContext = require(React.ReactContext)
local ReactSymbols = require(Workspace.Shared.ReactSymbols)

local createElement = _G.__DEV__ and
	ReactElementValidator.createElementWithValidation or
	ReactElement.createElement
local cloneElement = _G.__DEV__ and
	ReactElementValidator.cloneElementWithValidation or
	ReactElement.cloneElement

return {
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = ReactSharedInternals,
	Component = ReactBaseClasses.Component,
	PureComponent = ReactBaseClasses.PureComponent,
	createElement = createElement,
	cloneElement = cloneElement,
	isValidElement = ReactElement.isValidElement,
	createRef = ReactCreateRef.createRef,
	forwardRef = ReactForwardRef.forwardRef,
	Fragment = ReactSymbols.REACT_FRAGMENT_TYPE,
	Profiler = ReactSymbols.REACT_PROFILER_TYPE,
	StrictMode = ReactSymbols.REACT_STRICT_MODE_TYPE,
	Suspense = ReactSymbols.REACT_SUSPENSE_TYPE,
	memo = ReactMemo.memo,
	useState = ReactHooks.useState,
	useReducer = ReactHooks.useReducer,
	useEffect = ReactHooks.useEffect,
	useImperativeHandle = ReactHooks.useImperativeHandle,
	useLayoutEffect = ReactHooks.useLayoutEffect,
	useRef = ReactHooks.useRef,
	useMemo = ReactHooks.useMemo,
	useCallback = ReactHooks.useCallback,
	useContext = ReactHooks.useContext,
	createContext = ReactContext.createContext,
	unstable_LegacyHidden = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE
}
