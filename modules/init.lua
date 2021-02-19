local React = require(script.React)
local ReactRobloxRenderer = require(script.ReactRobloxRenderer)

return {
	-- __SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,
	Component = React.Component,
	PureComponent = React.PureComponent,
	createElement = React.createElement,
	-- cloneElement = React.cloneElement,
	-- isValidElement = React.isValidElement,
	createRef = React.createRef,
	-- forwardRef = React.forwardRef,
	-- Fragment = React.REACT_FRAGMENT_TYPE,
	-- Profiler = React.REACT_PROFILER_TYPE,
	-- StrictMode = React.REACT_STRICT_MODE_TYPE,
	-- Suspense = React.REACT_SUSPENSE_TYPE,
	-- memo = React.memo,
	-- useState = React.useState,
	-- useReducer = React.useReducer,
	-- useEffect = React.useEffect,
	-- useLayoutEffect = React.useLayoutEffect,
	-- useRef = React.useRef,
	-- useMemo = React.useMemo,
	-- useContext = React.useContext,
	createContext = React.createContext,

	-- render = ReactRobloxRenderer.render,
	createRoot = ReactRobloxRenderer.createRoot,
	createBlockingRoot = ReactRobloxRenderer.createBlockingRoot,
	-- createLegacyRoot = ReactRobloxRenderer.createLegacyRoot,
	Event = ReactRobloxRenderer.Event,
	Change = ReactRobloxRenderer.Change,
	createBinding = ReactRobloxRenderer.createBinding,

	-- Compatibility layer for top-level interface
	-- TODO: Add warnings
	update = function(root, element)
		root:render(element)
		return root
	end,
	mount = function(element)
		local root = ReactRobloxRenderer.createLegacyRoot(Instance.new("Folder"))
		root:render(element)
		return root
	end,
	unmount = function(root)
		root:unmount()
	end,

	-- Compatibility layer for special symbol keys, aligning them with simple
	-- reserved props used by upstream
	Children = "children",
	Ref = "ref",
}