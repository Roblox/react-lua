local React = require(script.React)
local ReactRobloxRenderer = require(script.ReactRobloxRenderer)

return {
	-- __SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,
	Component = React.Component,
	PureComponent = React.PureComponent,
	createElement = React.createElement,
	cloneElement = React.cloneElement,
	isValidElement = React.isValidElement,
	createRef = React.createRef,
	forwardRef = React.forwardRef,
	Fragment = React.REACT_FRAGMENT_TYPE,
	Profiler = React.REACT_PROFILER_TYPE,
	StrictMode = React.REACT_STRICT_MODE_TYPE,
	Suspense = React.REACT_SUSPENSE_TYPE,
	lazy = React.lazy,
	memo = React.memo,
	useCallback = React.useCallback,
	useState = React.useState,
	useReducer = React.useReducer,
	useEffect = React.useEffect,
	useImperativeHandle = React.useImperativeHandle,
	useLayoutEffect = React.useLayoutEffect,
	useRef = React.useRef,
	useMemo = React.useMemo,
	useContext = React.useContext,
	createContext = React.createContext,
	unstable_useMutableSource = React.useMutableSource,
	unstable_createMutableSource = React.createMutableSource,

	-- render = ReactRobloxRenderer.render,
	createRoot = ReactRobloxRenderer.createRoot,
	createBlockingRoot = ReactRobloxRenderer.createBlockingRoot,
	createLegacyRoot = ReactRobloxRenderer.createLegacyRoot,
	Event = ReactRobloxRenderer.Event,
	Change = ReactRobloxRenderer.Change,
	createBinding = ReactRobloxRenderer.createBinding,

	update = ReactRobloxRenderer.update,
	mount = ReactRobloxRenderer.mount,
	unmount = ReactRobloxRenderer.unmount,

	-- Additional compatibility affordances
	createFragment = React.createFragment,

	-- Compatibility layer for special symbol keys, aligning them with simple
	-- reserved props used by upstream
	Children = ReactRobloxRenderer.Children,
	Ref = ReactRobloxRenderer.Ref,
}
