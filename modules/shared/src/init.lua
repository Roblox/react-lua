--!strict
-- ROBLOX deviation: Promote `shared` to an actual unpublished package with a
-- real interface instead of just a bag of loose source code

local ReactTypes = require(script.ReactTypes)
local ReactElementType = require(script.ReactElementType)
local ReactFiberHostConfig = require(script.ReactFiberHostConfig)
local ReactSharedInternals = require(script.ReactSharedInternals)

-- Re-export all top-level public types
export type ReactEmpty = ReactTypes.ReactEmpty
export type ReactFragment = ReactTypes.ReactFragment
export type ReactNodeList = ReactTypes.ReactNodeList
export type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
export type ReactConsumer<T> = ReactTypes.ReactConsumer<T>
export type ReactProvider<T> = ReactTypes.ReactProvider<T>
export type ReactContext<T> = ReactTypes.ReactContext<T>
export type ReactPortal = ReactTypes.ReactPortal
export type React_Node = ReactTypes.React_Node
export type React_Element<ElementType> = ReactTypes.React_Element<ElementType>
export type React_Portal = ReactTypes.React_Portal
export type RefObject = ReactTypes.RefObject
export type EventPriority = ReactTypes.EventPriority
export type ReactFundamentalComponentInstance<C, H> =
	ReactTypes.ReactFundamentalComponentInstance<C, H>
export type ReactFundamentalImpl<C, H> = ReactTypes.ReactFundamentalImpl<C, H>
export type ReactFundamentalComponent<C, H> = ReactTypes.ReactFundamentalComponent<C, H>
export type ReactScope = ReactTypes.ReactScope
export type ReactScopeQuery = ReactTypes.ReactScopeQuery
export type ReactScopeInstance = ReactTypes.ReactScopeInstance
export type MutableSourceVersion = ReactTypes.MutableSourceVersion
export type MutableSourceGetSnapshotFn<Source, Snapshot> =
	ReactTypes.MutableSourceGetSnapshotFn<Source, Snapshot>
export type MutableSourceSubscribeFn<Source, Snapshot> =
	ReactTypes.MutableSourceSubscribeFn<Source, Snapshot>
export type MutableSourceGetVersionFn = ReactTypes.MutableSourceGetVersionFn
export type MutableSource<Source> = ReactTypes.MutableSource<Source>
export type Wakeable = ReactTypes.Wakeable
export type Thenable<R> = ReactTypes.Thenable<R>

export type Source = ReactElementType.Source
export type ReactElement = ReactElementType.ReactElement

export type OpaqueIDType = ReactFiberHostConfig.OpaqueIDType

export type Dispatcher = ReactSharedInternals.Dispatcher

return {
	checkPropTypes = require(script.checkPropTypes),
	console = require(script.console),
	ConsolePatchingDev = require(script["ConsolePatchingDev.roblox"]),
	consoleWithStackDev = require(script.consoleWithStackDev),
	enqueueTask = require(script["enqueueTask.roblox"]),
	ExecutionEnvironment = require(script["ExecutionEnvironment.roblox"]),
	formatProdErrorMessage = require(script.formatProdErrorMessage),
	getComponentName = require(script.getComponentName),
	invariant = require(script.invariant),
	invokeGuardedCallbackImpl = require(script.invokeGuardedCallbackImpl),
	isValidElementType = require(script.isValidElementType),
	objectIs = require(script.objectIs),
	ReactComponentStackFrame = require(script.ReactComponentStackFrame),
	ReactElementType = require(script.ReactElementType),
	ReactErrorUtils = require(script.ReactErrorUtils),
	ReactFeatureFlags = require(script.ReactFeatureFlags),
	ReactInstanceMap = require(script.ReactInstanceMap),
	-- ROBLOX deviation: Instead of re-exporting from here, Shared actually owns
	-- these files itself
	ReactSharedInternals = ReactSharedInternals,
	-- ROBLOX deviation: Instead of extracting these out of the reconciler and
	-- then re-injecting the host config _into_ the reconciler, export these
	-- from shared for easier reuse
	ReactFiberHostConfig = ReactFiberHostConfig,

	ReactSymbols = require(script.ReactSymbols),
	ReactVersion = require(script.ReactVersion),
	shallowEqual = require(script.shallowEqual),
	UninitializedState = require(script["UninitializedState.roblox"]),
	ReactTypes = ReactTypes,
}
