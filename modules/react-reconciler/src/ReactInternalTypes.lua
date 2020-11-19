-- upstream: https://github.com/facebook/react/blob/7baf9d4128d41903de125527b50285ea9862cf9a/packages/react-reconciler/src/ReactInternalTypes.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Workspace = script.Parent.Parent

local ReactElementType = require(Workspace.Shared.ReactElementType)
type Source = ReactElementType.Source;
-- local ReactTypes = require(Workspace.shared.ReactTypes)
-- type RefObject = ReactTypes.RefObject;
type RefObject = any; -- FIXME (roblox): type
-- type ReactContext = ReactTypes.ReactContext;
type ReactContext<T> = any; -- FIXME (roblox): type
-- type MutableSourceSubscribeFn = ReactTypes.MutableSourceSubscribeFn;
-- type MutableSourceGetSnapshotFn = ReactTypes.MutableSourceGetSnapshotFn;
-- type MutableSourceVersion = ReactTypes.MutableSourceVersion;
type MutableSourceVersion = any; -- FIXME (roblox): type
-- type MutableSource = ReactTypes.MutableSource;
type MutableSource<T> = any; -- FIXME (roblox): type

-- local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
-- type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
type SuspenseInstance = any; -- FIXME (roblox): type
-- type TimeoutHandle = ReactFiberHostConfig.TimeoutHandle;
-- type NoTimeout = ReactFiberHostConfig.NoTimeout;
type TimeoutHandle = any; -- FIXME (roblox): type
type NoTimeout = any; -- FIXME (roblox): type
local ReactWorkTags = require(script.Parent.ReactWorkTags)
type WorkTag = ReactWorkTags.WorkTag;
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
type TypeOfMode = ReactTypeOfMode.TypeOfMode;
-- local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
-- type Flags = ReactFiberFlags.Flags;
type Flags = any; -- FIXME (roblox)

-- deviation: FiberLane types defined below

-- local ReactFiberHooks = require(script.Parent["ReactFiberHooks.old"])
-- type HookType = ReactFiberHooks.HookType;
type HookType = any; -- FIXME (roblox): type
local ReactRootTags = require(script.Parent.ReactRootTags)
type RootTag = ReactRootTags.RootTag;
-- local ReactTypes = require(Workspace.shared.ReactTypes)
-- type Wakeable = ReactTypes.Wakeable;
type Wakeable = any; -- FIXME (roblox)
-- local Tracing = require(Workspace.Scheduler.Tracing)
-- type Interaction = Tracing.Interaction;
type Interaction = any; -- FIXME (roblox): type

-- generic types
type Array<T> = { [number]: T };
type Object = { [any]: any };
type Set<T> = { [T]: boolean };

-- deviation: FiberLane types are defined and exported from here to avoid
-- cyclical requires
export type LanePriority = number;
export type Lanes = number;
export type Lane = number;
export type LaneMap<T> = { [number]: T };

-- export type ReactPriorityLevel = 99 | 98 | 97 | 96 | 95 | 90
export type ReactPriorityLevel = number;

-- deviation: Doesn't play nice with `next: ContextDependency<any>`
-- export type ContextDependency<T> = {
-- 	context: ReactContext<T>,
-- 	next: ContextDependency<any>?,
export type ContextDependency = {
	context: ReactContext<any>,
	observedBits: number,
	next: ContextDependency?,
	[any]: any,
};

export type Dependencies = {
	lanes: Lanes,
	firstContext: ContextDependency?,
	[any]: any,
};

-- A Fiber is work on a Component that needs to be done or was done. There can
-- be more than one per component.
export type Fiber = {
	-- These first fields are conceptually members of an Instance. This used to
	-- be split into a separate type and intersected with the other Fiber fields,
	-- but until Flow fixes its intersection bugs, we've merged them into a
	-- single type.

	-- An Instance is shared between all versions of a component. We can easily
	-- break this out into a separate object to avoid copying so much to the
	-- alternate versions of the tree. We put this on a single object for now to
	-- minimize the number of objects created during the initial render.

	-- Tag identifying the type of fiber.
	tag: WorkTag,

	-- Unique identifier of this child.
	key: string?,

	-- The value of element.type which is used to preserve the identity during
	-- reconciliation of this child.
	elementType: any,

	-- The resolved function/class/ associated with this fiber.
	type: any,

	-- The local state associated with this fiber.
	stateNode: any,

	-- Conceptual aliases
	-- parent : Instance -> return The parent happens to be the same as the
	-- return fiber since we've merged the fiber and instance.

	-- Remaining fields belong to Fiber

	-- The Fiber to return to after finishing processing this one.
	-- This is effectively the parent, but there can be multiple parents (two)
	-- so this is only the parent of the thing we're currently processing.
	-- It is conceptually the same as the return address of a stack frame.
	-- deviation: Luau does not allow us to use `return` as a field name
	-- return: Fiber | nil,
	return_: Fiber?,

	-- Singly Linked List Tree Structure.
	child: Fiber?,
	sibling: Fiber?,
	index: number,

	-- The ref last used to attach this node.
	-- I'll avoid adding an owner field for prod and model that as functions.
	ref: (((any) -> ()) & {_stringRef: string?, [any]: any}) | RefObject,

	-- Input is the data coming into process this fiber. Arguments. Props.
	pendingProps: any, -- This type will be more specific once we overload the tag.
	memoizedProps: any, -- The props used to create the output.

	-- A queue of state updates and callbacks.
	updateQueue: any,

	-- The state used to create the output
	memoizedState: any,

	-- Dependencies (contexts, events) for this fiber, if it has any
	dependencies: Dependencies?,

	-- Bitfield that describes properties about the fiber and its subtree. E.g.
	-- the ConcurrentMode flag indicates whether the subtree should be async-by-
	-- default. When a fiber is created, it inherits the mode of its
	-- parent. Additional flags can be set at creation time, but after that the
	-- value should remain unchanged throughout the fiber's lifetime, particularly
	-- before its child fibers are created.
	mode: TypeOfMode,

	-- Effect
	flags: Flags,
	subtreeFlags: Flags,
	deletions: Array<Fiber>?,

	-- Singly linked list fast path to the next fiber with side-effects.
	nextEffect: Fiber?,

	-- The first and last fiber with side-effect within this subtree. This allows
	-- us to reuse a slice of the linked list when we reuse the work done within
	-- this fiber.
	firstEffect: Fiber?,
	lastEffect: Fiber?,

	lanes: Lanes,
	childLanes: Lanes,

	-- This is a pooled version of a Fiber. Every fiber that gets updated will
	-- eventually have a pair. There are cases when we can clean up pairs to save
	-- memory if we need to.
	alternate: Fiber?,

	-- Time spent rendering this Fiber and its descendants for the current update.
	-- This tells us how well the tree makes use of sCU for memoization.
	-- It is reset to 0 each time we render and only updated when we don't bailout.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	actualDuration: number?,

	-- If the Fiber is currently active in the "render" phase,
	-- This marks the time at which the work began.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	actualStartTime: number?,

	-- Duration of the most recent render time for this Fiber.
	-- This value is not updated when we bailout for memoization purposes.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	selfBaseDuration: number?,

	-- Sum of base times for all descendants of this Fiber.
	-- This value bubbles up during the "complete" phase.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	treeBaseDuration: number?,

	-- Conceptual aliases
	-- workInProgress : Fiber ->  alternate The alternate used for reuse happens
	-- to be the same as work in progress.
	-- _G.__DEV__ only
	_debugID: number?,
	_debugSource: Source?,
	_debugOwner: Fiber?,
	_debugIsCurrentlyTiming: boolean?,
	_debugNeedsRemount: boolean?,

	-- Used to verify that the order of hooks does not change between renders.
	_debugHookTypes: Array<HookType>?,
};

export type SuspenseHydrationCallbacks = {
	onHydrated: ((SuspenseInstance) -> ())?,
	onDeleted: ((SuspenseInstance) -> ())?,
	[any]: any,
};

-- deviation: Instead of combining all these props after the fact, we define
-- them all in one to allow Luau's syntax

-- Exported FiberRoot type includes all properties,
-- To avoid requiring potentially error-prone :any casts throughout the project.
-- Profiling properties are only safe to access in profiling builds (when enableSchedulerTracing is true).
-- The types are defined separately within this file to ensure they stay in sync.
-- (We don't have to use an inline :any cast when enableSchedulerTracing is disabled.)
export type FiberRoot = {
	-- ...BaseFiberRootProperties,
	-- The type of root (legacy, batched, concurrent, etc.)
	tag: RootTag,

	-- Any additional information from the host associated with this root.
	containerInfo: any,
	-- Used only by persistent updates.
	pendingChildren: any,
	-- The currently active root fiber. This is the mutable root of the tree.
	current: Fiber,

	pingCache: { [Wakeable]: Set<any> }?,

	-- A finished work-in-progress HostRoot that's ready to be committed.
	finishedWork: Fiber?,
	-- Timeout handle returned by setTimeout. Used to cancel a pending timeout, if
	-- it's superseded by a new one.
	timeoutHandle: TimeoutHandle | NoTimeout,
	-- Top context object, used by renderSubtreeIntoContainer
	context: Object?,
	pendingContext: Object?,
	-- Determines if we should attempt to hydrate on the initial mount
	hydrate: boolean,

	-- Used by useMutableSource hook to avoid tearing during hydration.
	mutableSourceEagerHydrationData: Array<MutableSource<any> | MutableSourceVersion>?,

	-- Node returned by Scheduler.scheduleCallback. Represents the next rendering
	-- task that the root will work on.
	callbackNode: any,
	callbackPriority: LanePriority,
	eventTimes: LaneMap<number>,
	expirationTimes: LaneMap<number>,

	pendingLanes: Lanes,
	suspendedLanes: Lanes,
	pingedLanes: Lanes,
	expiredLanes: Lanes,
	mutableReadLanes: Lanes,

	finishedLanes: Lanes,

	entangledLanes: Lanes,
	entanglements: LaneMap<Lanes>,

	-- ...ProfilingOnlyFiberRootProperties,
	-- The following attributes are only used by interaction tracing builds.
	-- They enable interactions to be associated with their async work,
	-- And expose interaction metadata to the React DevTools Profiler plugin.
	-- Note that these attributes are only defined when the enableSchedulerTracing flag is enabled.
	interactionThreadID: number,
	memoizedInteractions: Set<Interaction>,
	pendingInteractionMap: { [Lane | Lanes]: Set<Interaction> },

	-- ...SuspenseCallbackOnlyFiberRootProperties,
	-- The follow fields are only used by enableSuspenseCallback for hydration.
	hydrationCallbacks: SuspenseHydrationCallbacks?,

	-- ...
	[any]: any,
};

-- type BasicStateAction<S> = (S => S) | S
-- type Dispatch<A> = A => void

-- export type Dispatcher = {|
-- 	readContext<T>(
-- 		context: ReactContext<T>,
-- 		observedBits: void | number | boolean,
-- 	): T,
-- 	useState<S>(initialState: (() => S) | S): [S, Dispatch<BasicStateAction<S>>],
-- 	useReducer<S, I, A>(
-- 		reducer: (S, A) => S,
-- 		initialArg: I,
-- 		init?: (I) => S,
-- 	): [S, Dispatch<A>],
-- 	useContext<T>(
-- 		context: ReactContext<T>,
-- 		observedBits: void | number | boolean,
-- 	): T,
-- 	useRef<T>(initialValue: T): {|current: T|},
-- 	useEffect(
-- 		create: () => (() => void) | void,
-- 		deps: Array<mixed> | void | nil,
-- 	): void,
-- 	useLayoutEffect(
-- 		create: () => (() => void) | void,
-- 		deps: Array<mixed> | void | nil,
-- 	): void,
-- 	useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T,
-- 	useMemo<T>(nextCreate: () => T, deps: Array<mixed> | void | nil): T,
-- 	useImperativeHandle<T>(
-- 		ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
-- 		create: () => T,
-- 		deps: Array<mixed> | void | nil,
-- 	): void,
-- 	useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void,
-- 	useDeferredValue<T>(value: T): T,
-- 	useTransition(): [(() => void) => void, boolean],
-- 	useMutableSource<Source, Snapshot>(
-- 		source: MutableSource<Source>,
-- 		getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
-- 		subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
-- 	): Snapshot,
-- 	useOpaqueIdentifier(): any,

-- 	unstable_isNewReconciler?: boolean,
-- |}

-- deviation: Return something so that the module system is happy
return {}
