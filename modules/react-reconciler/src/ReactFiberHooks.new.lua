--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- FIXME (roblox): remove this when our unimplemented
-- local function unimplemented(message)
--   error("FIXME (roblox): " .. message .. " is unimplemented", 2)
-- end

local Workspace = script.Parent.Parent
local Packages = Workspace.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local console = LuauPolyfill.console

-- local type {
--   MutableSource,
--   MutableSourceGetSnapshotFn,
--   MutableSourceSubscribeFn,
--   ReactContext,
-- } = require(Workspace.Shared.ReactTypes)
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
-- type Dispatcher = ReactInternalTypes.Dispatcher;
-- FIXME (roblox): Dispatcher definition
type Dispatcher = any;
type HookType = ReactInternalTypes.HookType;
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel;
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes;
type Lane = ReactFiberLane.Lane;
local ReactHookEffectTags = require(script.Parent.ReactHookEffectTags)
type HookFlags = ReactHookEffectTags.HookFlags;
-- local type {FiberRoot} = require(script.Parent.ReactInternalTypes)
-- local type {OpaqueIDType} = require(script.Parent.ReactFiberHostConfig)

local ReactSharedInternals = require(Workspace.Shared.ReactSharedInternals)
local ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
-- local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
-- local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local enableNewReconciler = ReactFeatureFlags.enableNewReconciler
-- local decoupleUpdatePriorityFromScheduler = ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects

-- local {NoMode, BlockingMode, DebugTracingMode} = require(script.Parent.ReactTypeOfMode)
-- local NoLane = ReactFiberLane.NoLane
local NoLanes = ReactFiberLane.NoLanes
-- local InputContinuousLanePriority = ReactFiberLane.InputContinuousLanePriority
-- local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
-- local mergeLanes = ReactFiberLane.mergeLanes
-- local removeLanes = ReactFiberLane.removeLanes
-- local markRootEntangled = ReactFiberLane.markRootEntangled
-- local markRootMutableRead = ReactFiberLane.markRootMutableRead
-- local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
-- local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
-- local higherLanePriority = ReactFiberLane.higherLanePriority
-- local DefaultLanePriority = ReactFiberLane.DefaultLanePriority
local ReactFiberNewContext = require(script.Parent["ReactFiberNewContext.new"])
local readContext = ReactFiberNewContext.readContext
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
-- local UpdateEffect = ReactFiberFlags.Update
local PassiveEffect = ReactFiberFlags.Passive
local PassiveStaticEffect = ReactFiberFlags.PassiveStatic
-- local MountLayoutDevEffect = ReactFiberFlags.MountLayoutDev
local MountPassiveDevEffect = ReactFiberFlags.MountPassiveDev
local HookHasEffect = ReactHookEffectTags.HasEffect
-- local HookLayout = ReactHookEffectTags.Layout
local HookPassive = ReactHookEffectTags.Passive
-- local {
--   getWorkInProgressRoot,
--   scheduleUpdateOnFiber,
--   requestUpdateLane,
--   requestEventTime,
--   warnIfNotCurrentlyActingEffectsInDEV,
--   warnIfNotCurrentlyActingUpdatesInDev,
--   warnIfNotScopedWithMatchingAct,
--   markSkippedUpdateLanes,
-- } = require(script.Parent.ReactFiberWorkLoop.new)

local invariant = require(Workspace.Shared.invariant)
-- local getComponentName = require(Workspace.Shared.getComponentName)
local is = require(Workspace.Shared.objectIs)
-- local {markWorkInProgressReceivedUpdate} = require(script.Parent.ReactFiberBeginWork.new)
-- local {
--   UserBlockingPriority,
--   NormalPriority,
--   runWithPriority,
--   getCurrentPriorityLevel,
-- } = require(script.Parent.SchedulerWithReactIntegration.new)
-- local {getIsHydrating} = require(script.Parent.ReactFiberHydrationContext.new)
-- local {
--   makeClientId,
--   makeClientIdInDEV,
--   makeOpaqueHydratingObject,
-- } = require(script.Parent.ReactFiberHostConfig)
-- local {
--   getWorkInProgressVersion,
--   markSourceAsDirty,
--   setWorkInProgressVersion,
--   warnAboutMultipleRenderersDEV,
-- } = require(script.Parent.ReactMutableSource.new)
-- local {getIsRendering} = require(script.Parent.ReactCurrentFiber)
-- local {logStateUpdateScheduled} = require(script.Parent.DebugTracing)
-- local {markStateUpdateScheduled} = require(script.Parent.SchedulingProfiler)

local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
-- local ReactCurrentBatchConfig = ReactSharedInternals.ReactCurrentBatchConfig

-- deviation: common types
type Array<T> = { [number]: T };

type Update<S, A> = {
  lane: Lane,
  action: A,
  eagerReducer: ((S, A) -> S) | nil,
  eagerState: S | nil,
  next: Update,
  priority: ReactPriorityLevel?,
};

type UpdateQueue<S, A> = {
  pending: Update<S, A> | nil,
  dispatch: ((A) -> any) | nil,
  lastRenderedReducer: ((S, A) -> S) | nil,
  lastRenderedState: S | nil,
};

-- local didWarnAboutMismatchedHooksForComponent
-- local didWarnAboutUseOpaqueIdentifier
-- if __DEV__)
--   didWarnAboutUseOpaqueIdentifier = {}
--   didWarnAboutMismatchedHooksForComponent = new Set()
-- end

export type Hook = {
  memoizedState: any,
  baseState: any,
  baseQueue: Update<any, any>?,
  queue: UpdateQueue<any, any>?,
  next: Hook?,
};

export type Effect = {
  tag: HookFlags,
  create: () -> (() -> ())?,
  destroy: (() -> ())?,
  deps: Array<any>?,
  next: Effect,
};

export type FunctionComponentUpdateQueue = {
  lastEffect: Effect?
};

-- type BasicStateAction<S> = (S => S) | S

-- type Dispatch<A> = A => void

local exports: any = {}

-- These are set right before calling the component.
local _renderLanes: Lanes = NoLanes
-- The work-in-progress fiber. I've named it differently to distinguish it from
-- the work-in-progress hook.
-- FIXME (roblox): No luau support for `local x: Fiber = (nil: any)`
local currentlyRenderingFiber: any = nil

-- Hooks are stored as a linked list on the fiber's memoizedState field. The
-- current hook list is the list that belongs to the current fiber. The
-- work-in-progress hook list is a new list that will be added to the
-- work-in-progress fiber.
-- FIXME (roblox): type refinement
-- local currentHook: Hook | nil = nil
local currentHook: any = nil
-- FIXME (roblox): type refinement
-- local workInProgressHook: Hook | nil = nil
local workInProgressHook: any = nil

-- Whether an update was scheduled at any point during the render phase. This
-- does not get reset if we do another render pass; only when we're completely
-- finished evaluating this component. This is an optimization so we know
-- whether we need to clear render phase updates after a throw.
local didScheduleRenderPhaseUpdate: boolean = false
-- Where an update was scheduled only during the current render pass. This
-- gets reset after each attempt.
-- TODO: Maybe there's some way to consolidate this with
-- `didScheduleRenderPhaseUpdate`. Or with `numberOfReRenders`.
local didScheduleRenderPhaseUpdateDuringThisPass: boolean = false

local RE_RENDER_LIMIT = 25

-- In DEV, this is the name of the currently executing primitive hook
local currentHookNameInDev: HookType? = nil

-- In DEV, this list ensures that hooks are called in the same order between renders.
-- The list stores the order of hooks used during the initial render (mount).
-- Subsequent renders (updates) reference this list.
local hookTypesDev: Array<HookType> | nil = nil
local _hookTypesUpdateIndexDev: number = -1

-- In DEV, this tracks whether currently rendering component needs to ignore
-- the dependencies for Hooks that need them (e.g. useEffect or useMemo).
-- When true, such Hooks will always be "remounted". Only used during hot reload.
local ignorePreviousDependencies: boolean = false

-- function mountHookTypesDev()
--   if __DEV__)
--     local hookName = ((currentHookNameInDev: any): HookType)

--     if hookTypesDev == nil)
--       hookTypesDev = [hookName]
--     } else {
--       hookTypesDev.push(hookName)
--     end
--   end
-- end

-- function updateHookTypesDev()
--   if __DEV__)
--     local hookName = ((currentHookNameInDev: any): HookType)

--     if hookTypesDev ~= nil)
--       hookTypesUpdateIndexDev++
--       if hookTypesDev[hookTypesUpdateIndexDev] ~= hookName)
--         warnOnHookMismatchInDev(hookName)
--       end
--     end
--   end
-- end

-- function checkDepsAreArrayDev(deps: mixed)
--   if __DEV__)
--     if deps ~= undefined and deps ~= nil and !Array.isArray(deps))
--       -- Verify deps, but only on mount to avoid extra checks.
--       -- It's unlikely their type would change as usually you define them inline.
--       console.error(
--         '%s received a final argument that is not an array (instead, received `%s`). When ' +
--           'specified, the final argument must be an array.',
--         currentHookNameInDev,
--         typeof deps,
--       )
--     end
--   end
-- end

-- function warnOnHookMismatchInDev(currentHookName: HookType)
--   if __DEV__)
--     local componentName = getComponentName(currentlyRenderingFiber.type)
--     if !didWarnAboutMismatchedHooksForComponent.has(componentName))
--       didWarnAboutMismatchedHooksForComponent.add(componentName)

--       if hookTypesDev ~= nil)
--         local table = ''

--         local secondColumnStart = 30

--         for (local i = 0; i <= ((hookTypesUpdateIndexDev: any): number); i++)
--           local oldHookName = hookTypesDev[i]
--           local newHookName =
--             i == ((hookTypesUpdateIndexDev: any): number)
--               ? currentHookName
--               : oldHookName

--           local row = `${i + 1}. ${oldHookName}`

--           -- Extra space so second column lines up
--           -- lol @ IE not supporting String#repeat
--           while (row.length < secondColumnStart)
--             row += ' '
--           end

--           row += newHookName + '\n'

--           table += row
--         end

--         console.error(
--           'React has detected a change in the order of Hooks called by %s. ' +
--             'This will lead to bugs and errors if not fixed. ' +
--             'For more information, read the Rules of Hooks: https:--reactjs.org/link/rules-of-hooks\n\n' +
--             '   Previous render            Next render\n' +
--             '   ------------------------------------------------------\n' +
--             '%s' +
--             '   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n',
--           componentName,
--           table,
--         )
--       end
--     end
--   end
-- end

local function throwInvalidHookError()
  invariant(
    false,
    "Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for" ..
      " one of the following reasons:\n" ..
      "1. You might have mismatching versions of React and the renderer (such as React DOM)\n" ..
      "2. You might be breaking the Rules of Hooks\n" ..
      "3. You might have more than one copy of React in the same app\n" ..
      "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
  )
end

-- FIXME (roblox): type refinement
-- prevDeps: Array<any>?
local function areHookInputsEqual(
  nextDeps: Array<any>,
  prevDeps
)
  if _G.__DEV__ then
    if ignorePreviousDependencies then
      -- Only true when this component is being hot reloaded.
      return false
    end
  end

  if prevDeps == nil then
    if _G.__DEV__ then
      console.error(
        "%s received a final argument during this render, but not during " ..
          "the previous render. Even though the final argument is optional, " ..
          "its type cannot change between renders.",
        currentHookNameInDev
      )
    end
    return false
  end

  if _G.__DEV__ then
    -- Don't bother comparing lengths in prod because these arrays should be
    -- passed inline.
    if #nextDeps ~= #prevDeps then
      console.error(
        "The final argument passed to %s changed size between renders. The " ..
          "order and size of this array must remain constant.\n\n" ..
          "Previous: %s\n" ..
          "Incoming: %s",
        currentHookNameInDev,
        table.concat(prevDeps, ", "),
        table.concat(nextDeps, ", ")
      )
    end
  end
  for i = 0, math.min(#prevDeps, #nextDeps) do
    if is(nextDeps[i], prevDeps[i]) then
      continue
    end
    return false
  end
  return true
end

-- exports.bailoutHooks(
--   current: Fiber,
--   workInProgress: Fiber,
--   lanes: Lanes,
-- )
--   workInProgress.updateQueue = current.updateQueue
--   if __DEV__ and enableDoubleInvokingEffects)
--     workInProgress.flags &= ~(
--       MountPassiveDevEffect |
--       PassiveEffect |
--       MountLayoutDevEffect |
--       UpdateEffect
--     )
--   } else {
--     workInProgress.flags &= ~(PassiveEffect | UpdateEffect)
--   end
--   current.lanes = removeLanes(current.lanes, lanes)
-- end

local _isUpdatingOpaqueValueInRenderPhase = false
exports.resetHooksAfterThrow = function()
  -- We can assume the previous dispatcher is always this one, since we set it
  -- at the beginning of the render phase and there's no re-entrancy.
  ReactCurrentDispatcher.current = exports.ContextOnlyDispatcher

  if didScheduleRenderPhaseUpdate then
    -- There were render phase updates. These are only valid for this render
    -- phase, which we are now aborting. Remove the updates from the queues so
    -- they do not persist to the next render. Do not remove updates from hooks
    -- that weren't processed.
    --
    -- Only reset the updates from the queue if it has a clone. If it does
    -- not have a clone, that means it wasn't processed, and the updates were
    -- scheduled before we entered the render phase.
    -- FIXME (roblox): Better type refinement
    -- local hook: Hook | nil = currentlyRenderingFiber.memoizedState
    local hook: any = currentlyRenderingFiber.memoizedState
    while hook ~= nil do
      local queue = hook.queue
      if queue ~= nil then
        queue.pending = nil
      end
      hook = hook.next
    end
    didScheduleRenderPhaseUpdate = false
  end

  _renderLanes = NoLanes
  currentlyRenderingFiber = nil

  currentHook = nil
  workInProgressHook = nil

  if _G.__DEV__ then
    hookTypesDev = nil
    _hookTypesUpdateIndexDev = -1

    currentHookNameInDev = nil

    _isUpdatingOpaqueValueInRenderPhase = false
  end

  didScheduleRenderPhaseUpdateDuringThisPass = false
end

local function mountWorkInProgressHook(): Hook
  local hook: Hook = {
    memoizedState = nil,

    baseState = nil,
    baseQueue = nil,
    queue = nil,

    next = nil,
  }

  if workInProgressHook == nil then
    -- This is the first hook in the list
    currentlyRenderingFiber.memoizedState = hook
    workInProgressHook = hook
  else
    -- Append to the end of the list
    workInProgressHook = hook
    workInProgressHook.next = hook
  end
  return workInProgressHook
end

local function updateWorkInProgressHook(): Hook
  -- This function is used both for updates and for re-renders triggered by a
  -- render phase update. It assumes there is either a current hook we can
  -- clone, or a work-in-progress hook from a previous render pass that we can
  -- use as a base. When we reach the end of the base list, we must switch to
  -- the dispatcher used for mounts.
  -- FIXME (roblox): type refinement
  -- local nextCurrentHook: Hook?
  local nextCurrentHook
  if currentHook == nil then
    local current = currentlyRenderingFiber.alternate
    if current ~= nil then
      nextCurrentHook = current.memoizedState
    else
      nextCurrentHook = nil
    end
  else
    nextCurrentHook = currentHook.next
  end

  -- FIXME (roblox): type refinement
  -- local nextWorkInProgressHook: Hook?
  local nextWorkInProgressHook
  if workInProgressHook == nil then
    nextWorkInProgressHook = currentlyRenderingFiber.memoizedState
  else
    nextWorkInProgressHook = workInProgressHook.next
  end

  if nextWorkInProgressHook ~= nil then
    -- There's already a work-in-progress. Reuse it.
    workInProgressHook = nextWorkInProgressHook
    nextWorkInProgressHook = workInProgressHook.next

    currentHook = nextCurrentHook
  else
    -- Clone from the current hook.

    invariant(
      nextCurrentHook ~= nil,
      "Rendered more hooks than during the previous render."
    )
    currentHook = nextCurrentHook

    local newHook: Hook = {
      memoizedState = currentHook.memoizedState,

      baseState = currentHook.baseState,
      baseQueue = currentHook.baseQueue,
      queue = currentHook.queue,

      next = nil,
    }

    if workInProgressHook == nil then
      -- This is the first hook in the list.
      currentlyRenderingFiber.memoizedState = newHook
      workInProgressHook = newHook
    else
      -- Append to the end of the list.
      workInProgressHook = newHook
      workInProgressHook.next = newHook
    end
  end
  return workInProgressHook
end

local function createFunctionComponentUpdateQueue(): FunctionComponentUpdateQueue
  return {
    lastEffect = nil,
  }
end

-- function basicStateReducer<S>(state: S, action: BasicStateAction<S>): S {
--   -- $FlowFixMe: Flow doesn't like mixed types
--   return typeof action == 'function' ? action(state) : action
-- end

-- function mountReducer<S, I, A>(
--   reducer: (S, A) => S,
--   initialArg: I,
--   init?: I => S,
-- ): [S, Dispatch<A>] {
--   local hook = mountWorkInProgressHook()
--   local initialState
--   if init ~= undefined)
--     initialState = init(initialArg)
--   } else {
--     initialState = ((initialArg: any): S)
--   end
--   hook.memoizedState = hook.baseState = initialState
--   local queue = (hook.queue = {
--     pending: nil,
--     dispatch: nil,
--     lastRenderedReducer: reducer,
--     lastRenderedState: (initialState: any),
--   })
--   local dispatch: Dispatch<A> = (queue.dispatch = (dispatchAction.bind(
--     nil,
--     currentlyRenderingFiber,
--     queue,
--   ): any))
--   return [hook.memoizedState, dispatch]
-- end

-- function updateReducer<S, I, A>(
--   reducer: (S, A) => S,
--   initialArg: I,
--   init?: I => S,
-- ): [S, Dispatch<A>] {
--   local hook = updateWorkInProgressHook()
--   local queue = hook.queue
--   invariant(
--     queue ~= nil,
--     'Should have a queue. This is likely a bug in React. Please file an issue.',
--   )

--   queue.lastRenderedReducer = reducer

--   local current: Hook = (currentHook: any)

--   -- The last rebase update that is NOT part of the base state.
--   local baseQueue = current.baseQueue

--   -- The last pending update that hasn't been processed yet.
--   local pendingQueue = queue.pending
--   if pendingQueue ~= nil)
--     -- We have new updates that haven't been processed yet.
--     -- We'll add them to the base queue.
--     if baseQueue ~= nil)
--       -- Merge the pending queue and the base queue.
--       local baseFirst = baseQueue.next
--       local pendingFirst = pendingQueue.next
--       baseQueue.next = pendingFirst
--       pendingQueue.next = baseFirst
--     end
--     if __DEV__)
--       if current.baseQueue ~= baseQueue)
--         -- Internal invariant that should never happen, but feasibly could in
--         -- the future if we implement resuming, or some form of that.
--         console.error(
--           'Internal error: Expected work-in-progress queue to be a clone. ' +
--             'This is a bug in React.',
--         )
--       end
--     end
--     current.baseQueue = baseQueue = pendingQueue
--     queue.pending = nil
--   end

--   if baseQueue ~= nil)
--     -- We have a queue to process.
--     local first = baseQueue.next
--     local newState = current.baseState

--     local newBaseState = nil
--     local newBaseQueueFirst = nil
--     local newBaseQueueLast = nil
--     local update = first
--     do {
--       local updateLane = update.lane
--       if !isSubsetOfLanes(renderLanes, updateLane))
--         -- Priority is insufficient. Skip this update. If this is the first
--         -- skipped update, the previous update/state is the new base
--         -- update/state.
--         local clone: Update<S, A> = {
--           lane: updateLane,
--           action: update.action,
--           eagerReducer: update.eagerReducer,
--           eagerState: update.eagerState,
--           next: (null: any),
--         end
--         if newBaseQueueLast == nil)
--           newBaseQueueFirst = newBaseQueueLast = clone
--           newBaseState = newState
--         } else {
--           newBaseQueueLast = newBaseQueueLast.next = clone
--         end
--         -- Update the remaining priority in the queue.
--         -- TODO: Don't need to accumulate this. Instead, we can remove
--         -- renderLanes from the original lanes.
--         currentlyRenderingFiber.lanes = mergeLanes(
--           currentlyRenderingFiber.lanes,
--           updateLane,
--         )
--         markSkippedUpdateLanes(updateLane)
--       } else {
--         -- This update does have sufficient priority.

--         if newBaseQueueLast ~= nil)
--           local clone: Update<S, A> = {
--             -- This update is going to be committed so we never want uncommit
--             -- it. Using NoLane works because 0 is a subset of all bitmasks, so
--             -- this will never be skipped by the check above.
--             lane: NoLane,
--             action: update.action,
--             eagerReducer: update.eagerReducer,
--             eagerState: update.eagerState,
--             next: (null: any),
--           end
--           newBaseQueueLast = newBaseQueueLast.next = clone
--         end

--         -- Process this update.
--         if update.eagerReducer == reducer)
--           -- If this update was processed eagerly, and its reducer matches the
--           -- current reducer, we can use the eagerly computed state.
--           newState = ((update.eagerState: any): S)
--         } else {
--           local action = update.action
--           newState = reducer(newState, action)
--         end
--       end
--       update = update.next
--     } while (update ~= nil and update ~= first)

--     if newBaseQueueLast == nil)
--       newBaseState = newState
--     } else {
--       newBaseQueueLast.next = (newBaseQueueFirst: any)
--     end

--     -- Mark that the fiber performed work, but only if the new state is
--     -- different from the current state.
--     if !is(newState, hook.memoizedState))
--       markWorkInProgressReceivedUpdate()
--     end

--     hook.memoizedState = newState
--     hook.baseState = newBaseState
--     hook.baseQueue = newBaseQueueLast

--     queue.lastRenderedState = newState
--   end

--   local dispatch: Dispatch<A> = (queue.dispatch: any)
--   return [hook.memoizedState, dispatch]
-- end

-- function rerenderReducer<S, I, A>(
--   reducer: (S, A) => S,
--   initialArg: I,
--   init?: I => S,
-- ): [S, Dispatch<A>] {
--   local hook = updateWorkInProgressHook()
--   local queue = hook.queue
--   invariant(
--     queue ~= nil,
--     'Should have a queue. This is likely a bug in React. Please file an issue.',
--   )

--   queue.lastRenderedReducer = reducer

--   -- This is a re-render. Apply the new render phase updates to the previous
--   -- work-in-progress hook.
--   local dispatch: Dispatch<A> = (queue.dispatch: any)
--   local lastRenderPhaseUpdate = queue.pending
--   local newState = hook.memoizedState
--   if lastRenderPhaseUpdate ~= nil)
--     -- The queue doesn't persist past this render pass.
--     queue.pending = nil

--     local firstRenderPhaseUpdate = lastRenderPhaseUpdate.next
--     local update = firstRenderPhaseUpdate
--     do {
--       -- Process this render phase update. We don't have to check the
--       -- priority because it will always be the same as the current
--       -- render's.
--       local action = update.action
--       newState = reducer(newState, action)
--       update = update.next
--     } while (update ~= firstRenderPhaseUpdate)

--     -- Mark that the fiber performed work, but only if the new state is
--     -- different from the current state.
--     if !is(newState, hook.memoizedState))
--       markWorkInProgressReceivedUpdate()
--     end

--     hook.memoizedState = newState
--     -- Don't persist the state accumulated from the render phase updates to
--     -- the base state unless the queue is empty.
--     -- TODO: Not sure if this is the desired semantics, but it's what we
--     -- do for gDSFP. I can't remember why.
--     if hook.baseQueue == nil)
--       hook.baseState = newState
--     end

--     queue.lastRenderedState = newState
--   end
--   return [newState, dispatch]
-- end

-- type MutableSourceMemoizedState<Source, Snapshot> = {|
--   refs: {
--     getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--     setSnapshot: Snapshot => void,
--   },
--   source: MutableSource<any>,
--   subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
-- |}

-- function readFromUnsubcribedMutableSource<Source, Snapshot>(
--   root: FiberRoot,
--   source: MutableSource<Source>,
--   getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
-- ): Snapshot {
--   if __DEV__)
--     warnAboutMultipleRenderersDEV(source)
--   end

--   local getVersion = source._getVersion
--   local version = getVersion(source._source)

--   -- Is it safe for this component to read from this source during the current render?
--   local isSafeToReadFromSource = false

--   -- Check the version first.
--   -- If this render has already been started with a specific version,
--   -- we can use it alone to determine if we can safely read from the source.
--   local currentRenderVersion = getWorkInProgressVersion(source)
--   if currentRenderVersion ~= nil)
--     -- It's safe to read if the store hasn't been mutated since the last time
--     -- we read something.
--     isSafeToReadFromSource = currentRenderVersion == version
--   } else {
--     -- If there's no version, then this is the first time we've read from the
--     -- source during the current render pass, so we need to do a bit more work.
--     -- What we need to determine is if there are any hooks that already
--     -- subscribed to the source, and if so, whether there are any pending
--     -- mutations that haven't been synchronized yet.
--     --
--     -- If there are no pending mutations, then `root.mutableReadLanes` will be
--     -- empty, and we know we can safely read.
--     --
--     -- If there *are* pending mutations, we may still be able to safely read
--     -- if the currently rendering lanes are inclusive of the pending mutation
--     -- lanes, since that guarantees that the value we're about to read from
--     -- the source is consistent with the values that we read during the most
--     -- recent mutation.
--     isSafeToReadFromSource = isSubsetOfLanes(
--       renderLanes,
--       root.mutableReadLanes,
--     )

--     if isSafeToReadFromSource)
--       -- If it's safe to read from this source during the current render,
--       -- store the version in case other components read from it.
--       -- A changed version number will local those components know to throw and restart the render.
--       setWorkInProgressVersion(source, version)
--     end
--   end

--   if isSafeToReadFromSource)
--     local snapshot = getSnapshot(source._source)
--     if __DEV__)
--       if typeof snapshot == 'function')
--         console.error(
--           'Mutable source should not return a function as the snapshot value. ' +
--             'Functions may close over mutable values and cause tearing.',
--         )
--       end
--     end
--     return snapshot
--   } else {
--     -- This handles the special case of a mutable source being shared between renderers.
--     -- In that case, if the source is mutated between the first and second renderer,
--     -- The second renderer don't know that it needs to reset the WIP version during unwind,
--     -- (because the hook only marks sources as dirty if it's written to their WIP version).
--     -- That would cause this tear check to throw again and eventually be visible to the user.
--     -- We can avoid this infinite loop by explicitly marking the source as dirty.
--     --
--     -- This can lead to tearing in the first renderer when it resumes,
--     -- but there's nothing we can do about that (short of throwing here and refusing to continue the render).
--     markSourceAsDirty(source)

--     invariant(
--       false,
--       'Cannot read from mutable source during the current render without tearing. This is a bug in React. Please file an issue.',
--     )
--   end
-- end

-- function useMutableSource<Source, Snapshot>(
--   hook: Hook,
--   source: MutableSource<Source>,
--   getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--   subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
-- ): Snapshot {
--   local root = ((getWorkInProgressRoot(): any): FiberRoot)
--   invariant(
--     root ~= nil,
--     'Expected a work-in-progress root. This is a bug in React. Please file an issue.',
--   )

--   local getVersion = source._getVersion
--   local version = getVersion(source._source)

--   local dispatcher = ReactCurrentDispatcher.current

--   -- eslint-disable-next-line prefer-const
--   local [currentSnapshot, setSnapshot] = dispatcher.useState(() =>
--     readFromUnsubcribedMutableSource(root, source, getSnapshot),
--   )
--   local snapshot = currentSnapshot

--   -- Grab a handle to the state hook as well.
--   -- We use it to clear the pending update queue if we have a new source.
--   local stateHook = ((workInProgressHook: any): Hook)

--   local memoizedState = ((hook.memoizedState: any): MutableSourceMemoizedState<
--     Source,
--     Snapshot,
--   >)
--   local refs = memoizedState.refs
--   local prevGetSnapshot = refs.getSnapshot
--   local prevSource = memoizedState.source
--   local prevSubscribe = memoizedState.subscribe

--   local fiber = currentlyRenderingFiber

--   hook.memoizedState = ({
--     refs,
--     source,
--     subscribe,
--   }: MutableSourceMemoizedState<Source, Snapshot>)

--   -- Sync the values needed by our subscription handler after each commit.
--   dispatcher.useEffect(() => {
--     refs.getSnapshot = getSnapshot

--     -- Normally the dispatch function for a state hook never changes,
--     -- but this hook recreates the queue in certain cases  to avoid updates from stale sources.
--     -- handleChange() below needs to reference the dispatch function without re-subscribing,
--     -- so we use a ref to ensure that it always has the latest version.
--     refs.setSnapshot = setSnapshot

--     -- Check for a possible change between when we last rendered now.
--     local maybeNewVersion = getVersion(source._source)
--     if !is(version, maybeNewVersion))
--       local maybeNewSnapshot = getSnapshot(source._source)
--       if __DEV__)
--         if typeof maybeNewSnapshot == 'function')
--           console.error(
--             'Mutable source should not return a function as the snapshot value. ' +
--               'Functions may close over mutable values and cause tearing.',
--           )
--         end
--       end

--       if !is(snapshot, maybeNewSnapshot))
--         setSnapshot(maybeNewSnapshot)

--         local lane = requestUpdateLane(fiber)
--         markRootMutableRead(root, lane)
--       end
--       -- If the source mutated between render and now,
--       -- there may be state updates already scheduled from the old source.
--       -- Entangle the updates so that they render in the same batch.
--       markRootEntangled(root, root.mutableReadLanes)
--     end
--   }, [getSnapshot, source, subscribe])

--   -- If we got a new source or subscribe function, re-subscribe in a passive effect.
--   dispatcher.useEffect(() => {
--     local handleChange = () => {
--       local latestGetSnapshot = refs.getSnapshot
--       local latestSetSnapshot = refs.setSnapshot

--       try {
--         latestSetSnapshot(latestGetSnapshot(source._source))

--         -- Record a pending mutable source update with the same expiration time.
--         local lane = requestUpdateLane(fiber)

--         markRootMutableRead(root, lane)
--       } catch (error)
--         -- A selector might throw after a source mutation.
--         -- e.g. it might try to read from a part of the store that no longer exists.
--         -- In this case we should still schedule an update with React.
--         -- Worst case the selector will throw again and then an error boundary will handle it.
--         latestSetSnapshot(
--           (() => {
--             throw error
--           }: any),
--         )
--       end
--     end

--     local unsubscribe = subscribe(source._source, handleChange)
--     if __DEV__)
--       if typeof unsubscribe ~= 'function')
--         console.error(
--           'Mutable source subscribe function must return an unsubscribe function.',
--         )
--       end
--     end

--     return unsubscribe
--   }, [source, subscribe])

--   -- If any of the inputs to useMutableSource change, reading is potentially unsafe.
--   --
--   -- If either the source or the subscription have changed we can't can't trust the update queue.
--   -- Maybe the source changed in a way that the old subscription ignored but the new one depends on.
--   --
--   -- If the getSnapshot function changed, we also shouldn't rely on the update queue.
--   -- It's possible that the underlying source was mutated between the when the last "change" event fired,
--   -- and when the current render (with the new getSnapshot function) is processed.
--   --
--   -- In both cases, we need to throw away pending updates (since they are no longer relevant)
--   -- and treat reading from the source as we do in the mount case.
--   if
--     !is(prevGetSnapshot, getSnapshot) or
--     !is(prevSource, source) or
--     !is(prevSubscribe, subscribe)
--   )
--     -- Create a new queue and setState method,
--     -- So if there are interleaved updates, they get pushed to the older queue.
--     -- When this becomes current, the previous queue and dispatch method will be discarded,
--     -- including any interleaving updates that occur.
--     local newQueue = {
--       pending: nil,
--       dispatch: nil,
--       lastRenderedReducer: basicStateReducer,
--       lastRenderedState: snapshot,
--     end
--     newQueue.dispatch = setSnapshot = (dispatchAction.bind(
--       nil,
--       currentlyRenderingFiber,
--       newQueue,
--     ): any)
--     stateHook.queue = newQueue
--     stateHook.baseQueue = nil
--     snapshot = readFromUnsubcribedMutableSource(root, source, getSnapshot)
--     stateHook.memoizedState = stateHook.baseState = snapshot
--   end

--   return snapshot
-- end

-- function mountMutableSource<Source, Snapshot>(
--   source: MutableSource<Source>,
--   getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--   subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
-- ): Snapshot {
--   local hook = mountWorkInProgressHook()
--   hook.memoizedState = ({
--     refs: {
--       getSnapshot,
--       setSnapshot: (null: any),
--     },
--     source,
--     subscribe,
--   }: MutableSourceMemoizedState<Source, Snapshot>)
--   return useMutableSource(hook, source, getSnapshot, subscribe)
-- end

-- function updateMutableSource<Source, Snapshot>(
--   source: MutableSource<Source>,
--   getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--   subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
-- ): Snapshot {
--   local hook = updateWorkInProgressHook()
--   return useMutableSource(hook, source, getSnapshot, subscribe)
-- end

-- function mountState<S>(
--   initialState: (() => S) | S,
-- ): [S, Dispatch<BasicStateAction<S>>] {
--   local hook = mountWorkInProgressHook()
--   if typeof initialState == 'function')
--     -- $FlowFixMe: Flow doesn't like mixed types
--     initialState = initialState()
--   end
--   hook.memoizedState = hook.baseState = initialState
--   local queue = (hook.queue = {
--     pending: nil,
--     dispatch: nil,
--     lastRenderedReducer: basicStateReducer,
--     lastRenderedState: (initialState: any),
--   })
--   local dispatch: Dispatch<
--     BasicStateAction<S>,
--   > = (queue.dispatch = (dispatchAction.bind(
--     nil,
--     currentlyRenderingFiber,
--     queue,
--   ): any))
--   return [hook.memoizedState, dispatch]
-- end

-- function updateState<S>(
--   initialState: (() => S) | S,
-- ): [S, Dispatch<BasicStateAction<S>>] {
--   return updateReducer(basicStateReducer, (initialState: any))
-- end

-- function rerenderState<S>(
--   initialState: (() => S) | S,
-- ): [S, Dispatch<BasicStateAction<S>>] {
--   return rerenderReducer(basicStateReducer, (initialState: any))
-- end

local function pushEffect(tag, create, destroy, deps)
  local effect: Effect = {
    tag = tag,
    create = create,
    destroy = destroy,
    deps = deps,
    -- Circular
    next = nil,
  }
  -- FIXME (roblox): type coercion
  -- local componentUpdateQueue: FunctionComponentUpdateQueue? = (currentlyRenderingFiber.updateQueue: any)
  local componentUpdateQueue = currentlyRenderingFiber.updateQueue
  if componentUpdateQueue == nil then
    componentUpdateQueue = createFunctionComponentUpdateQueue()
    currentlyRenderingFiber.updateQueue = componentUpdateQueue
    componentUpdateQueue.lastEffect = effect
    effect.next = effect
  else
    local lastEffect = componentUpdateQueue.lastEffect
    if lastEffect == nil then
      componentUpdateQueue.lastEffect = effect
      effect.next = effect
    else
      local firstEffect = lastEffect.next
      lastEffect.next = effect
      effect.next = firstEffect
      componentUpdateQueue.lastEffect = effect
    end
  end
  return effect
end

local function mountEffectImpl(fiberFlags, hookFlags, create, deps)
  local hook = mountWorkInProgressHook()
  -- deviation: no need to account for undefined
  -- local nextDeps = deps == undefined ? nil : deps
  local nextDeps = deps
  currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags, fiberFlags)

  hook.memoizedState = pushEffect(
    bit32.bor(HookHasEffect, hookFlags),
    create,
    nil,
    nextDeps
  )
end

function updateEffectImpl(fiberFlags, hookFlags, create, deps)
  local hook = updateWorkInProgressHook()
  -- deviation: no need to account for undefined
  -- local nextDeps = deps == undefined ? nil : deps
  local nextDeps
  local destroy

  if currentHook ~= nil then
    local prevEffect = currentHook.memoizedState
    destroy = prevEffect.destroy
    if nextDeps ~= nil then
      local prevDeps = prevEffect.deps
      if areHookInputsEqual(nextDeps, prevDeps) then
        pushEffect(hookFlags, create, destroy, nextDeps)
        return
      end
    end
  end

  currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags, fiberFlags)

  hook.memoizedState = pushEffect(
    bit32.bor(HookHasEffect, hookFlags),
    create,
    destroy,
    nextDeps
  )
end

local function mountEffect(
  create: () -> (() -> ())?,
  deps: Array<any>?
)
  if _G.__DEV__ then
    -- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ (no jest global)
    -- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
    if _G.__TESTEZ_RUNNING_TEST__ then
      warn("Skip warnIfNotCurrentlyActingEffectsInDEV (creates cycles)")
      -- warnIfNotCurrentlyActingEffectsInDEV(currentlyRenderingFiber)
    end
  end

  if _G.__DEV__ and enableDoubleInvokingEffects then
    return mountEffectImpl(
      bit32.bor(MountPassiveDevEffect, PassiveEffect, PassiveStaticEffect),
      HookPassive,
      create,
      deps
    )
  else
    return mountEffectImpl(
      bit32.bor(PassiveEffect, PassiveStaticEffect),
      HookPassive,
      create,
      deps
    )
  end
end

local function updateEffect(
  create: () -> (() -> ())?,
  deps: Array<any>?
)
  if _G.__DEV__ then
    -- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ (no jest global)
    -- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
    if _G.__TESTEZ_RUNNING_TEST__ then
      warn("Skip warnIfNotCurrentlyActingEffectsInDEV (creates cycles)")
      -- warnIfNotCurrentlyActingEffectsInDEV(currentlyRenderingFiber)
    end
  end
  return updateEffectImpl(
    PassiveEffect,
    HookPassive,
    create,
    deps
  )
end

-- function mountLayoutEffect(
--   create: () => (() => void) | void,
--   deps: Array<mixed> | void | nil,
-- ): void {
--   if __DEV__ and enableDoubleInvokingEffects)
--     return mountEffectImpl(
--       MountLayoutDevEffect | UpdateEffect,
--       HookLayout,
--       create,
--       deps,
--     )
--   } else {
--     return mountEffectImpl(UpdateEffect, HookLayout, create, deps)
--   end
-- end

-- function updateLayoutEffect(
--   create: () => (() => void) | void,
--   deps: Array<mixed> | void | nil,
-- ): void {
--   return updateEffectImpl(UpdateEffect, HookLayout, create, deps)
-- end

-- function imperativeHandleEffect<T>(
--   create: () => T,
--   ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
-- )
--   if typeof ref == 'function')
--     local refCallback = ref
--     local inst = create()
--     refCallback(inst)
--     return () => {
--       refCallback(null)
--     end
--   } else if ref ~= nil and ref ~= undefined)
--     local refObject = ref
--     if __DEV__)
--       if !refObject.hasOwnProperty('current'))
--         console.error(
--           'Expected useImperativeHandle() first argument to either be a ' +
--             'ref callback or React.createRef() object. Instead received: %s.',
--           'an object with keys {' + Object.keys(refObject).join(', ') + '}',
--         )
--       end
--     end
--     local inst = create()
--     refObject.current = inst
--     return () => {
--       refObject.current = nil
--     end
--   end
-- end

-- function mountImperativeHandle<T>(
--   ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--   create: () => T,
--   deps: Array<mixed> | void | nil,
-- ): void {
--   if __DEV__)
--     if typeof create ~= 'function')
--       console.error(
--         'Expected useImperativeHandle() second argument to be a function ' +
--           'that creates a handle. Instead received: %s.',
--         create ~= nil ? typeof create : 'null',
--       )
--     end
--   end

--   -- TODO: If deps are provided, should we skip comparing the ref itself?
--   local effectDeps =
--     deps ~= nil and deps ~= undefined ? deps.concat([ref]) : nil

--   if __DEV__ and enableDoubleInvokingEffects)
--     return mountEffectImpl(
--       MountLayoutDevEffect | UpdateEffect,
--       HookLayout,
--       imperativeHandleEffect.bind(null, create, ref),
--       effectDeps,
--     )
--   } else {
--     return mountEffectImpl(
--       UpdateEffect,
--       HookLayout,
--       imperativeHandleEffect.bind(null, create, ref),
--       effectDeps,
--     )
--   end
-- end

-- function updateImperativeHandle<T>(
--   ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--   create: () => T,
--   deps: Array<mixed> | void | nil,
-- ): void {
--   if __DEV__)
--     if typeof create ~= 'function')
--       console.error(
--         'Expected useImperativeHandle() second argument to be a function ' +
--           'that creates a handle. Instead received: %s.',
--         create ~= nil ? typeof create : 'null',
--       )
--     end
--   end

--   -- TODO: If deps are provided, should we skip comparing the ref itself?
--   local effectDeps =
--     deps ~= nil and deps ~= undefined ? deps.concat([ref]) : nil

--   return updateEffectImpl(
--     UpdateEffect,
--     HookLayout,
--     imperativeHandleEffect.bind(null, create, ref),
--     effectDeps,
--   )
-- end

-- function mountDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--   -- This hook is normally a no-op.
--   -- The react-debug-hooks package injects its own implementation
--   -- so that e.g. DevTools can display custom hook values.
-- end

-- local updateDebugValue = mountDebugValue

-- function mountCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--   local hook = mountWorkInProgressHook()
--   local nextDeps = deps == undefined ? nil : deps
--   hook.memoizedState = [callback, nextDeps]
--   return callback
-- end

-- function updateCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--   local hook = updateWorkInProgressHook()
--   local nextDeps = deps == undefined ? nil : deps
--   local prevState = hook.memoizedState
--   if prevState ~= nil)
--     if nextDeps ~= nil)
--       local prevDeps: Array<mixed> | nil = prevState[1]
--       if areHookInputsEqual(nextDeps, prevDeps))
--         return prevState[0]
--       end
--     end
--   end
--   hook.memoizedState = [callback, nextDeps]
--   return callback
-- end

-- function mountMemo<T>(
--   nextCreate: () => T,
--   deps: Array<mixed> | void | nil,
-- ): T {
--   local hook = mountWorkInProgressHook()
--   local nextDeps = deps == undefined ? nil : deps
--   local nextValue = nextCreate()
--   hook.memoizedState = [nextValue, nextDeps]
--   return nextValue
-- end

-- function updateMemo<T>(
--   nextCreate: () => T,
--   deps: Array<mixed> | void | nil,
-- ): T {
--   local hook = updateWorkInProgressHook()
--   local nextDeps = deps == undefined ? nil : deps
--   local prevState = hook.memoizedState
--   if prevState ~= nil)
--     -- Assume these are defined. If they're not, areHookInputsEqual will warn.
--     if nextDeps ~= nil)
--       local prevDeps: Array<mixed> | nil = prevState[1]
--       if areHookInputsEqual(nextDeps, prevDeps))
--         return prevState[0]
--       end
--     end
--   end
--   local nextValue = nextCreate()
--   hook.memoizedState = [nextValue, nextDeps]
--   return nextValue
-- end

-- function mountDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = mountState(value)
--   mountEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function updateDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = updateState(value)
--   updateEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function rerenderDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = rerenderState(value)
--   updateEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function startTransition(setPending, callback)
--   local priorityLevel = getCurrentPriorityLevel()
--   if decoupleUpdatePriorityFromScheduler)
--     local previousLanePriority = getCurrentUpdateLanePriority()
--     setCurrentUpdateLanePriority(
--       higherLanePriority(previousLanePriority, InputContinuousLanePriority),
--     )

--     runWithPriority(
--       priorityLevel < UserBlockingPriority
--         ? UserBlockingPriority
--         : priorityLevel,
--       () => {
--         setPending(true)
--       },
--     )

--     -- TODO: Can remove this. Was only necessary because we used to give
--     -- different behavior to transitions without a config object. Now they are
--     -- all treated the same.
--     setCurrentUpdateLanePriority(DefaultLanePriority)

--     runWithPriority(
--       priorityLevel > NormalPriority ? NormalPriority : priorityLevel,
--       () => {
--         local prevTransition = ReactCurrentBatchConfig.transition
--         ReactCurrentBatchConfig.transition = 1
--         try {
--           setPending(false)
--           callback()
--         } finally {
--           if decoupleUpdatePriorityFromScheduler)
--             setCurrentUpdateLanePriority(previousLanePriority)
--           end
--           ReactCurrentBatchConfig.transition = prevTransition
--         end
--       },
--     )
--   } else {
--     runWithPriority(
--       priorityLevel < UserBlockingPriority
--         ? UserBlockingPriority
--         : priorityLevel,
--       () => {
--         setPending(true)
--       },
--     )

--     runWithPriority(
--       priorityLevel > NormalPriority ? NormalPriority : priorityLevel,
--       () => {
--         local prevTransition = ReactCurrentBatchConfig.transition
--         ReactCurrentBatchConfig.transition = 1
--         try {
--           setPending(false)
--           callback()
--         } finally {
--           ReactCurrentBatchConfig.transition = prevTransition
--         end
--       },
--     )
--   end
-- end

-- function mountTransition(): [(() => void) => void, boolean] {
--   local [isPending, setPending] = mountState(false)
--   -- The `start` method can be stored on a ref, since `setPending`
--   -- never changes.
--   local start = startTransition.bind(null, setPending)
--   mountRef(start)
--   return [start, isPending]
-- end

-- function updateTransition(): [(() => void) => void, boolean] {
--   local [isPending] = updateState(false)
--   local startRef = updateRef()
--   local start: (() => void) => void = (startRef.current: any)
--   return [start, isPending]
-- end

-- function rerenderTransition(): [(() => void) => void, boolean] {
--   local [isPending] = rerenderState(false)
--   local startRef = updateRef()
--   local start: (() => void) => void = (startRef.current: any)
--   return [start, isPending]
-- end

-- local isUpdatingOpaqueValueInRenderPhase = false
-- exports.getIsUpdatingOpaqueValueInRenderPhaseInDEV(): boolean | void {
--   if __DEV__)
--     return isUpdatingOpaqueValueInRenderPhase
--   end
-- end

-- function warnOnOpaqueIdentifierAccessInDEV(fiber)
--   if __DEV__)
--     -- TODO: Should warn in effects and callbacks, too
--     local name = getComponentName(fiber.type) or 'Unknown'
--     if getIsRendering() and !didWarnAboutUseOpaqueIdentifier[name])
--       console.error(
--         'The object passed back from useOpaqueIdentifier is meant to be ' +
--           'passed through to attributes only. Do not read the ' +
--           'value directly.',
--       )
--       didWarnAboutUseOpaqueIdentifier[name] = true
--     end
--   end
-- end

-- function mountOpaqueIdentifier(): OpaqueIDType | void {
--   local makeId = __DEV__
--     ? makeClientIdInDEV.bind(
--         nil,
--         warnOnOpaqueIdentifierAccessInDEV.bind(null, currentlyRenderingFiber),
--       )
--     : makeClientId

--   if getIsHydrating())
--     local didUpgrade = false
--     local fiber = currentlyRenderingFiber
--     local readValue = () => {
--       if !didUpgrade)
--         -- Only upgrade once. This works even inside the render phase because
--         -- the update is added to a shared queue, which outlasts the
--         -- in-progress render.
--         didUpgrade = true
--         if __DEV__)
--           isUpdatingOpaqueValueInRenderPhase = true
--           setId(makeId())
--           isUpdatingOpaqueValueInRenderPhase = false
--           warnOnOpaqueIdentifierAccessInDEV(fiber)
--         } else {
--           setId(makeId())
--         end
--       end
--       invariant(
--         false,
--         'The object passed back from useOpaqueIdentifier is meant to be ' +
--           'passed through to attributes only. Do not read the value directly.',
--       )
--     end
--     local id = makeOpaqueHydratingObject(readValue)

--     local setId = mountState(id)[1]

--     if (currentlyRenderingFiber.mode & BlockingMode) == NoMode)
--       if __DEV__ and enableDoubleInvokingEffects)
--         currentlyRenderingFiber.flags |=
--           MountPassiveDevEffect | PassiveEffect | PassiveStaticEffect
--       } else {
--         currentlyRenderingFiber.flags |= PassiveEffect | PassiveStaticEffect
--       end
--       pushEffect(
--         HookHasEffect | HookPassive,
--         () => {
--           setId(makeId())
--         },
--         undefined,
--         nil,
--       )
--     end
--     return id
--   } else {
--     local id = makeId()
--     mountState(id)
--     return id
--   end
-- end

-- function updateOpaqueIdentifier(): OpaqueIDType | void {
--   local id = updateState(undefined)[0]
--   return id
-- end

-- function rerenderOpaqueIdentifier(): OpaqueIDType | void {
--   local id = rerenderState(undefined)[0]
--   return id
-- end

-- function dispatchAction<S, A>(
--   fiber: Fiber,
--   queue: UpdateQueue<S, A>,
--   action: A,
-- )
--   if __DEV__)
--     if typeof arguments[3] == 'function')
--       console.error(
--         "State updates from the useState() and useReducer() Hooks don't support the " +
--           'second callback argument. To execute a side effect after ' +
--           'rendering, declare it in the component body with useEffect().',
--       )
--     end
--   end

--   local eventTime = requestEventTime()
--   local lane = requestUpdateLane(fiber)

--   local update: Update<S, A> = {
--     lane,
--     action,
--     eagerReducer: nil,
--     eagerState: nil,
--     next: (null: any),
--   end

--   -- Append the update to the end of the list.
--   local pending = queue.pending
--   if pending == nil)
--     -- This is the first update. Create a circular list.
--     update.next = update
--   } else {
--     update.next = pending.next
--     pending.next = update
--   end
--   queue.pending = update

--   local alternate = fiber.alternate
--   if 
--     fiber == currentlyRenderingFiber or
--     (alternate ~= nil and alternate == currentlyRenderingFiber)
--   )
--     -- This is a render phase update. Stash it in a lazily-created map of
--     -- queue -> linked list of updates. After this render pass, we'll restart
--     -- and apply the stashed updates on top of the work-in-progress hook.
--     didScheduleRenderPhaseUpdateDuringThisPass = didScheduleRenderPhaseUpdate = true
--   } else {
--     if 
--       fiber.lanes == NoLanes and
--       (alternate == nil or alternate.lanes == NoLanes)
--     )
--       -- The queue is currently empty, which means we can eagerly compute the
--       -- next state before entering the render phase. If the new state is the
--       -- same as the current state, we may be able to bail out entirely.
--       local lastRenderedReducer = queue.lastRenderedReducer
--       if lastRenderedReducer ~= nil)
--         local prevDispatcher
--         if __DEV__)
--           prevDispatcher = ReactCurrentDispatcher.current
--           ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--         end
--         try {
--           local currentState: S = (queue.lastRenderedState: any)
--           local eagerState = lastRenderedReducer(currentState, action)
--           -- Stash the eagerly computed state, and the reducer used to compute
--           -- it, on the update object. If the reducer hasn't changed by the
--           -- time we enter the render phase, then the eager state can be used
--           -- without calling the reducer again.
--           update.eagerReducer = lastRenderedReducer
--           update.eagerState = eagerState
--           if is(eagerState, currentState))
--             -- Fast path. We can bail out without scheduling React to re-render.
--             -- It's still possible that we'll need to rebase this update later,
--             -- if the component re-renders for a different reason and by that
--             -- time the reducer has changed.
--             return
--           end
--         } catch (error)
--           -- Suppress the error. It will throw again in the render phase.
--         } finally {
--           if __DEV__)
--             ReactCurrentDispatcher.current = prevDispatcher
--           end
--         end
--       end
--     end
--     if __DEV__)
--       -- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
--       if typeof jest ~= 'undefined')
--         warnIfNotScopedWithMatchingAct(fiber)
--         warnIfNotCurrentlyActingUpdatesInDev(fiber)
--       end
--     end
--     scheduleUpdateOnFiber(fiber, lane, eventTime)
--   end

--   if __DEV__)
--     if enableDebugTracing)
--       if fiber.mode & DebugTracingMode)
--         local name = getComponentName(fiber.type) or 'Unknown'
--         logStateUpdateScheduled(name, lane, action)
--       end
--     end
--   end

--   if enableSchedulingProfiler)
--     markStateUpdateScheduled(fiber, lane)
--   end
-- end

-- deviation: Move these to the top so they're in scope for above functions
local ContextOnlyDispatcher: Dispatcher = {
  readContext = readContext,

  useCallback = throwInvalidHookError,
  useContext = throwInvalidHookError,
  useEffect = throwInvalidHookError,
  useImperativeHandle = throwInvalidHookError,
  useLayoutEffect = throwInvalidHookError,
  useMemo = throwInvalidHookError,
  useReducer = throwInvalidHookError,
  useRef = throwInvalidHookError,
  useState = throwInvalidHookError,
  useDebugValue = throwInvalidHookError,
  useDeferredValue = throwInvalidHookError,
  useTransition = throwInvalidHookError,
  useMutableSource = throwInvalidHookError,
  useOpaqueIdentifier = throwInvalidHookError,

  unstable_isNewReconciler = enableNewReconciler,
}
exports.ContextOnlyDispatcher = ContextOnlyDispatcher

local HooksDispatcherOnMount: Dispatcher = {
  readContext = readContext,

  -- useCallback = mountCallback,
  useContext = readContext,
  useEffect = mountEffect,
  -- useImperativeHandle = mountImperativeHandle,
  -- useLayoutEffect = mountLayoutEffect,
  -- useMemo = mountMemo,
  -- useReducer = mountReducer,
  -- useRef = mountRef,
  -- useState = mountState,
  -- useDebugValue = mountDebugValue,
  -- useDeferredValue = mountDeferredValue,
  -- useTransition = mountTransition,
  -- useMutableSource = mountMutableSource,
  -- useOpaqueIdentifier = mountOpaqueIdentifier,

  unstable_isNewReconciler = enableNewReconciler,
}

local HooksDispatcherOnUpdate: Dispatcher = {
  readContext = readContext,

  -- useCallback = updateCallback,
  useContext = readContext,
  useEffect = updateEffect,
  -- useImperativeHandle = updateImperativeHandle,
  -- useLayoutEffect = updateLayoutEffect,
  -- useMemo = updateMemo,
  -- useReducer = updateReducer,
  -- useRef = updateRef,
  -- useState = updateState,
  -- useDebugValue = updateDebugValue,
  -- useDeferredValue = updateDeferredValue,
  -- useTransition = updateTransition,
  -- useMutableSource = updateMutableSource,
  -- useOpaqueIdentifier = updateOpaqueIdentifier,

  unstable_isNewReconciler = enableNewReconciler,
}

local HooksDispatcherOnRerender: Dispatcher = {
  readContext = readContext,

  -- useCallback = updateCallback,
  useContext = readContext,
  useEffect = updateEffect,
  -- useImperativeHandle = updateImperativeHandle,
  -- useLayoutEffect = updateLayoutEffect,
  -- useMemo = updateMemo,
  -- useReducer = rerenderReducer,
  -- useRef = updateRef,
  -- useState = rerenderState,
  -- useDebugValue = updateDebugValue,
  -- useDeferredValue = rerenderDeferredValue,
  -- useTransition = rerenderTransition,
  -- useMutableSource = updateMutableSource,
  -- useOpaqueIdentifier = rerenderOpaqueIdentifier,

  unstable_isNewReconciler = enableNewReconciler,
}

local HooksDispatcherOnMountInDEV: Dispatcher | nil = nil
local HooksDispatcherOnMountWithHookTypesInDEV: Dispatcher | nil = nil
local HooksDispatcherOnUpdateInDEV: Dispatcher | nil = nil
local HooksDispatcherOnRerenderInDEV: Dispatcher | nil = nil
-- local InvalidNestedHooksDispatcherOnMountInDEV: Dispatcher | nil = nil
-- local InvalidNestedHooksDispatcherOnUpdateInDEV: Dispatcher | nil = nil
-- local InvalidNestedHooksDispatcherOnRerenderInDEV: Dispatcher | nil = nil

-- if __DEV__)
--   local warnInvalidContextAccess = () => {
--     console.error(
--       'Context can only be read while React is rendering. ' +
--         'In classes, you can read it in the render method or getDerivedStateFromProps. ' +
--         'In function components, you can read it directly in the function body, but not ' +
--         'inside Hooks like useReducer() or useMemo().',
--     )
--   end

--   local warnInvalidHookAccess = () => {
--     console.error(
--       'Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks. ' +
--         'You can only call Hooks at the top level of your React function. ' +
--         'For more information, see ' +
--         'https:--reactjs.org/link/rules-of-hooks',
--     )
--   end

--   HooksDispatcherOnMountInDEV = {
--     readContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       return readContext(context, observedBits)
--     },
--     useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useCallback'
--       mountHookTypesDev()
--       checkDepsAreArrayDev(deps)
--       return mountCallback(callback, deps)
--     },
--     useContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       currentHookNameInDev = 'useContext'
--       mountHookTypesDev()
--       return readContext(context, observedBits)
--     },
--     useEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useEffect'
--       mountHookTypesDev()
--       checkDepsAreArrayDev(deps)
--       return mountEffect(create, deps)
--     },
--     useImperativeHandle<T>(
--       ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--       create: () => T,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useImperativeHandle'
--       mountHookTypesDev()
--       checkDepsAreArrayDev(deps)
--       return mountImperativeHandle(ref, create, deps)
--     },
--     useLayoutEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useLayoutEffect'
--       mountHookTypesDev()
--       checkDepsAreArrayDev(deps)
--       return mountLayoutEffect(create, deps)
--     },
--     useMemo<T>(create: () => T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useMemo'
--       mountHookTypesDev()
--       checkDepsAreArrayDev(deps)
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountMemo(create, deps)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useReducer<S, I, A>(
--       reducer: (S, A) => S,
--       initialArg: I,
--       init?: I => S,
--     ): [S, Dispatch<A>] {
--       currentHookNameInDev = 'useReducer'
--       mountHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountReducer(reducer, initialArg, init)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useRef<T>(initialValue: T): {|current: T|} {
--       currentHookNameInDev = 'useRef'
--       mountHookTypesDev()
--       return mountRef(initialValue)
--     },
--     useState<S>(
--       initialState: (() => S) | S,
--     ): [S, Dispatch<BasicStateAction<S>>] {
--       currentHookNameInDev = 'useState'
--       mountHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountState(initialState)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--       currentHookNameInDev = 'useDebugValue'
--       mountHookTypesDev()
--       return mountDebugValue(value, formatterFn)
--     },
--     useDeferredValue<T>(value: T): T {
--       currentHookNameInDev = 'useDeferredValue'
--       mountHookTypesDev()
--       return mountDeferredValue(value)
--     },
--     useTransition(): [(() => void) => void, boolean] {
--       currentHookNameInDev = 'useTransition'
--       mountHookTypesDev()
--       return mountTransition()
--     },
--     useMutableSource<Source, Snapshot>(
--       source: MutableSource<Source>,
--       getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--       subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
--     ): Snapshot {
--       currentHookNameInDev = 'useMutableSource'
--       mountHookTypesDev()
--       return mountMutableSource(source, getSnapshot, subscribe)
--     },
--     useOpaqueIdentifier(): OpaqueIDType | void {
--       currentHookNameInDev = 'useOpaqueIdentifier'
--       mountHookTypesDev()
--       return mountOpaqueIdentifier()
--     },

--     unstable_isNewReconciler: enableNewReconciler,
--   end

--   HooksDispatcherOnMountWithHookTypesInDEV = {
--     readContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       return readContext(context, observedBits)
--     },
--     useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useCallback'
--       updateHookTypesDev()
--       return mountCallback(callback, deps)
--     },
--     useContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       currentHookNameInDev = 'useContext'
--       updateHookTypesDev()
--       return readContext(context, observedBits)
--     },
--     useEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useEffect'
--       updateHookTypesDev()
--       return mountEffect(create, deps)
--     },
--     useImperativeHandle<T>(
--       ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--       create: () => T,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useImperativeHandle'
--       updateHookTypesDev()
--       return mountImperativeHandle(ref, create, deps)
--     },
--     useLayoutEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useLayoutEffect'
--       updateHookTypesDev()
--       return mountLayoutEffect(create, deps)
--     },
--     useMemo<T>(create: () => T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useMemo'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountMemo(create, deps)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useReducer<S, I, A>(
--       reducer: (S, A) => S,
--       initialArg: I,
--       init?: I => S,
--     ): [S, Dispatch<A>] {
--       currentHookNameInDev = 'useReducer'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountReducer(reducer, initialArg, init)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useRef<T>(initialValue: T): {|current: T|} {
--       currentHookNameInDev = 'useRef'
--       updateHookTypesDev()
--       return mountRef(initialValue)
--     },
--     useState<S>(
--       initialState: (() => S) | S,
--     ): [S, Dispatch<BasicStateAction<S>>] {
--       currentHookNameInDev = 'useState'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountState(initialState)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--       currentHookNameInDev = 'useDebugValue'
--       updateHookTypesDev()
--       return mountDebugValue(value, formatterFn)
--     },
--     useDeferredValue<T>(value: T): T {
--       currentHookNameInDev = 'useDeferredValue'
--       updateHookTypesDev()
--       return mountDeferredValue(value)
--     },
--     useTransition(): [(() => void) => void, boolean] {
--       currentHookNameInDev = 'useTransition'
--       updateHookTypesDev()
--       return mountTransition()
--     },
--     useMutableSource<Source, Snapshot>(
--       source: MutableSource<Source>,
--       getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--       subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
--     ): Snapshot {
--       currentHookNameInDev = 'useMutableSource'
--       updateHookTypesDev()
--       return mountMutableSource(source, getSnapshot, subscribe)
--     },
--     useOpaqueIdentifier(): OpaqueIDType | void {
--       currentHookNameInDev = 'useOpaqueIdentifier'
--       updateHookTypesDev()
--       return mountOpaqueIdentifier()
--     },

--     unstable_isNewReconciler: enableNewReconciler,
--   end

--   HooksDispatcherOnUpdateInDEV = {
--     readContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       return readContext(context, observedBits)
--     },
--     useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useCallback'
--       updateHookTypesDev()
--       return updateCallback(callback, deps)
--     },
--     useContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       currentHookNameInDev = 'useContext'
--       updateHookTypesDev()
--       return readContext(context, observedBits)
--     },
--     useEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useEffect'
--       updateHookTypesDev()
--       return updateEffect(create, deps)
--     },
--     useImperativeHandle<T>(
--       ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--       create: () => T,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useImperativeHandle'
--       updateHookTypesDev()
--       return updateImperativeHandle(ref, create, deps)
--     },
--     useLayoutEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useLayoutEffect'
--       updateHookTypesDev()
--       return updateLayoutEffect(create, deps)
--     },
--     useMemo<T>(create: () => T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useMemo'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return updateMemo(create, deps)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useReducer<S, I, A>(
--       reducer: (S, A) => S,
--       initialArg: I,
--       init?: I => S,
--     ): [S, Dispatch<A>] {
--       currentHookNameInDev = 'useReducer'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return updateReducer(reducer, initialArg, init)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useRef<T>(initialValue: T): {|current: T|} {
--       currentHookNameInDev = 'useRef'
--       updateHookTypesDev()
--       return updateRef(initialValue)
--     },
--     useState<S>(
--       initialState: (() => S) | S,
--     ): [S, Dispatch<BasicStateAction<S>>] {
--       currentHookNameInDev = 'useState'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return updateState(initialState)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--       currentHookNameInDev = 'useDebugValue'
--       updateHookTypesDev()
--       return updateDebugValue(value, formatterFn)
--     },
--     useDeferredValue<T>(value: T): T {
--       currentHookNameInDev = 'useDeferredValue'
--       updateHookTypesDev()
--       return updateDeferredValue(value)
--     },
--     useTransition(): [(() => void) => void, boolean] {
--       currentHookNameInDev = 'useTransition'
--       updateHookTypesDev()
--       return updateTransition()
--     },
--     useMutableSource<Source, Snapshot>(
--       source: MutableSource<Source>,
--       getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--       subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
--     ): Snapshot {
--       currentHookNameInDev = 'useMutableSource'
--       updateHookTypesDev()
--       return updateMutableSource(source, getSnapshot, subscribe)
--     },
--     useOpaqueIdentifier(): OpaqueIDType | void {
--       currentHookNameInDev = 'useOpaqueIdentifier'
--       updateHookTypesDev()
--       return updateOpaqueIdentifier()
--     },

--     unstable_isNewReconciler: enableNewReconciler,
--   end

--   HooksDispatcherOnRerenderInDEV = {
--     readContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       return readContext(context, observedBits)
--     },

--     useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useCallback'
--       updateHookTypesDev()
--       return updateCallback(callback, deps)
--     },
--     useContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       currentHookNameInDev = 'useContext'
--       updateHookTypesDev()
--       return readContext(context, observedBits)
--     },
--     useEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useEffect'
--       updateHookTypesDev()
--       return updateEffect(create, deps)
--     },
--     useImperativeHandle<T>(
--       ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--       create: () => T,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useImperativeHandle'
--       updateHookTypesDev()
--       return updateImperativeHandle(ref, create, deps)
--     },
--     useLayoutEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useLayoutEffect'
--       updateHookTypesDev()
--       return updateLayoutEffect(create, deps)
--     },
--     useMemo<T>(create: () => T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useMemo'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
--       try {
--         return updateMemo(create, deps)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useReducer<S, I, A>(
--       reducer: (S, A) => S,
--       initialArg: I,
--       init?: I => S,
--     ): [S, Dispatch<A>] {
--       currentHookNameInDev = 'useReducer'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
--       try {
--         return rerenderReducer(reducer, initialArg, init)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useRef<T>(initialValue: T): {|current: T|} {
--       currentHookNameInDev = 'useRef'
--       updateHookTypesDev()
--       return updateRef(initialValue)
--     },
--     useState<S>(
--       initialState: (() => S) | S,
--     ): [S, Dispatch<BasicStateAction<S>>] {
--       currentHookNameInDev = 'useState'
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
--       try {
--         return rerenderState(initialState)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--       currentHookNameInDev = 'useDebugValue'
--       updateHookTypesDev()
--       return updateDebugValue(value, formatterFn)
--     },
--     useDeferredValue<T>(value: T): T {
--       currentHookNameInDev = 'useDeferredValue'
--       updateHookTypesDev()
--       return rerenderDeferredValue(value)
--     },
--     useTransition(): [(() => void) => void, boolean] {
--       currentHookNameInDev = 'useTransition'
--       updateHookTypesDev()
--       return rerenderTransition()
--     },
--     useMutableSource<Source, Snapshot>(
--       source: MutableSource<Source>,
--       getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--       subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
--     ): Snapshot {
--       currentHookNameInDev = 'useMutableSource'
--       updateHookTypesDev()
--       return updateMutableSource(source, getSnapshot, subscribe)
--     },
--     useOpaqueIdentifier(): OpaqueIDType | void {
--       currentHookNameInDev = 'useOpaqueIdentifier'
--       updateHookTypesDev()
--       return rerenderOpaqueIdentifier()
--     },

--     unstable_isNewReconciler: enableNewReconciler,
--   end

--   InvalidNestedHooksDispatcherOnMountInDEV = {
--     readContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       warnInvalidContextAccess()
--       return readContext(context, observedBits)
--     },
--     useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useCallback'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountCallback(callback, deps)
--     },
--     useContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       currentHookNameInDev = 'useContext'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return readContext(context, observedBits)
--     },
--     useEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useEffect'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountEffect(create, deps)
--     },
--     useImperativeHandle<T>(
--       ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--       create: () => T,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useImperativeHandle'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountImperativeHandle(ref, create, deps)
--     },
--     useLayoutEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useLayoutEffect'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountLayoutEffect(create, deps)
--     },
--     useMemo<T>(create: () => T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useMemo'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountMemo(create, deps)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useReducer<S, I, A>(
--       reducer: (S, A) => S,
--       initialArg: I,
--       init?: I => S,
--     ): [S, Dispatch<A>] {
--       currentHookNameInDev = 'useReducer'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountReducer(reducer, initialArg, init)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useRef<T>(initialValue: T): {|current: T|} {
--       currentHookNameInDev = 'useRef'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountRef(initialValue)
--     },
--     useState<S>(
--       initialState: (() => S) | S,
--     ): [S, Dispatch<BasicStateAction<S>>] {
--       currentHookNameInDev = 'useState'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
--       try {
--         return mountState(initialState)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--       currentHookNameInDev = 'useDebugValue'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountDebugValue(value, formatterFn)
--     },
--     useDeferredValue<T>(value: T): T {
--       currentHookNameInDev = 'useDeferredValue'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountDeferredValue(value)
--     },
--     useTransition(): [(() => void) => void, boolean] {
--       currentHookNameInDev = 'useTransition'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountTransition()
--     },
--     useMutableSource<Source, Snapshot>(
--       source: MutableSource<Source>,
--       getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--       subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
--     ): Snapshot {
--       currentHookNameInDev = 'useMutableSource'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountMutableSource(source, getSnapshot, subscribe)
--     },
--     useOpaqueIdentifier(): OpaqueIDType | void {
--       currentHookNameInDev = 'useOpaqueIdentifier'
--       warnInvalidHookAccess()
--       mountHookTypesDev()
--       return mountOpaqueIdentifier()
--     },

--     unstable_isNewReconciler: enableNewReconciler,
--   end

--   InvalidNestedHooksDispatcherOnUpdateInDEV = {
--     readContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       warnInvalidContextAccess()
--       return readContext(context, observedBits)
--     },
--     useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useCallback'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateCallback(callback, deps)
--     },
--     useContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       currentHookNameInDev = 'useContext'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return readContext(context, observedBits)
--     },
--     useEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useEffect'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateEffect(create, deps)
--     },
--     useImperativeHandle<T>(
--       ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--       create: () => T,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useImperativeHandle'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateImperativeHandle(ref, create, deps)
--     },
--     useLayoutEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useLayoutEffect'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateLayoutEffect(create, deps)
--     },
--     useMemo<T>(create: () => T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useMemo'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return updateMemo(create, deps)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useReducer<S, I, A>(
--       reducer: (S, A) => S,
--       initialArg: I,
--       init?: I => S,
--     ): [S, Dispatch<A>] {
--       currentHookNameInDev = 'useReducer'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return updateReducer(reducer, initialArg, init)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useRef<T>(initialValue: T): {|current: T|} {
--       currentHookNameInDev = 'useRef'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateRef(initialValue)
--     },
--     useState<S>(
--       initialState: (() => S) | S,
--     ): [S, Dispatch<BasicStateAction<S>>] {
--       currentHookNameInDev = 'useState'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return updateState(initialState)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--       currentHookNameInDev = 'useDebugValue'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateDebugValue(value, formatterFn)
--     },
--     useDeferredValue<T>(value: T): T {
--       currentHookNameInDev = 'useDeferredValue'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateDeferredValue(value)
--     },
--     useTransition(): [(() => void) => void, boolean] {
--       currentHookNameInDev = 'useTransition'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateTransition()
--     },
--     useMutableSource<Source, Snapshot>(
--       source: MutableSource<Source>,
--       getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--       subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
--     ): Snapshot {
--       currentHookNameInDev = 'useMutableSource'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateMutableSource(source, getSnapshot, subscribe)
--     },
--     useOpaqueIdentifier(): OpaqueIDType | void {
--       currentHookNameInDev = 'useOpaqueIdentifier'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateOpaqueIdentifier()
--     },

--     unstable_isNewReconciler: enableNewReconciler,
--   end

--   InvalidNestedHooksDispatcherOnRerenderInDEV = {
--     readContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       warnInvalidContextAccess()
--       return readContext(context, observedBits)
--     },

--     useCallback<T>(callback: T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useCallback'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateCallback(callback, deps)
--     },
--     useContext<T>(
--       context: ReactContext<T>,
--       observedBits: void | number | boolean,
--     ): T {
--       currentHookNameInDev = 'useContext'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return readContext(context, observedBits)
--     },
--     useEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useEffect'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateEffect(create, deps)
--     },
--     useImperativeHandle<T>(
--       ref: {|current: T | nil|} | ((inst: T | nil) => mixed) | nil | void,
--       create: () => T,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useImperativeHandle'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateImperativeHandle(ref, create, deps)
--     },
--     useLayoutEffect(
--       create: () => (() => void) | void,
--       deps: Array<mixed> | void | nil,
--     ): void {
--       currentHookNameInDev = 'useLayoutEffect'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateLayoutEffect(create, deps)
--     },
--     useMemo<T>(create: () => T, deps: Array<mixed> | void | nil): T {
--       currentHookNameInDev = 'useMemo'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return updateMemo(create, deps)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useReducer<S, I, A>(
--       reducer: (S, A) => S,
--       initialArg: I,
--       init?: I => S,
--     ): [S, Dispatch<A>] {
--       currentHookNameInDev = 'useReducer'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return rerenderReducer(reducer, initialArg, init)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useRef<T>(initialValue: T): {|current: T|} {
--       currentHookNameInDev = 'useRef'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateRef(initialValue)
--     },
--     useState<S>(
--       initialState: (() => S) | S,
--     ): [S, Dispatch<BasicStateAction<S>>] {
--       currentHookNameInDev = 'useState'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       local prevDispatcher = ReactCurrentDispatcher.current
--       ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
--       try {
--         return rerenderState(initialState)
--       } finally {
--         ReactCurrentDispatcher.current = prevDispatcher
--       end
--     },
--     useDebugValue<T>(value: T, formatterFn: ?(value: T) => mixed): void {
--       currentHookNameInDev = 'useDebugValue'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateDebugValue(value, formatterFn)
--     },
--     useDeferredValue<T>(value: T): T {
--       currentHookNameInDev = 'useDeferredValue'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return rerenderDeferredValue(value)
--     },
--     useTransition(): [(() => void) => void, boolean] {
--       currentHookNameInDev = 'useTransition'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return rerenderTransition()
--     },
--     useMutableSource<Source, Snapshot>(
--       source: MutableSource<Source>,
--       getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
--       subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
--     ): Snapshot {
--       currentHookNameInDev = 'useMutableSource'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return updateMutableSource(source, getSnapshot, subscribe)
--     },
--     useOpaqueIdentifier(): OpaqueIDType | void {
--       currentHookNameInDev = 'useOpaqueIdentifier'
--       warnInvalidHookAccess()
--       updateHookTypesDev()
--       return rerenderOpaqueIdentifier()
--     },

--     unstable_isNewReconciler: enableNewReconciler,
--   end
-- end

-- deviation: Moved to bottom so that its dependencies are defined ahead of it
-- FIXME (roblox): function generics
-- exports.renderWithHooks<Props, SecondArg> = function(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   Component: (p: Props, arg: SecondArg) => any,
--   props: Props,
--   secondArg: SecondArg,
--   nextRenderLanes: Lanes
-- ): any {
exports.renderWithHooks = function(
  current,
  workInProgress: Fiber,
  Component: (any, any) -> any,
  props: any,
  secondArg: any,
  nextRenderLanes: Lanes
): any
  _renderLanes = nextRenderLanes
  currentlyRenderingFiber = workInProgress

  if _G.__DEV__ then
    -- FIXME (roblox): type coercion
    -- hookTypesDev =
    --   current ~= nil
    --     ? ((current._debugHookTypes: any): Array<HookType>)
    --     : nil
    hookTypesDev = current and current._debugHookTypes or nil
    _hookTypesUpdateIndexDev = -1
    -- Used for hot reloading:
    ignorePreviousDependencies =
      current ~= nil and current.type ~= workInProgress.type
  end

  workInProgress.memoizedState = nil
  workInProgress.updateQueue = nil
  workInProgress.lanes = NoLanes

  -- The following should have already been reset
  -- currentHook = nil
  -- workInProgressHook = nil

  -- didScheduleRenderPhaseUpdate = false

  -- TODO Warn if no hooks are used at all during mount, then some are used during update.
  -- Currently we will identify the update render as a mount because memoizedState == nil.
  -- This is tricky because it's valid for certain types of components (e.g. React.lazy)

  -- Using memoizedState to differentiate between mount/update only works if at least one stateful hook is used.
  -- Non-stateful hooks (e.g. context) don't get added to memoizedState,
  -- so memoizedState would be nil during updates and mounts.
  if _G.__DEV__ then
    if current ~= nil and current.memoizedState ~= nil then
      ReactCurrentDispatcher.current = HooksDispatcherOnUpdateInDEV
    elseif hookTypesDev ~= nil then
      -- This dispatcher handles an edge case where a component is updating,
      -- but no stateful hooks have been used.
      -- We want to match the production code behavior (which will use HooksDispatcherOnMount),
      -- but with the extra DEV validation to ensure hooks ordering hasn't changed.
      -- This dispatcher does that.
      ReactCurrentDispatcher.current = HooksDispatcherOnMountWithHookTypesInDEV
    else
      ReactCurrentDispatcher.current = HooksDispatcherOnMountInDEV
    end
  else
    ReactCurrentDispatcher.current =
      (current == nil or current.memoizedState == nil)
        and HooksDispatcherOnMount
        or HooksDispatcherOnUpdate
  end

  local children = Component(props, secondArg)

  -- Check if there was a render phase update
  if didScheduleRenderPhaseUpdateDuringThisPass then
    -- Keep rendering in a loop for as long as render phase updates continue to
    -- be scheduled. Use a counter to prevent infinite loops.
    local numberOfReRenders: number = 0
    repeat
      didScheduleRenderPhaseUpdateDuringThisPass = false
      invariant(
        numberOfReRenders < RE_RENDER_LIMIT,
        "Too many re-renders. React limits the number of renders to prevent " ..
          "an infinite loop."
      )

      numberOfReRenders += 1
      if _G.__DEV__ then
        -- Even when hot reloading, allow dependencies to stabilize
        -- after first render to prevent infinite render phase updates.
        ignorePreviousDependencies = false
      end

      -- Start over from the beginning of the list
      currentHook = nil
      workInProgressHook = nil

      workInProgress.updateQueue = nil

      if _G.__DEV__ then
        -- Also validate hook order for cascading updates.
        _hookTypesUpdateIndexDev = -1
      end

      ReactCurrentDispatcher.current = _G.__DEV__
        and HooksDispatcherOnRerenderInDEV
        or HooksDispatcherOnRerender

      children = Component(props, secondArg)
    until not didScheduleRenderPhaseUpdateDuringThisPass
  end

  -- We can assume the previous dispatcher is always this one, since we set it
  -- at the beginning of the render phase and there's no re-entrancy.
  ReactCurrentDispatcher.current = ContextOnlyDispatcher

  if _G.__DEV__ then
    workInProgress._debugHookTypes = hookTypesDev
  end

  -- This check uses currentHook so that it works the same in DEV and prod bundles.
  -- hookTypesDev could catch more cases (e.g. context) but only in DEV bundles.
  local didRenderTooFewHooks =
    currentHook ~= nil and currentHook.next ~= nil

  _renderLanes = NoLanes
  currentlyRenderingFiber = nil

  currentHook = nil
  workInProgressHook = nil

  if _G.__DEV__ then
    currentHookNameInDev = nil
    hookTypesDev = nil
    _hookTypesUpdateIndexDev = -1
  end

  didScheduleRenderPhaseUpdate = false

  invariant(
    not didRenderTooFewHooks,
    "Rendered fewer hooks than expected. This may be caused by an accidental " ..
      "early return statement."
  )

  return children
end

return exports
