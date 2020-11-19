-- upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberWorkLoop.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Workspace = script.Parent.Parent
local Packages = Workspace.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local console = LuauPolyfill.console

-- local type {Thenable, Wakeable} = require(Workspace.Shared.ReactTypes)
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
type FiberRoot = ReactInternalTypes.FiberRoot;
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes;
type Lane = ReactFiberLane.Lane;
-- local type {ReactPriorityLevel} = require(script.Parent.ReactInternalTypes)
-- local type {Interaction} = require(Workspace.Scheduler.Tracing)
-- local type {SuspenseState} = require(script.Parent["ReactFiberSuspenseComponent.new"])
local ReactFiberStack = require(script.Parent["ReactFiberStack.new"])
type StackCursor<T> = ReactFiberStack.StackCursor<T>;
-- local type {FunctionComponentUpdateQueue} = require(script.Parent["ReactFiberHooks.new"])

local ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
-- local warnAboutDeprecatedLifecycles = ReactFeatureFlags.warnAboutDeprecatedLifecycles
-- local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local replayFailedUnitOfWorkWithInvokeGuardedCallback = ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback
-- local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
-- local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
-- local warnAboutUnmockedScheduler = ReactFeatureFlags.warnAboutUnmockedScheduler
local deferRenderPhaseUpdateToNextBatch = ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch
local decoupleUpdatePriorityFromScheduler = ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
-- local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
-- local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
-- local skipUnmountedBoundaries = ReactFeatureFlags.skipUnmountedBoundaries
-- local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects
-- local ReactSharedInternals = require(Workspace.Shared.ReactSharedInternals)
local invariant = require(Workspace.Shared.invariant)

local SchedulerWithReactIntegration = require(script.Parent["SchedulerWithReactIntegration.new"])
-- local scheduleCallback = SchedulerWithReactIntegration.scheduleCallback
-- local cancelCallback = SchedulerWithReactIntegration.cancelCallback
local getCurrentPriorityLevel = SchedulerWithReactIntegration.getCurrentPriorityLevel
-- local runWithPriority = SchedulerWithReactIntegration.runWithPriority
-- local shouldYield = SchedulerWithReactIntegration.shouldYield
-- local requestPaint = SchedulerWithReactIntegration.requestPaint
local now = SchedulerWithReactIntegration.now
-- local NoSchedulerPriority = SchedulerWithReactIntegration.NoPriority
local ImmediateSchedulerPriority = SchedulerWithReactIntegration.ImmediatePriority
local UserBlockingSchedulerPriority = SchedulerWithReactIntegration.UserBlockingPriority
-- local NormalSchedulerPriority = SchedulerWithReactIntegration.NormalPriority
-- local flushSyncCallbackQueue = SchedulerWithReactIntegration.flushSyncCallbackQueue
-- local scheduleSyncCallback = SchedulerWithReactIntegration.scheduleSyncCallback
-- local {
--   NoFlags as NoHookEffect,
--   Passive as HookPassive,
-- } = require(script.Parent.ReactHookEffectTags)
-- local {
--   logCommitStarted,
--   logCommitStopped,
--   logLayoutEffectsStarted,
--   logLayoutEffectsStopped,
--   logPassiveEffectsStarted,
--   logPassiveEffectsStopped,
--   logRenderStarted,
--   logRenderStopped,
-- } = require(script.Parent.DebugTracing)
-- local {
--   markCommitStarted,
--   markCommitStopped,
--   markLayoutEffectsStarted,
--   markLayoutEffectsStopped,
--   markPassiveEffectsStarted,
--   markPassiveEffectsStopped,
--   markRenderStarted,
--   markRenderYielded,
--   markRenderStopped,
-- } = require(script.Parent.SchedulingProfiler)

-- -- The scheduler is imported here *only* to detect whether it's been mocked
-- local Scheduler = require(Workspace.Scheduler)

-- local {__interactionsRef, __subscriberRef} = require(Workspace.Scheduler.tracing)

-- local {
--   resetAfterCommit,
--   scheduleTimeout,
--   cancelTimeout,
--   noTimeout,
--   warnsIfNotActing,
--   afterActiveInstanceBlur,
--   clearContainer,
-- } = require(script.Parent.ReactFiberHostConfig)

-- local {
--   createWorkInProgress,
--   assignFiberPropertiesInDEV,
-- } = require(script.Parent.ReactFiber.new)
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local NoMode = ReactTypeOfMode.NoMode
-- local StrictMode = ReactTypeOfMode.StrictMode
-- local ProfileMode = ReactTypeOfMode.ProfileMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
-- local {
--   HostRoot,
--   IndeterminateComponent,
--   ClassComponent,
--   SuspenseComponent,
--   SuspenseListComponent,
--   FunctionComponent,
--   ForwardRef,
--   MemoComponent,
--   SimpleMemoComponent,
-- } = require(script.Parent.ReactWorkTags)
-- local {LegacyRoot} = require(script.Parent.ReactRootTags)
-- local {
--   NoFlags,
--   Placement,
--   PassiveStatic,
--   Incomplete,
--   HostEffectMask,
--   Hydrating,
--   BeforeMutationMask,
--   MutationMask,
--   LayoutMask,
--   PassiveMask,
-- } = require(script.Parent.ReactFiberFlags)
local NoLanePriority = ReactFiberLane.NoLanePriority
-- local SyncLanePriority = ReactFiberLane.SyncLanePriority
-- local SyncBatchedLanePriority = ReactFiberLane.SyncBatchedLanePriority
local InputDiscreteLanePriority = ReactFiberLane.InputDiscreteLanePriority
-- local DefaultLanePriority = ReactFiberLane.DefaultLanePriority
local NoLanes = ReactFiberLane.NoLanes
-- local NoLane = ReactFiberLane.NoLane
local SyncLane = ReactFiberLane.SyncLane
local SyncBatchedLane = ReactFiberLane.SyncBatchedLane
local NoTimestamp = ReactFiberLane.NoTimestamp
local findUpdateLane = ReactFiberLane.findUpdateLane
local findTransitionLane = ReactFiberLane.findTransitionLane
-- local findRetryLane = ReactFiberLane.findRetryLane
-- local includesSomeLane = ReactFiberLane.includesSomeLane
-- local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
-- local mergeLanes = ReactFiberLane.mergeLanes
-- local removeLanes = ReactFiberLane.removeLanes
local pickArbitraryLane = ReactFiberLane.pickArbitraryLane
-- local hasDiscreteLanes = ReactFiberLane.hasDiscreteLanes
-- local includesNonIdleWork = ReactFiberLane.includesNonIdleWork
-- local includesOnlyRetries = ReactFiberLane.includesOnlyRetries
-- local includesOnlyTransitions = ReactFiberLane.includesOnlyTransitions
-- local getNextLanes = ReactFiberLane.getNextLanes
-- local returnNextLanesPriority = ReactFiberLane.returnNextLanesPriority
-- local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
-- local markStarvedLanesAsExpired = ReactFiberLane.markStarvedLanesAsExpired
-- local getLanesToRetrySynchronouslyOnError = ReactFiberLane.getLanesToRetrySynchronouslyOnError
-- local getMostRecentEventTime = ReactFiberLane.getMostRecentEventTime
-- local markRootUpdated = ReactFiberLane.markRootUpdated
-- local markRootSuspended_dontCallThisOneDirectly = ReactFiberLane.markRootSuspended
-- local markRootPinged = ReactFiberLane.markRootPinged
-- local markRootExpired = ReactFiberLane.markRootExpired
-- local markDiscreteUpdatesExpired = ReactFiberLane.markDiscreteUpdatesExpired
-- local markRootFinished = ReactFiberLane.markRootFinished
local schedulerPriorityToLanePriority = ReactFiberLane.schedulerPriorityToLanePriority
-- local lanePriorityToSchedulerPriority = ReactFiberLane.lanePriorityToSchedulerPriority
local ReactFiberTransition = require(script.Parent.ReactFiberTransition)
local requestCurrentTransition = ReactFiberTransition.requestCurrentTransition
local NoTransition = ReactFiberTransition.NoTransition
-- local {beginWork as originalBeginWork} = require(script.Parent.ReactFiberBeginWork.new)
-- local {completeWork} = require(script.Parent.ReactFiberCompleteWork.new)
-- local {unwindWork, unwindInterruptedWork} = require(script.Parent.ReactFiberUnwindWork.new)
-- local {
--   throwException,
--   createRootErrorUpdate,
--   createClassErrorUpdate,
-- } = require(script.Parent.ReactFiberThrow.new)
-- local {
--   commitBeforeMutationEffects,
--   commitMutationEffects,
--   commitLayoutEffects,
--   commitPassiveMountEffects,
--   commitPassiveUnmountEffects,
--   commitDoubleInvokeEffectsInDEV,
-- } = require(script.Parent.ReactFiberCommitWork.new)
-- local {enqueueUpdate} = require(script.Parent.ReactUpdateQueue.new)
-- local {resetContextDependencies} = require(script.Parent.ReactFiberNewContext.new)
-- local {
--   resetHooksAfterThrow,
--   ContextOnlyDispatcher,
--   getIsUpdatingOpaqueValueInRenderPhaseInDEV,
-- } = require(script.Parent.ReactFiberHooks.new)
-- local {createCapturedValue} = require(script.Parent.ReactCapturedValue)
-- local pushToStack = ReactFiberStack.push
-- local popFromStack = ReactFiberStack.pop
-- local createCursor = ReactFiberStack.createCursor

-- local {
--   recordCommitTime,
--   startProfilerTimer,
--   stopProfilerTimerIfRunningAndRecordDelta,
-- } = require(script.Parent.ReactProfilerTimer.new)

-- -- DEV stuff
-- local getComponentName = require(Workspace.Shared.getComponentName)
-- local ReactStrictModeWarnings = require(script.Parent.ReactStrictModeWarnings.new)
-- local ReactCurrentFiber = require(script.Parent.ReactCurrentFiber)
-- local ReactCurrentDebugFiberIsRenderingInDEV = ReactCurrentFiber.isRendering
-- local ReactCurrentFiberCurrent = ReactCurrentFiber.current
-- local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
-- local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
-- local {
--   invokeGuardedCallback,
--   hasCaughtError,
--   clearCaughtError,
-- } = require(Workspace.Shared.ReactErrorUtils)
-- local {onCommitRoot as onCommitRootDevTools} = require(script.Parent.ReactFiberDevToolsHook.new)
-- local {onCommitRoot as onCommitRootTestSelector} = require(script.Parent.ReactTestSelectors)

-- -- Used by `act`
-- local enqueueTask = require(Workspace.Shared.enqueueTask)

-- deviation: Common types
type Set<T> = { [T]: boolean };

local exports = {}

-- local ceil = math.ceil

-- deviation: Pre-declare functions
local checkForNestedUpdates, warnAboutRenderPhaseUpdatesInDEV

-- local {
--   ReactCurrentDispatcher,
--   ReactCurrentOwner,
--   IsSomeRendererActing,
-- } = ReactSharedInternals

type ExecutionContext = number;

local NoContext = --[[                    ]] 0b0000000
-- local BatchedContext = --[[               ]] 0b0000001
-- local EventContext = --[[                 ]] 0b0000010
local DiscreteEventContext = --[[         ]] 0b0000100
-- local LegacyUnbatchedContext = --[[       ]] 0b0001000
local RenderContext = --[[                ]] 0b0010000
local CommitContext = --[[                ]] 0b0100000
local RetryAfterError = --[[              ]] 0b1000000

exports.NoContext = NoContext
exports.RetryAfterError = RetryAfterError

-- deviation: Luau doesn't yet support literal types
-- type RootExitStatus = 0 | 1 | 2 | 3 | 4 | 5
type RootExitStatus = number;
-- local RootIncomplete = 0
-- local RootFatalErrored = 1
-- local RootErrored = 2
-- local RootSuspended = 3
-- local RootSuspendedWithDelay = 4
-- local RootCompleted = 5

-- Describes where we are in the React execution stack
local executionContext: ExecutionContext = NoContext
-- -- The root we're working on
-- local workInProgressRoot: FiberRoot? = nil
-- -- The fiber we're working on
-- local workInProgress: Fiber? = nil
-- The lanes we're rendering
local workInProgressRootRenderLanes: Lanes = NoLanes

-- Stack that allows components to change the render lanes for its subtree
-- This is a superset of the lanes we started working on at the root. The only
-- case where it's different from `workInProgressRootRenderLanes` is when we
-- enter a subtree that is hidden and needs to be unhidden: Suspense and
-- Offscreen component.
--
-- Most things in the work loop should deal with workInProgressRootRenderLanes.
-- Most things in begin/complete phases should deal with subtreeRenderLanes.
exports.subtreeRenderLanes = NoLanes
-- local subtreeRenderLanesCursor: StackCursor<Lanes> = createCursor(NoLanes)

-- -- Whether to root completed, errored, suspended, etc.
-- local workInProgressRootExitStatus: RootExitStatus = RootIncomplete
-- -- A fatal error, if one is thrown
-- local workInProgressRootFatalError: any = nil
-- "Included" lanes refer to lanes that were worked on during this render. It's
-- slightly different than `renderLanes` because `renderLanes` can change as you
-- enter and exit an Offscreen tree. This value is the combination of all render
-- lanes for the entire render phase.
local workInProgressRootIncludedLanes: Lanes = NoLanes
-- -- The work left over by components that were visited during this render. Only
-- -- includes unprocessed updates, not work in bailed out children.
-- local workInProgressRootSkippedLanes: Lanes = NoLanes
-- -- Lanes that were updated (in an interleaved event) during this render.
-- local workInProgressRootUpdatedLanes: Lanes = NoLanes
-- -- Lanes that were pinged (in an interleaved event) during this render.
-- local workInProgressRootPingedLanes: Lanes = NoLanes

local mostRecentlyUpdatedRoot: FiberRoot | nil = nil

-- -- The most recent time we committed a fallback. This lets us ensure a train
-- -- model where we don't commit new loading states in too quick succession.
-- local globalMostRecentFallbackTime: number = 0
-- local FALLBACK_THROTTLE_MS: number = 500

-- -- The absolute time for when we should start giving up on rendering
-- -- more and prefer CPU suspense heuristics instead.
-- local workInProgressRootRenderTargetTime: number = math.huge
-- -- How long a render is supposed to take before we start following CPU
-- -- suspense heuristics and opt out of rendering more content.
-- local RENDER_TIMEOUT_MS = 500

-- function resetRenderTimer()
--   workInProgressRootRenderTargetTime = now() + RENDER_TIMEOUT_MS
-- end

-- exports.getRenderTargetTime(): number {
--   return workInProgressRootRenderTargetTime
-- end

-- local hasUncaughtError = false
-- local firstUncaughtError = nil
-- local legacyErrorBoundariesThatAlreadyFailed: Set<mixed> | nil = nil

-- local rootWithPendingPassiveEffects: FiberRoot | nil = nil
-- local pendingPassiveEffectsRenderPriority: ReactPriorityLevel = NoSchedulerPriority
-- local pendingPassiveEffectsLanes: Lanes = NoLanes

-- local rootsWithPendingDiscreteUpdates: Set<FiberRoot> | nil = nil

-- -- Use these to prevent an infinite loop of nested updates
local NESTED_UPDATE_LIMIT = 50
local nestedUpdateCount: number = 0
-- local rootWithNestedUpdates: FiberRoot | nil = nil

local NESTED_PASSIVE_UPDATE_LIMIT = 50
local nestedPassiveUpdateCount: number = 0

-- -- Marks the need to reschedule pending interactions at these lanes
-- -- during the commit phase. This enables them to be traced across components
-- -- that spawn new work during render. E.g. hidden boundaries, suspended SSR
-- -- hydration or SuspenseList.
-- -- TODO: Can use a bitmask instead of an array
-- local spawnedWorkDuringRender: nil | Array<Lane | Lanes> = nil

-- -- If two updates are scheduled within the same event, we should treat their
-- -- event times as simultaneous, even if the actual clock time has advanced
-- -- between the first and second call.
local currentEventTime: number = NoTimestamp
local currentEventWipLanes: Lanes = NoLanes
local currentEventPendingLanes: Lanes = NoLanes

-- -- Dev only flag that tracks if passive effects are currently being flushed.
-- -- We warn about state updates for unmounted components differently in this case.
-- local isFlushingPassiveEffects = false

-- exports.getWorkInProgressRoot(): FiberRoot | nil {
--   return workInProgressRoot
-- end

exports.requestEventTime = function()
  if bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) ~= NoContext then
    -- We're inside React, so it's fine to read the actual time.
    return now()
  end
  -- We're not inside React, so we may be in the middle of a browser event.
  if currentEventTime ~= NoTimestamp then
    -- Use the same start time for all updates until we enter React again.
    return currentEventTime
  end
  -- This is the first update since React yielded. Compute a new start time.
  currentEventTime = now()
  return currentEventTime
end

-- exports.getCurrentTime()
--   return now()
-- end

exports.requestUpdateLane = function(fiber: Fiber): Lane
  -- Special cases
  local mode = fiber.mode
  if bit32.band(mode, BlockingMode) == NoMode then
    return SyncLane
  elseif bit32.band(mode, ConcurrentMode) == NoMode then
    return getCurrentPriorityLevel() == ImmediateSchedulerPriority
      and SyncLane
      or SyncBatchedLane
  elseif 
    not deferRenderPhaseUpdateToNextBatch and
    bit32.band(executionContext, RenderContext) ~= NoContext and
    workInProgressRootRenderLanes ~= NoLanes
  then
    -- This is a render phase update. These are not officially supported. The
    -- old behavior is to give this the same "thread" (expiration time) as
    -- whatever is currently rendering. So if you call `setState` on a component
    -- that happens later in the same render, it will flush. Ideally, we want to
    -- remove the special case and treat them as if they came from an
    -- interleaved event. Regardless, this pattern is not officially supported.
    -- This behavior is only a fallback. The flag only exists until we can roll
    -- out the setState warning, since existing code might accidentally rely on
    -- the current behavior.
    return pickArbitraryLane(workInProgressRootRenderLanes)
  end

  -- The algorithm for assigning an update to a lane should be stable for all
  -- updates at the same priority within the same event. To do this, the inputs
  -- to the algorithm must be the same. For example, we use the `renderLanes`
  -- to avoid choosing a lane that is already in the middle of rendering.
  --
  -- However, the "included" lanes could be mutated in between updates in the
  -- same event, like if you perform an update inside `flushSync`. Or any other
  -- code path that might call `prepareFreshStack`.
  --
  -- The trick we use is to cache the first of each of these inputs within an
  -- event. Then reset the cached values once we can be sure the event is over.
  -- Our heuristic for that is whenever we enter a concurrent work loop.
  --
  -- We'll do the same for `currentEventPendingLanes` below.
  if currentEventWipLanes == NoLanes then
    currentEventWipLanes = workInProgressRootIncludedLanes
  end

  local isTransition = requestCurrentTransition() ~= NoTransition
  if isTransition then
    if currentEventPendingLanes ~= NoLanes then
      if mostRecentlyUpdatedRoot then
        currentEventPendingLanes = mostRecentlyUpdatedRoot.pendingLanes
      else
        currentEventPendingLanes = NoLanes
      end
    end
    return findTransitionLane(currentEventWipLanes, currentEventPendingLanes)
  end

  -- TODO: Remove this dependency on the Scheduler priority.
  -- To do that, we're replacing it with an update lane priority.
  local schedulerPriority = getCurrentPriorityLevel()

  -- The old behavior was using the priority level of the Scheduler.
  -- This couples React to the Scheduler internals, so we're replacing it
  -- with the currentUpdateLanePriority above. As an example of how this
  -- could be problematic, if we're not inside `Scheduler.runWithPriority`,
  -- then we'll get the priority of the current running Scheduler task,
  -- which is probably not what we want.
  local lane
  if
    -- TODO: Temporary. We're removing the concept of discrete updates.
    bit32.band(executionContext, DiscreteEventContext) ~= NoContext and
    schedulerPriority == UserBlockingSchedulerPriority
  then
    lane = findUpdateLane(InputDiscreteLanePriority, currentEventWipLanes)
  else
    local schedulerLanePriority = schedulerPriorityToLanePriority(
      schedulerPriority
    )

    if decoupleUpdatePriorityFromScheduler then
      -- In the new strategy, we will track the current update lane priority
      -- inside React and use that priority to select a lane for this update.
      -- For now, we're just logging when they're different so we can assess.
      local currentUpdateLanePriority = getCurrentUpdateLanePriority()

      if
        schedulerLanePriority ~= currentUpdateLanePriority and
        currentUpdateLanePriority ~= NoLanePriority
      then
        if _G.__DEV__ then
          console.error(
            "Expected current scheduler lane priority %s to match current update lane priority %s",
            schedulerLanePriority,
            currentUpdateLanePriority
          )
        end
      end
    end

    lane = findUpdateLane(schedulerLanePriority, currentEventWipLanes)
  end

  return lane
end

-- function requestRetryLane(fiber: Fiber)
--   -- This is a fork of `requestUpdateLane` designed specifically for Suspense
--   -- "retries" — a special update that attempts to flip a Suspense boundary
--   -- from its placeholder state to its primary/resolved state.

--   -- Special cases
--   local mode = fiber.mode
--   if (mode & BlockingMode) == NoMode)
--     return (SyncLane: Lane)
--   } else if (mode & ConcurrentMode) == NoMode)
--     return getCurrentPriorityLevel() == ImmediateSchedulerPriority
--       ? (SyncLane: Lane)
--       : (SyncBatchedLane: Lane)
--   end

--   -- See `requestUpdateLane` for explanation of `currentEventWipLanes`
--   if currentEventWipLanes == NoLanes)
--     currentEventWipLanes = workInProgressRootIncludedLanes
--   end
--   return findRetryLane(currentEventWipLanes)
-- end

exports.scheduleUpdateOnFiber = function(
  fiber: Fiber,
  lane: Lane,
  eventTime: number
)
  checkForNestedUpdates()
  warnAboutRenderPhaseUpdatesInDEV(fiber)

  -- FIXME: WIP
  -- local root = markUpdateLaneFromFiberToRoot(fiber, lane)
  -- if root == nil then
  --   warnAboutUpdateOnUnmountedFiberInDEV(fiber)
  --   return
  -- end

  -- -- Mark that the root has a pending update.
  -- markRootUpdated(root, lane, eventTime)

  -- if root == workInProgressRoot then
  --   -- Received an update to a tree that's in the middle of rendering. Mark
  --   -- that there was an interleaved update work on this root. Unless the
  --   -- `deferRenderPhaseUpdateToNextBatch` flag is off and this is a render
  --   -- phase update. In that case, we don't treat render phase updates as if
  --   -- they were interleaved, for backwards compat reasons.
  --   if
  --     deferRenderPhaseUpdateToNextBatch or
  --     bit32.band(executionContext, RenderContext) == NoContext
  --   then
  --     workInProgressRootUpdatedLanes = mergeLanes(
  --       workInProgressRootUpdatedLanes,
  --       lane
  --     )
  --   end
  --   if workInProgressRootExitStatus == RootSuspendedWithDelay then
  --     -- The root already suspended with a delay, which means this render
  --     -- definitely won't finish. Since we have a new update, let's mark it as
  --     -- suspended now, right before marking the incoming update. This has the
  --     -- effect of interrupting the current render and switching to the update.
  --     -- TODO: Make sure this doesn't override pings that happen while we've
  --     -- already started rendering.
  --     markRootSuspended(root, workInProgressRootRenderLanes)
  --   end
  -- end

  -- -- TODO: requestUpdateLanePriority also reads the priority. Pass the
  -- -- priority as an argument to that function and this one.
  -- local priorityLevel = getCurrentPriorityLevel()

  -- if lane == SyncLane then
  --   if
  --     -- Check if we're inside unbatchedUpdates
  --     bit32.band(executionContext, LegacyUnbatchedContext) ~= NoContext and
  --     -- Check if we're not already rendering
  --     bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext
  --   then
  --     -- Register pending interactions on the root to avoid losing traced interaction data.
  --     schedulePendingInteractions(root, lane)

  --     -- This is a legacy edge case. The initial mount of a ReactDOM.render-ed
  --     -- root inside of batchedUpdates should be synchronous, but layout updates
  --     -- should be deferred until the end of the batch.
  --     performSyncWorkOnRoot(root)
  --   else
  --     ensureRootIsScheduled(root, eventTime)
  --     schedulePendingInteractions(root, lane)
  --     if executionContext == NoContext then
  --       -- Flush the synchronous work now, unless we're already working or inside
  --       -- a batch. This is intentionally inside scheduleUpdateOnFiber instead of
  --       -- scheduleCallbackForFiber to preserve the ability to schedule a callback
  --       -- without immediately flushing it. We only do this for user-initiated
  --       -- updates, to preserve historical behavior of legacy mode.
  --       resetRenderTimer()
  --       flushSyncCallbackQueue()
  --     end
  --   end
  -- else
  --   -- Schedule a discrete update but only if it's not Sync.
  --   if
  --     bit32.band(executionContext, DiscreteEventContext) ~= NoContext and
  --     -- Only updates at user-blocking priority or greater are considered
  --     -- discrete, even inside a discrete event.
  --     (priorityLevel == UserBlockingSchedulerPriority or
  --       priorityLevel == ImmediateSchedulerPriority)
  --   then
  --     -- This is the result of a discrete event. Track the lowest priority
  --     -- discrete update per root so we can flush them early, if needed.
  --     if rootsWithPendingDiscreteUpdates == nil then
  --       rootsWithPendingDiscreteUpdates = { root = true }
  --     else
  --       rootsWithPendingDiscreteUpdates.add(root)
  --     end
  --   end
  --   -- Schedule other updates after in case the callback is sync.
  --   ensureRootIsScheduled(root, eventTime)
  --   schedulePendingInteractions(root, lane)
  -- end

  -- -- We use this when assigning a lane for a transition inside
  -- -- `requestUpdateLane`. We assume it's the same as the root being updated,
  -- -- since in the common case of a single root app it probably is. If it's not
  -- -- the same root, then it's not a huge deal, we just might batch more stuff
  -- -- together more than necessary.
  -- mostRecentlyUpdatedRoot = root
end

-- -- This is split into a separate function so we can mark a fiber with pending
-- -- work without treating it as a typical update that originates from an event
-- -- e.g. retrying a Suspense boundary isn't an update, but it does schedule work
-- -- on a fiber.
-- function markUpdateLaneFromFiberToRoot(
--   sourceFiber: Fiber,
--   lane: Lane,
-- ): FiberRoot | nil {
--   -- Update the source fiber's lanes
--   sourceFiber.lanes = mergeLanes(sourceFiber.lanes, lane)
--   local alternate = sourceFiber.alternate
--   if alternate ~= nil)
--     alternate.lanes = mergeLanes(alternate.lanes, lane)
--   end
--   if _G.__DEV__)
--     if 
--       alternate == nil and
--       (sourceFiber.flags & (Placement | Hydrating)) ~= NoFlags
--     )
--       warnAboutUpdateOnNotYetMountedFiberInDEV(sourceFiber)
--     end
--   end
--   -- Walk the parent path to the root and update the child expiration time.
--   local node = sourceFiber
--   local parent = sourceFiber.return
--   while (parent ~= nil)
--     parent.childLanes = mergeLanes(parent.childLanes, lane)
--     alternate = parent.alternate
--     if alternate ~= nil)
--       alternate.childLanes = mergeLanes(alternate.childLanes, lane)
--     } else {
--       if _G.__DEV__)
--         if (parent.flags & (Placement | Hydrating)) ~= NoFlags)
--           warnAboutUpdateOnNotYetMountedFiberInDEV(sourceFiber)
--         end
--       end
--     end
--     node = parent
--     parent = parent.return
--   end
--   if node.tag == HostRoot)
--     local root: FiberRoot = node.stateNode
--     return root
--   } else {
--     return nil
--   end
-- end

-- -- Use this function to schedule a task for a root. There's only one task per
-- -- root; if a task was already scheduled, we'll check to make sure the priority
-- -- of the existing task is the same as the priority of the next level that the
-- -- root has work on. This function is called on every update, and right before
-- -- exiting a task.
-- function ensureRootIsScheduled(root: FiberRoot, currentTime: number)
--   local existingCallbackNode = root.callbackNode

--   -- Check if any lanes are being starved by other work. If so, mark them as
--   -- expired so we know to work on those next.
--   markStarvedLanesAsExpired(root, currentTime)

--   -- Determine the next lanes to work on, and their priority.
--   local nextLanes = getNextLanes(
--     root,
--     root == workInProgressRoot ? workInProgressRootRenderLanes : NoLanes,
--   )
--   -- This returns the priority level computed during the `getNextLanes` call.
--   local newCallbackPriority = returnNextLanesPriority()

--   if nextLanes == NoLanes)
--     -- Special case: There's nothing to work on.
--     if existingCallbackNode ~= nil)
--       cancelCallback(existingCallbackNode)
--       root.callbackNode = nil
--       root.callbackPriority = NoLanePriority
--     end
--     return
--   end

--   -- Check if there's an existing task. We may be able to reuse it.
--   if existingCallbackNode ~= nil)
--     local existingCallbackPriority = root.callbackPriority
--     if existingCallbackPriority == newCallbackPriority)
--       -- The priority hasn't changed. We can reuse the existing task. Exit.
--       return
--     end
--     -- The priority changed. Cancel the existing callback. We'll schedule a new
--     -- one below.
--     cancelCallback(existingCallbackNode)
--   end

--   -- Schedule a new callback.
--   local newCallbackNode
--   if newCallbackPriority == SyncLanePriority)
--     -- Special case: Sync React callbacks are scheduled on a special
--     -- internal queue
--     newCallbackNode = scheduleSyncCallback(
--       performSyncWorkOnRoot.bind(null, root),
--     )
--   } else if newCallbackPriority == SyncBatchedLanePriority)
--     newCallbackNode = scheduleCallback(
--       ImmediateSchedulerPriority,
--       performSyncWorkOnRoot.bind(null, root),
--     )
--   } else {
--     local schedulerPriorityLevel = lanePriorityToSchedulerPriority(
--       newCallbackPriority,
--     )
--     newCallbackNode = scheduleCallback(
--       schedulerPriorityLevel,
--       performConcurrentWorkOnRoot.bind(null, root),
--     )
--   end

--   root.callbackPriority = newCallbackPriority
--   root.callbackNode = newCallbackNode
-- end

-- -- This is the entry point for every concurrent task, i.e. anything that
-- -- goes through Scheduler.
-- function performConcurrentWorkOnRoot(root)
--   -- Since we know we're in a React event, we can clear the current
--   -- event time. The next update will compute a new event time.
--   currentEventTime = NoTimestamp
--   currentEventWipLanes = NoLanes
--   currentEventPendingLanes = NoLanes

--   invariant(
--     (executionContext & (RenderContext | CommitContext)) == NoContext,
--     'Should not already be working.',
--   )

--   -- Flush any pending passive effects before deciding which lanes to work on,
--   -- in case they schedule additional work.
--   local originalCallbackNode = root.callbackNode
--   local didFlushPassiveEffects = flushPassiveEffects()
--   if didFlushPassiveEffects)
--     -- Something in the passive effect phase may have canceled the current task.
--     -- Check if the task node for this root was changed.
--     if root.callbackNode ~= originalCallbackNode)
--       -- The current task was canceled. Exit. We don't need to call
--       -- `ensureRootIsScheduled` because the check above implies either that
--       -- there's a new task, or that there's no remaining work on this root.
--       return nil
--     } else {
--       -- Current task was not canceled. Continue.
--     end
--   end

--   -- Determine the next expiration time to work on, using the fields stored
--   -- on the root.
--   local lanes = getNextLanes(
--     root,
--     root == workInProgressRoot ? workInProgressRootRenderLanes : NoLanes,
--   )
--   if lanes == NoLanes)
--     -- Defensive coding. This is never expected to happen.
--     return nil
--   end

--   local exitStatus = renderRootConcurrent(root, lanes)

--   if 
--     includesSomeLane(
--       workInProgressRootIncludedLanes,
--       workInProgressRootUpdatedLanes,
--     )
--   )
--     -- The render included lanes that were updated during the render phase.
--     -- For example, when unhiding a hidden tree, we include all the lanes
--     -- that were previously skipped when the tree was hidden. That set of
--     -- lanes is a superset of the lanes we started rendering with.
--     --
--     -- So we'll throw out the current work and restart.
--     prepareFreshStack(root, NoLanes)
--   } else if exitStatus ~= RootIncomplete)
--     if exitStatus == RootErrored)
--       executionContext |= RetryAfterError

--       -- If an error occurred during hydration,
--       -- discard server response and fall back to client side render.
--       if root.hydrate)
--         root.hydrate = false
--         clearContainer(root.containerInfo)
--       end

--       -- If something threw an error, try rendering one more time. We'll render
--       -- synchronously to block concurrent data mutations, and we'll includes
--       -- all pending updates are included. If it still fails after the second
--       -- attempt, we'll give up and commit the resulting tree.
--       lanes = getLanesToRetrySynchronouslyOnError(root)
--       if lanes ~= NoLanes)
--         exitStatus = renderRootSync(root, lanes)
--       end
--     end

--     if exitStatus == RootFatalErrored)
--       local fatalError = workInProgressRootFatalError
--       prepareFreshStack(root, NoLanes)
--       markRootSuspended(root, lanes)
--       ensureRootIsScheduled(root, now())
--       throw fatalError
--     end

--     -- We now have a consistent tree. The next step is either to commit it,
--     -- or, if something suspended, wait to commit it after a timeout.
--     local finishedWork: Fiber = (root.current.alternate: any)
--     root.finishedWork = finishedWork
--     root.finishedLanes = lanes
--     finishConcurrentRender(root, exitStatus, lanes)
--   end

--   ensureRootIsScheduled(root, now())
--   if root.callbackNode == originalCallbackNode)
--     -- The task node scheduled for this root is the same one that's
--     -- currently executed. Need to return a continuation.
--     return performConcurrentWorkOnRoot.bind(null, root)
--   end
--   return nil
-- end

-- function finishConcurrentRender(root, exitStatus, lanes)
--   switch (exitStatus)
--     case RootIncomplete:
--     case RootFatalErrored: {
--       invariant(false, 'Root did not complete. This is a bug in React.')
--     end
--     -- Flow knows about invariant, so it complains if I add a break
--     -- statement, but eslint doesn't know about invariant, so it complains
--     -- if I do. eslint-disable-next-line no-fallthrough
--     case RootErrored: {
--       -- We should have already attempted to retry this tree. If we reached
--       -- this point, it errored again. Commit it.
--       commitRoot(root)
--       break
--     end
--     case RootSuspended: {
--       markRootSuspended(root, lanes)

--       -- We have an acceptable loading state. We need to figure out if we
--       -- should immediately commit it or wait a bit.

--       if 
--         includesOnlyRetries(lanes) and
--         -- do not delay if we're inside an act() scope
--         !shouldForceFlushFallbacksInDEV()
--       )
--         -- This render only included retries, no updates. Throttle committing
--         -- retries so that we don't show too many loading states too quickly.
--         local msUntilTimeout =
--           globalMostRecentFallbackTime + FALLBACK_THROTTLE_MS - now()
--         -- Don't bother with a very short suspense time.
--         if msUntilTimeout > 10)
--           local nextLanes = getNextLanes(root, NoLanes)
--           if nextLanes ~= NoLanes)
--             -- There's additional work on this root.
--             break
--           end
--           local suspendedLanes = root.suspendedLanes
--           if !isSubsetOfLanes(suspendedLanes, lanes))
--             -- We should prefer to render the fallback of at the last
--             -- suspended level. Ping the last suspended level to try
--             -- rendering it again.
--             -- FIXME: What if the suspended lanes are Idle? Should not restart.
--             local eventTime = requestEventTime()
--             markRootPinged(root, suspendedLanes, eventTime)
--             break
--           end

--           -- The render is suspended, it hasn't timed out, and there's no
--           -- lower priority work to do. Instead of committing the fallback
--           -- immediately, wait for more data to arrive.
--           root.timeoutHandle = scheduleTimeout(
--             commitRoot.bind(null, root),
--             msUntilTimeout,
--           )
--           break
--         end
--       end
--       -- The work expired. Commit immediately.
--       commitRoot(root)
--       break
--     end
--     case RootSuspendedWithDelay: {
--       markRootSuspended(root, lanes)

--       if includesOnlyTransitions(lanes))
--         -- This is a transition, so we should exit without committing a
--         -- placeholder and without scheduling a timeout. Delay indefinitely
--         -- until we receive more data.
--         break
--       end

--       if !shouldForceFlushFallbacksInDEV())
--         -- This is not a transition, but we did trigger an avoided state.
--         -- Schedule a placeholder to display after a short delay, using the Just
--         -- Noticeable Difference.
--         -- TODO: Is the JND optimization worth the added complexity? If this is
--         -- the only reason we track the event time, then probably not.
--         -- Consider removing.

--         local mostRecentEventTime = getMostRecentEventTime(root, lanes)
--         local eventTimeMs = mostRecentEventTime
--         local timeElapsedMs = now() - eventTimeMs
--         local msUntilTimeout = jnd(timeElapsedMs) - timeElapsedMs

--         -- Don't bother with a very short suspense time.
--         if msUntilTimeout > 10)
--           -- Instead of committing the fallback immediately, wait for more data
--           -- to arrive.
--           root.timeoutHandle = scheduleTimeout(
--             commitRoot.bind(null, root),
--             msUntilTimeout,
--           )
--           break
--         end
--       end

--       -- Commit the placeholder.
--       commitRoot(root)
--       break
--     end
--     case RootCompleted: {
--       -- The work completed. Ready to commit.
--       commitRoot(root)
--       break
--     end
--     default: {
--       invariant(false, 'Unknown root exit status.')
--     end
--   end
-- end

-- function markRootSuspended(root, suspendedLanes)
--   -- When suspending, we should always exclude lanes that were pinged or (more
--   -- rarely, since we try to avoid it) updated during the render phase.
--   -- TODO: Lol maybe there's a better way to factor this besides this
--   -- obnoxiously named function :)
--   suspendedLanes = removeLanes(suspendedLanes, workInProgressRootPingedLanes)
--   suspendedLanes = removeLanes(suspendedLanes, workInProgressRootUpdatedLanes)
--   markRootSuspended_dontCallThisOneDirectly(root, suspendedLanes)
-- end

-- -- This is the entry point for synchronous tasks that don't go
-- -- through Scheduler
-- function performSyncWorkOnRoot(root)
--   invariant(
--     (executionContext & (RenderContext | CommitContext)) == NoContext,
--     'Should not already be working.',
--   )

--   flushPassiveEffects()

--   local lanes
--   local exitStatus
--   if 
--     root == workInProgressRoot and
--     includesSomeLane(root.expiredLanes, workInProgressRootRenderLanes)
--   )
--     -- There's a partial tree, and at least one of its lanes has expired. Finish
--     -- rendering it before rendering the rest of the expired work.
--     lanes = workInProgressRootRenderLanes
--     exitStatus = renderRootSync(root, lanes)
--     if 
--       includesSomeLane(
--         workInProgressRootIncludedLanes,
--         workInProgressRootUpdatedLanes,
--       )
--     )
--       -- The render included lanes that were updated during the render phase.
--       -- For example, when unhiding a hidden tree, we include all the lanes
--       -- that were previously skipped when the tree was hidden. That set of
--       -- lanes is a superset of the lanes we started rendering with.
--       --
--       -- Note that this only happens when part of the tree is rendered
--       -- concurrently. If the whole tree is rendered synchronously, then there
--       -- are no interleaved events.
--       lanes = getNextLanes(root, lanes)
--       exitStatus = renderRootSync(root, lanes)
--     end
--   } else {
--     lanes = getNextLanes(root, NoLanes)
--     exitStatus = renderRootSync(root, lanes)
--   end

--   if root.tag ~= LegacyRoot and exitStatus == RootErrored)
--     executionContext |= RetryAfterError

--     -- If an error occurred during hydration,
--     -- discard server response and fall back to client side render.
--     if root.hydrate)
--       root.hydrate = false
--       clearContainer(root.containerInfo)
--     end

--     -- If something threw an error, try rendering one more time. We'll render
--     -- synchronously to block concurrent data mutations, and we'll includes
--     -- all pending updates are included. If it still fails after the second
--     -- attempt, we'll give up and commit the resulting tree.
--     lanes = getLanesToRetrySynchronouslyOnError(root)
--     if lanes ~= NoLanes)
--       exitStatus = renderRootSync(root, lanes)
--     end
--   end

--   if exitStatus == RootFatalErrored)
--     local fatalError = workInProgressRootFatalError
--     prepareFreshStack(root, NoLanes)
--     markRootSuspended(root, lanes)
--     ensureRootIsScheduled(root, now())
--     throw fatalError
--   end

--   -- We now have a consistent tree. Because this is a sync render, we
--   -- will commit it even if something suspended.
--   local finishedWork: Fiber = (root.current.alternate: any)
--   root.finishedWork = finishedWork
--   root.finishedLanes = lanes
--   commitRoot(root)

--   -- Before exiting, make sure there's a callback scheduled for the next
--   -- pending level.
--   ensureRootIsScheduled(root, now())

--   return nil
-- end

-- exports.flushRoot(root: FiberRoot, lanes: Lanes)
--   markRootExpired(root, lanes)
--   ensureRootIsScheduled(root, now())
--   if (executionContext & (RenderContext | CommitContext)) == NoContext)
--     resetRenderTimer()
--     flushSyncCallbackQueue()
--   end
-- end

-- exports.getExecutionContext(): ExecutionContext {
--   return executionContext
-- end

-- exports.flushDiscreteUpdates()
--   -- TODO: Should be able to flush inside batchedUpdates, but not inside `act`.
--   -- However, `act` uses `batchedUpdates`, so there's no way to distinguish
--   -- those two cases. Need to fix this before exposing flushDiscreteUpdates
--   -- as a public API.
--   if 
--     (executionContext & (BatchedContext | RenderContext | CommitContext)) ~=
--     NoContext
--   )
--     if _G.__DEV__)
--       if (executionContext & RenderContext) ~= NoContext)
--         console.error(
--           'unstable_flushDiscreteUpdates: Cannot flush updates when React is ' +
--             'already rendering.',
--         )
--       end
--     end
--     -- We're already rendering, so we can't synchronously flush pending work.
--     -- This is probably a nested event dispatch triggered by a lifecycle/effect,
--     -- like `el.focus()`. Exit.
--     return
--   end
--   flushPendingDiscreteUpdates()
--   -- If the discrete updates scheduled passive effects, flush them now so that
--   -- they fire before the next serial event.
--   flushPassiveEffects()
-- end

-- exports.deferredUpdates<A>(fn: () => A): A {
--   if decoupleUpdatePriorityFromScheduler)
--     local previousLanePriority = getCurrentUpdateLanePriority()
--     try {
--       setCurrentUpdateLanePriority(DefaultLanePriority)
--       return runWithPriority(NormalSchedulerPriority, fn)
--     } finally {
--       setCurrentUpdateLanePriority(previousLanePriority)
--     end
--   } else {
--     return runWithPriority(NormalSchedulerPriority, fn)
--   end
-- end

-- function flushPendingDiscreteUpdates()
--   if rootsWithPendingDiscreteUpdates ~= nil)
--     -- For each root with pending discrete updates, schedule a callback to
--     -- immediately flush them.
--     local roots = rootsWithPendingDiscreteUpdates
--     rootsWithPendingDiscreteUpdates = nil
--     roots.forEach(root => {
--       markDiscreteUpdatesExpired(root)
--       ensureRootIsScheduled(root, now())
--     })
--   end
--   -- Now flush the immediate queue.
--   flushSyncCallbackQueue()
-- end

-- exports.batchedUpdates<A, R>(fn: A => R, a: A): R {
--   local prevExecutionContext = executionContext
--   executionContext |= BatchedContext
--   try {
--     return fn(a)
--   } finally {
--     executionContext = prevExecutionContext
--     if executionContext == NoContext)
--       -- Flush the immediate callbacks that were scheduled during this batch
--       resetRenderTimer()
--       flushSyncCallbackQueue()
--     end
--   end
-- end

-- exports.batchedEventUpdates<A, R>(fn: A => R, a: A): R {
--   local prevExecutionContext = executionContext
--   executionContext |= EventContext
--   try {
--     return fn(a)
--   } finally {
--     executionContext = prevExecutionContext
--     if executionContext == NoContext)
--       -- Flush the immediate callbacks that were scheduled during this batch
--       resetRenderTimer()
--       flushSyncCallbackQueue()
--     end
--   end
-- end

-- exports.discreteUpdates<A, B, C, D, R>(
--   fn: (A, B, C) => R,
--   a: A,
--   b: B,
--   c: C,
--   d: D,
-- ): R {
--   local prevExecutionContext = executionContext
--   executionContext |= DiscreteEventContext

--   if decoupleUpdatePriorityFromScheduler)
--     local previousLanePriority = getCurrentUpdateLanePriority()
--     try {
--       setCurrentUpdateLanePriority(InputDiscreteLanePriority)
--       return runWithPriority(
--         UserBlockingSchedulerPriority,
--         fn.bind(null, a, b, c, d),
--       )
--     } finally {
--       setCurrentUpdateLanePriority(previousLanePriority)
--       executionContext = prevExecutionContext
--       if executionContext == NoContext)
--         -- Flush the immediate callbacks that were scheduled during this batch
--         resetRenderTimer()
--         flushSyncCallbackQueue()
--       end
--     end
--   } else {
--     try {
--       return runWithPriority(
--         UserBlockingSchedulerPriority,
--         fn.bind(null, a, b, c, d),
--       )
--     } finally {
--       executionContext = prevExecutionContext
--       if executionContext == NoContext)
--         -- Flush the immediate callbacks that were scheduled during this batch
--         resetRenderTimer()
--         flushSyncCallbackQueue()
--       end
--     end
--   end
-- end

-- exports.unbatchedUpdates<A, R>(fn: (a: A) => R, a: A): R {
--   local prevExecutionContext = executionContext
--   executionContext &= ~BatchedContext
--   executionContext |= LegacyUnbatchedContext
--   try {
--     return fn(a)
--   } finally {
--     executionContext = prevExecutionContext
--     if executionContext == NoContext)
--       -- Flush the immediate callbacks that were scheduled during this batch
--       resetRenderTimer()
--       flushSyncCallbackQueue()
--     end
--   end
-- end

-- exports.flushSync<A, R>(fn: A => R, a: A): R {
--   local prevExecutionContext = executionContext
--   if (prevExecutionContext & (RenderContext | CommitContext)) ~= NoContext)
--     if _G.__DEV__)
--       console.error(
--         'flushSync was called from inside a lifecycle method. React cannot ' +
--           'flush when React is already rendering. Consider moving this call to ' +
--           'a scheduler task or micro task.',
--       )
--     end
--     return fn(a)
--   end
--   executionContext |= BatchedContext

--   if decoupleUpdatePriorityFromScheduler)
--     local previousLanePriority = getCurrentUpdateLanePriority()
--     try {
--       setCurrentUpdateLanePriority(SyncLanePriority)
--       if fn)
--         return runWithPriority(ImmediateSchedulerPriority, fn.bind(null, a))
--       } else {
--         return (undefined: $FlowFixMe)
--       end
--     } finally {
--       setCurrentUpdateLanePriority(previousLanePriority)
--       executionContext = prevExecutionContext
--       -- Flush the immediate callbacks that were scheduled during this batch.
--       -- Note that this will happen even if batchedUpdates is higher up
--       -- the stack.
--       flushSyncCallbackQueue()
--     end
--   } else {
--     try {
--       if fn)
--         return runWithPriority(ImmediateSchedulerPriority, fn.bind(null, a))
--       } else {
--         return (undefined: $FlowFixMe)
--       end
--     } finally {
--       executionContext = prevExecutionContext
--       -- Flush the immediate callbacks that were scheduled during this batch.
--       -- Note that this will happen even if batchedUpdates is higher up
--       -- the stack.
--       flushSyncCallbackQueue()
--     end
--   end
-- end

-- exports.flushControlled(fn: () => mixed): void {
--   local prevExecutionContext = executionContext
--   executionContext |= BatchedContext
--   if decoupleUpdatePriorityFromScheduler)
--     local previousLanePriority = getCurrentUpdateLanePriority()
--     try {
--       setCurrentUpdateLanePriority(SyncLanePriority)
--       runWithPriority(ImmediateSchedulerPriority, fn)
--     } finally {
--       setCurrentUpdateLanePriority(previousLanePriority)

--       executionContext = prevExecutionContext
--       if executionContext == NoContext)
--         -- Flush the immediate callbacks that were scheduled during this batch
--         resetRenderTimer()
--         flushSyncCallbackQueue()
--       end
--     end
--   } else {
--     try {
--       runWithPriority(ImmediateSchedulerPriority, fn)
--     } finally {
--       executionContext = prevExecutionContext
--       if executionContext == NoContext)
--         -- Flush the immediate callbacks that were scheduled during this batch
--         resetRenderTimer()
--         flushSyncCallbackQueue()
--       end
--     end
--   end
-- end

-- exports.pushRenderLanes(fiber: Fiber, lanes: Lanes)
--   pushToStack(subtreeRenderLanesCursor, subtreeRenderLanes, fiber)
--   subtreeRenderLanes = mergeLanes(subtreeRenderLanes, lanes)
--   workInProgressRootIncludedLanes = mergeLanes(
--     workInProgressRootIncludedLanes,
--     lanes,
--   )
-- end

-- exports.popRenderLanes(fiber: Fiber)
--   subtreeRenderLanes = subtreeRenderLanesCursor.current
--   popFromStack(subtreeRenderLanesCursor, fiber)
-- end

-- function prepareFreshStack(root: FiberRoot, lanes: Lanes)
--   root.finishedWork = nil
--   root.finishedLanes = NoLanes

--   local timeoutHandle = root.timeoutHandle
--   if timeoutHandle ~= noTimeout)
--     -- The root previous suspended and scheduled a timeout to commit a fallback
--     -- state. Now that we have additional work, cancel the timeout.
--     root.timeoutHandle = noTimeout
--     -- $FlowFixMe Complains noTimeout is not a TimeoutID, despite the check above
--     cancelTimeout(timeoutHandle)
--   end

--   if workInProgress ~= nil)
--     local interruptedWork = workInProgress.return
--     while (interruptedWork ~= nil)
--       unwindInterruptedWork(interruptedWork)
--       interruptedWork = interruptedWork.return
--     end
--   end
--   workInProgressRoot = root
--   workInProgress = createWorkInProgress(root.current, nil)
--   workInProgressRootRenderLanes = subtreeRenderLanes = workInProgressRootIncludedLanes = lanes
--   workInProgressRootExitStatus = RootIncomplete
--   workInProgressRootFatalError = nil
--   workInProgressRootSkippedLanes = NoLanes
--   workInProgressRootUpdatedLanes = NoLanes
--   workInProgressRootPingedLanes = NoLanes

--   if enableSchedulerTracing)
--     spawnedWorkDuringRender = nil
--   end

--   if _G.__DEV__)
--     ReactStrictModeWarnings.discardPendingWarnings()
--   end
-- end

-- function handleError(root, thrownValue): void {
--   do {
--     local erroredWork = workInProgress
--     try {
--       -- Reset module-level state that was set during the render phase.
--       resetContextDependencies()
--       resetHooksAfterThrow()
--       resetCurrentDebugFiberInDEV()
--       -- TODO: I found and added this missing line while investigating a
--       -- separate issue. Write a regression test using string refs.
--       ReactCurrentOwner.current = nil

--       if erroredWork == nil or erroredWork.return == nil)
--         -- Expected to be working on a non-root fiber. This is a fatal error
--         -- because there's no ancestor that can handle it; the root is
--         -- supposed to capture all errors that weren't caught by an error
--         -- boundary.
--         workInProgressRootExitStatus = RootFatalErrored
--         workInProgressRootFatalError = thrownValue
--         -- Set `workInProgress` to nil. This represents advancing to the next
--         -- sibling, or the parent if there are no siblings. But since the root
--         -- has no siblings nor a parent, we set it to nil. Usually this is
--         -- handled by `completeUnitOfWork` or `unwindWork`, but since we're
--         -- intentionally not calling those, we need set it here.
--         -- TODO: Consider calling `unwindWork` to pop the contexts.
--         workInProgress = nil
--         return
--       end

--       if enableProfilerTimer and erroredWork.mode & ProfileMode)
--         -- Record the time spent rendering before an error was thrown. This
--         -- avoids inaccurate Profiler durations in the case of a
--         -- suspended render.
--         stopProfilerTimerIfRunningAndRecordDelta(erroredWork, true)
--       end

--       throwException(
--         root,
--         erroredWork.return,
--         erroredWork,
--         thrownValue,
--         workInProgressRootRenderLanes,
--       )
--       completeUnitOfWork(erroredWork)
--     } catch (yetAnotherThrownValue)
--       -- Something in the return path also threw.
--       thrownValue = yetAnotherThrownValue
--       if workInProgress == erroredWork and erroredWork ~= nil)
--         -- If this boundary has already errored, then we had trouble processing
--         -- the error. Bubble it to the next boundary.
--         erroredWork = erroredWork.return
--         workInProgress = erroredWork
--       } else {
--         erroredWork = workInProgress
--       end
--       continue
--     end
--     -- Return to the normal work loop.
--     return
--   } while (true)
-- end

-- function pushDispatcher()
--   local prevDispatcher = ReactCurrentDispatcher.current
--   ReactCurrentDispatcher.current = ContextOnlyDispatcher
--   if prevDispatcher == nil)
--     -- The React isomorphic package does not include a default dispatcher.
--     -- Instead the first renderer will lazily attach one, in order to give
--     -- nicer error messages.
--     return ContextOnlyDispatcher
--   } else {
--     return prevDispatcher
--   end
-- end

-- function popDispatcher(prevDispatcher)
--   ReactCurrentDispatcher.current = prevDispatcher
-- end

-- function pushInteractions(root)
--   if enableSchedulerTracing)
--     local prevInteractions: Set<Interaction> | nil = __interactionsRef.current
--     __interactionsRef.current = root.memoizedInteractions
--     return prevInteractions
--   end
--   return nil
-- end

-- function popInteractions(prevInteractions)
--   if enableSchedulerTracing)
--     __interactionsRef.current = prevInteractions
--   end
-- end

-- exports.markCommitTimeOfFallback()
--   globalMostRecentFallbackTime = now()
-- end

-- exports.markSkippedUpdateLanes(lane: Lane | Lanes): void {
--   workInProgressRootSkippedLanes = mergeLanes(
--     lane,
--     workInProgressRootSkippedLanes,
--   )
-- end

-- exports.renderDidSuspend(): void {
--   if workInProgressRootExitStatus == RootIncomplete)
--     workInProgressRootExitStatus = RootSuspended
--   end
-- end

-- exports.renderDidSuspendDelayIfPossible(): void {
--   if 
--     workInProgressRootExitStatus == RootIncomplete or
--     workInProgressRootExitStatus == RootSuspended
--   )
--     workInProgressRootExitStatus = RootSuspendedWithDelay
--   end

--   -- Check if there are updates that we skipped tree that might have unblocked
--   -- this render.
--   if 
--     workInProgressRoot ~= nil and
--     (includesNonIdleWork(workInProgressRootSkippedLanes) or
--       includesNonIdleWork(workInProgressRootUpdatedLanes))
--   )
--     -- Mark the current render as suspended so that we switch to working on
--     -- the updates that were skipped. Usually we only suspend at the end of
--     -- the render phase.
--     -- TODO: We should probably always mark the root as suspended immediately
--     -- (inside this function), since by suspending at the end of the render
--     -- phase introduces a potential mistake where we suspend lanes that were
--     -- pinged or updated while we were rendering.
--     markRootSuspended(workInProgressRoot, workInProgressRootRenderLanes)
--   end
-- end

-- exports.renderDidError()
--   if workInProgressRootExitStatus ~= RootCompleted)
--     workInProgressRootExitStatus = RootErrored
--   end
-- end

-- -- Called during render to determine if anything has suspended.
-- -- Returns false if we're not sure.
-- exports.renderHasNotSuspendedYet(): boolean {
--   -- If something errored or completed, we can't really be sure,
--   -- so those are false.
--   return workInProgressRootExitStatus == RootIncomplete
-- end

-- function renderRootSync(root: FiberRoot, lanes: Lanes)
--   local prevExecutionContext = executionContext
--   executionContext |= RenderContext
--   local prevDispatcher = pushDispatcher()

--   -- If the root or lanes have changed, throw out the existing stack
--   -- and prepare a fresh one. Otherwise we'll continue where we left off.
--   if workInProgressRoot ~= root or workInProgressRootRenderLanes ~= lanes)
--     prepareFreshStack(root, lanes)
--     startWorkOnPendingInteractions(root, lanes)
--   end

--   local prevInteractions = pushInteractions(root)

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logRenderStarted(lanes)
--     end
--   end

--   if enableSchedulingProfiler)
--     markRenderStarted(lanes)
--   end

--   do {
--     try {
--       workLoopSync()
--       break
--     } catch (thrownValue)
--       handleError(root, thrownValue)
--     end
--   } while (true)
--   resetContextDependencies()
--   if enableSchedulerTracing)
--     popInteractions(((prevInteractions: any): Set<Interaction>))
--   end

--   executionContext = prevExecutionContext
--   popDispatcher(prevDispatcher)

--   if workInProgress ~= nil)
--     -- This is a sync render, so we should have finished the whole tree.
--     invariant(
--       false,
--       'Cannot commit an incomplete root. This error is likely caused by a ' +
--         'bug in React. Please file an issue.',
--     )
--   end

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logRenderStopped()
--     end
--   end

--   if enableSchedulingProfiler)
--     markRenderStopped()
--   end

--   -- Set this to nil to indicate there's no in-progress render.
--   workInProgressRoot = nil
--   workInProgressRootRenderLanes = NoLanes

--   return workInProgressRootExitStatus
-- end

-- -- The work loop is an extremely hot path. Tell Closure not to inline it.
-- --[[* @noinline ]]
-- function workLoopSync()
--   -- Already timed out, so perform work without checking if we need to yield.
--   while (workInProgress ~= nil)
--     performUnitOfWork(workInProgress)
--   end
-- end

-- function renderRootConcurrent(root: FiberRoot, lanes: Lanes)
--   local prevExecutionContext = executionContext
--   executionContext |= RenderContext
--   local prevDispatcher = pushDispatcher()

--   -- If the root or lanes have changed, throw out the existing stack
--   -- and prepare a fresh one. Otherwise we'll continue where we left off.
--   if workInProgressRoot ~= root or workInProgressRootRenderLanes ~= lanes)
--     resetRenderTimer()
--     prepareFreshStack(root, lanes)
--     startWorkOnPendingInteractions(root, lanes)
--   end

--   local prevInteractions = pushInteractions(root)

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logRenderStarted(lanes)
--     end
--   end

--   if enableSchedulingProfiler)
--     markRenderStarted(lanes)
--   end

--   do {
--     try {
--       workLoopConcurrent()
--       break
--     } catch (thrownValue)
--       handleError(root, thrownValue)
--     end
--   } while (true)
--   resetContextDependencies()
--   if enableSchedulerTracing)
--     popInteractions(((prevInteractions: any): Set<Interaction>))
--   end

--   popDispatcher(prevDispatcher)
--   executionContext = prevExecutionContext

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logRenderStopped()
--     end
--   end

--   -- Check if the tree has completed.
--   if workInProgress ~= nil)
--     -- Still work remaining.
--     if enableSchedulingProfiler)
--       markRenderYielded()
--     end
--     return RootIncomplete
--   } else {
--     -- Completed the tree.
--     if enableSchedulingProfiler)
--       markRenderStopped()
--     end

--     -- Set this to nil to indicate there's no in-progress render.
--     workInProgressRoot = nil
--     workInProgressRootRenderLanes = NoLanes

--     -- Return the final exit status.
--     return workInProgressRootExitStatus
--   end
-- end

-- --[[* @noinline ]]
-- function workLoopConcurrent()
--   -- Perform work until Scheduler asks us to yield
--   while (workInProgress ~= nil and !shouldYield())
--     performUnitOfWork(workInProgress)
--   end
-- end

-- function performUnitOfWork(unitOfWork: Fiber): void {
--   -- The current, flushed, state of this fiber is the alternate. Ideally
--   -- nothing should rely on this, but relying on it here means that we don't
--   -- need an additional field on the work in progress.
--   local current = unitOfWork.alternate
--   setCurrentDebugFiberInDEV(unitOfWork)

--   local next
--   if enableProfilerTimer and (unitOfWork.mode & ProfileMode) ~= NoMode)
--     startProfilerTimer(unitOfWork)
--     next = beginWork(current, unitOfWork, subtreeRenderLanes)
--     stopProfilerTimerIfRunningAndRecordDelta(unitOfWork, true)
--   } else {
--     next = beginWork(current, unitOfWork, subtreeRenderLanes)
--   end

--   resetCurrentDebugFiberInDEV()
--   unitOfWork.memoizedProps = unitOfWork.pendingProps
--   if next == nil)
--     -- If this doesn't spawn new work, complete the current work.
--     completeUnitOfWork(unitOfWork)
--   } else {
--     workInProgress = next
--   end

--   ReactCurrentOwner.current = nil
-- end

-- function completeUnitOfWork(unitOfWork: Fiber): void {
--   -- Attempt to complete the current unit of work, then move to the next
--   -- sibling. If there are no more siblings, return to the parent fiber.
--   local completedWork = unitOfWork
--   do {
--     -- The current, flushed, state of this fiber is the alternate. Ideally
--     -- nothing should rely on this, but relying on it here means that we don't
--     -- need an additional field on the work in progress.
--     local current = completedWork.alternate
--     local returnFiber = completedWork.return

--     -- Check if the work completed or if something threw.
--     if (completedWork.flags & Incomplete) == NoFlags)
--       setCurrentDebugFiberInDEV(completedWork)
--       local next
--       if 
--         !enableProfilerTimer or
--         (completedWork.mode & ProfileMode) == NoMode
--       )
--         next = completeWork(current, completedWork, subtreeRenderLanes)
--       } else {
--         startProfilerTimer(completedWork)
--         next = completeWork(current, completedWork, subtreeRenderLanes)
--         -- Update render duration assuming we didn't error.
--         stopProfilerTimerIfRunningAndRecordDelta(completedWork, false)
--       end
--       resetCurrentDebugFiberInDEV()

--       if next ~= nil)
--         -- Completing this fiber spawned new work. Work on that next.
--         workInProgress = next
--         return
--       end
--     } else {
--       -- This fiber did not complete because something threw. Pop values off
--       -- the stack without entering the complete phase. If this is a boundary,
--       -- capture values if possible.
--       local next = unwindWork(completedWork, subtreeRenderLanes)

--       -- Because this fiber did not complete, don't reset its expiration time.

--       if next ~= nil)
--         -- If completing this work spawned new work, do that next. We'll come
--         -- back here again.
--         -- Since we're restarting, remove anything that is not a host effect
--         -- from the effect tag.
--         next.flags &= HostEffectMask
--         workInProgress = next
--         return
--       end

--       if 
--         enableProfilerTimer and
--         (completedWork.mode & ProfileMode) ~= NoMode
--       )
--         -- Record the render duration for the fiber that errored.
--         stopProfilerTimerIfRunningAndRecordDelta(completedWork, false)

--         -- Include the time spent working on failed children before continuing.
--         local actualDuration = completedWork.actualDuration
--         local child = completedWork.child
--         while (child ~= nil)
--           actualDuration += child.actualDuration
--           child = child.sibling
--         end
--         completedWork.actualDuration = actualDuration
--       end

--       if returnFiber ~= nil)
--         -- Mark the parent fiber as incomplete
--         returnFiber.flags |= Incomplete
--         returnFiber.subtreeFlags = NoFlags
--         returnFiber.deletions = nil
--       end
--     end

--     local siblingFiber = completedWork.sibling
--     if siblingFiber ~= nil)
--       -- If there is more work to do in this returnFiber, do that next.
--       workInProgress = siblingFiber
--       return
--     end
--     -- Otherwise, return to the parent
--     completedWork = returnFiber
--     -- Update the next thing we're working on in case something throws.
--     workInProgress = completedWork
--   } while (completedWork ~= nil)

--   -- We've reached the root.
--   if workInProgressRootExitStatus == RootIncomplete)
--     workInProgressRootExitStatus = RootCompleted
--   end
-- end

-- function commitRoot(root)
--   local renderPriorityLevel = getCurrentPriorityLevel()
--   runWithPriority(
--     ImmediateSchedulerPriority,
--     commitRootImpl.bind(null, root, renderPriorityLevel),
--   )
--   return nil
-- end

-- function commitRootImpl(root, renderPriorityLevel)
--   do {
--     -- `flushPassiveEffects` will call `flushSyncUpdateQueue` at the end, which
--     -- means `flushPassiveEffects` will sometimes result in additional
--     -- passive effects. So we need to keep flushing in a loop until there are
--     -- no more pending effects.
--     -- TODO: Might be better if `flushPassiveEffects` did not automatically
--     -- flush synchronous work at the end, to avoid factoring hazards like this.
--     flushPassiveEffects()
--   } while (rootWithPendingPassiveEffects ~= nil)
--   flushRenderPhaseStrictModeWarningsInDEV()

--   invariant(
--     (executionContext & (RenderContext | CommitContext)) == NoContext,
--     'Should not already be working.',
--   )

--   local finishedWork = root.finishedWork
--   local lanes = root.finishedLanes

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logCommitStarted(lanes)
--     end
--   end

--   if enableSchedulingProfiler)
--     markCommitStarted(lanes)
--   end

--   if finishedWork == nil)
--     if _G.__DEV__)
--       if enableDebugTracing)
--         logCommitStopped()
--       end
--     end

--     if enableSchedulingProfiler)
--       markCommitStopped()
--     end

--     return nil
--   end
--   root.finishedWork = nil
--   root.finishedLanes = NoLanes

--   invariant(
--     finishedWork ~= root.current,
--     'Cannot commit the same tree as before. This error is likely caused by ' +
--       'a bug in React. Please file an issue.',
--   )

--   -- commitRoot never returns a continuation; it always finishes synchronously.
--   -- So we can clear these now to allow a new callback to be scheduled.
--   root.callbackNode = nil

--   -- Update the first and last pending times on this root. The new first
--   -- pending time is whatever is left on the root fiber.
--   local remainingLanes = mergeLanes(finishedWork.lanes, finishedWork.childLanes)
--   markRootFinished(root, remainingLanes)

--   -- Clear already finished discrete updates in case that a later call of
--   -- `flushDiscreteUpdates` starts a useless render pass which may cancels
--   -- a scheduled timeout.
--   if rootsWithPendingDiscreteUpdates ~= nil)
--     if 
--       !hasDiscreteLanes(remainingLanes) and
--       rootsWithPendingDiscreteUpdates.has(root)
--     )
--       rootsWithPendingDiscreteUpdates.delete(root)
--     end
--   end

--   if root == workInProgressRoot)
--     -- We can reset these now that they are finished.
--     workInProgressRoot = nil
--     workInProgress = nil
--     workInProgressRootRenderLanes = NoLanes
--   } else {
--     -- This indicates that the last root we worked on is not the same one that
--     -- we're committing now. This most commonly happens when a suspended root
--     -- times out.
--   end

--   -- If there are pending passive effects, schedule a callback to process them.
--   -- Do this as early as possible, so it is queued before anything else that
--   -- might get scheduled in the commit phase. (See #16714.)
--   local rootDoesHavePassiveEffects =
--     (finishedWork.subtreeFlags & PassiveMask) ~= NoFlags or
--     (finishedWork.flags & PassiveMask) ~= NoFlags
--   if rootDoesHavePassiveEffects)
--     rootWithPendingPassiveEffects = root
--     pendingPassiveEffectsLanes = lanes
--     pendingPassiveEffectsRenderPriority = renderPriorityLevel
--     scheduleCallback(NormalSchedulerPriority, () => {
--       flushPassiveEffects()
--       return nil
--     })
--   end

--   -- Check if there are any effects in the whole tree.
--   -- TODO: This is left over from the effect list implementation, where we had
--   -- to check for the existence of `firstEffect` to satsify Flow. I think the
--   -- only other reason this optimization exists is because it affects profiling.
--   -- Reconsider whether this is necessary.
--   local subtreeHasEffects =
--     (finishedWork.subtreeFlags &
--       (BeforeMutationMask | MutationMask | LayoutMask | PassiveMask)) ~=
--     NoFlags
--   local rootHasEffect =
--     (finishedWork.flags &
--       (BeforeMutationMask | MutationMask | LayoutMask | PassiveMask)) ~=
--     NoFlags

--   if subtreeHasEffects or rootHasEffect)
--     local previousLanePriority
--     if decoupleUpdatePriorityFromScheduler)
--       previousLanePriority = getCurrentUpdateLanePriority()
--       setCurrentUpdateLanePriority(SyncLanePriority)
--     end

--     local prevExecutionContext = executionContext
--     executionContext |= CommitContext
--     local prevInteractions = pushInteractions(root)

--     -- Reset this to nil before calling lifecycles
--     ReactCurrentOwner.current = nil

--     -- The commit phase is broken into several sub-phases. We do a separate pass
--     -- of the effect list for each phase: all mutation effects come before all
--     -- layout effects, and so on.

--     -- The first phase a "before mutation" phase. We use this phase to read the
--     -- state of the host tree right before we mutate it. This is where
--     -- getSnapshotBeforeUpdate is called.
--     local shouldFireAfterActiveInstanceBlur = commitBeforeMutationEffects(
--       root,
--       finishedWork,
--     )

--     if enableProfilerTimer)
--       -- Mark the current commit time to be shared by all Profilers in this
--       -- batch. This enables them to be grouped later.
--       recordCommitTime()
--     end

--     -- The next phase is the mutation phase, where we mutate the host tree.
--     commitMutationEffects(finishedWork, root, renderPriorityLevel)

--     if shouldFireAfterActiveInstanceBlur)
--       afterActiveInstanceBlur()
--     end
--     resetAfterCommit(root.containerInfo)

--     -- The work-in-progress tree is now the current tree. This must come after
--     -- the mutation phase, so that the previous tree is still current during
--     -- componentWillUnmount, but before the layout phase, so that the finished
--     -- work is current during componentDidMount/Update.
--     root.current = finishedWork

--     -- The next phase is the layout phase, where we call effects that read
--     -- the host tree after it's been mutated. The idiomatic use case for this is
--     -- layout, but class component lifecycles also fire here for legacy reasons.

--     if _G.__DEV__)
--       if enableDebugTracing)
--         logLayoutEffectsStarted(lanes)
--       end
--     end
--     if enableSchedulingProfiler)
--       markLayoutEffectsStarted(lanes)
--     end

--     commitLayoutEffects(finishedWork, root)

--     if _G.__DEV__)
--       if enableDebugTracing)
--         logLayoutEffectsStopped()
--       end
--     end
--     if enableSchedulingProfiler)
--       markLayoutEffectsStopped()
--     end

--     -- Tell Scheduler to yield at the end of the frame, so the browser has an
--     -- opportunity to paint.
--     requestPaint()

--     if enableSchedulerTracing)
--       popInteractions(((prevInteractions: any): Set<Interaction>))
--     end
--     executionContext = prevExecutionContext

--     if decoupleUpdatePriorityFromScheduler and previousLanePriority ~= nil)
--       -- Reset the priority to the previous non-sync value.
--       setCurrentUpdateLanePriority(previousLanePriority)
--     end
--   } else {
--     -- No effects.
--     root.current = finishedWork
--     -- Measure these anyway so the flamegraph explicitly shows that there were
--     -- no effects.
--     -- TODO: Maybe there's a better way to report this.
--     if enableProfilerTimer)
--       recordCommitTime()
--     end
--   end

--   -- Read this again, since an effect might have updated it
--   remainingLanes = root.pendingLanes

--   -- Check if there's remaining work on this root
--   if remainingLanes ~= NoLanes)
--     if enableSchedulerTracing)
--       if spawnedWorkDuringRender ~= nil)
--         local expirationTimes = spawnedWorkDuringRender
--         spawnedWorkDuringRender = nil
--         for (local i = 0; i < expirationTimes.length; i++)
--           scheduleInteractions(
--             root,
--             expirationTimes[i],
--             root.memoizedInteractions,
--           )
--         end
--       end
--       schedulePendingInteractions(root, remainingLanes)
--     end
--   } else {
--     -- If there's no remaining work, we can clear the set of already failed
--     -- error boundaries.
--     legacyErrorBoundariesThatAlreadyFailed = nil
--   end

--   if _G.__DEV__ and enableDoubleInvokingEffects)
--     if !rootDoesHavePassiveEffects)
--       commitDoubleInvokeEffectsInDEV(root.current, false)
--     end
--   end

--   if enableSchedulerTracing)
--     if !rootDoesHavePassiveEffects)
--       -- If there are no passive effects, then we can complete the pending interactions.
--       -- Otherwise, we'll wait until after the passive effects are flushed.
--       -- Wait to do this until after remaining work has been scheduled,
--       -- so that we don't prematurely signal complete for interactions when there's e.g. hidden work.
--       finishPendingInteractions(root, lanes)
--     end
--   end

--   if remainingLanes == SyncLane)
--     -- Count the number of times the root synchronously re-renders without
--     -- finishing. If there are too many, it indicates an infinite update loop.
--     if root == rootWithNestedUpdates)
--       nestedUpdateCount++
--     } else {
--       nestedUpdateCount = 0
--       rootWithNestedUpdates = root
--     end
--   } else {
  --   end
  --     nestedUpdateCount = 0

--   onCommitRootDevTools(finishedWork.stateNode, renderPriorityLevel)

--   if _G.__DEV__)
--     onCommitRootTestSelector()
--   end

--   -- Always call this before exiting `commitRoot`, to ensure that any
--   -- additional work on this root is scheduled.
--   ensureRootIsScheduled(root, now())

--   if hasUncaughtError)
--     hasUncaughtError = false
--     local error = firstUncaughtError
--     firstUncaughtError = nil
--     throw error
--   end

--   if (executionContext & LegacyUnbatchedContext) ~= NoContext)
--     if _G.__DEV__)
--       if enableDebugTracing)
--         logCommitStopped()
--       end
--     end

--     if enableSchedulingProfiler)
--       markCommitStopped()
--     end

--     -- This is a legacy edge case. We just committed the initial mount of
--     -- a ReactDOM.render-ed root inside of batchedUpdates. The commit fired
--     -- synchronously, but layout updates should be deferred until the end
--     -- of the batch.
--     return nil
--   end

--   -- If layout work was scheduled, flush it now.
--   flushSyncCallbackQueue()

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logCommitStopped()
--     end
--   end

--   if enableSchedulingProfiler)
--     markCommitStopped()
--   end

--   return nil
-- end

-- exports.flushPassiveEffects(): boolean {
--   -- Returns whether passive effects were flushed.
--   if pendingPassiveEffectsRenderPriority ~= NoSchedulerPriority)
--     local priorityLevel =
--       pendingPassiveEffectsRenderPriority > NormalSchedulerPriority
--         ? NormalSchedulerPriority
--         : pendingPassiveEffectsRenderPriority
--     pendingPassiveEffectsRenderPriority = NoSchedulerPriority
--     if decoupleUpdatePriorityFromScheduler)
--       local previousLanePriority = getCurrentUpdateLanePriority()
--       try {
--         setCurrentUpdateLanePriority(
--           schedulerPriorityToLanePriority(priorityLevel),
--         )
--         return runWithPriority(priorityLevel, flushPassiveEffectsImpl)
--       } finally {
--         setCurrentUpdateLanePriority(previousLanePriority)
--       end
--     } else {
--       return runWithPriority(priorityLevel, flushPassiveEffectsImpl)
--     end
--   end
--   return false
-- end

-- function flushPassiveEffectsImpl()
--   if rootWithPendingPassiveEffects == nil)
--     return false
--   end

--   local root = rootWithPendingPassiveEffects
--   local lanes = pendingPassiveEffectsLanes
--   rootWithPendingPassiveEffects = nil
--   pendingPassiveEffectsLanes = NoLanes

--   invariant(
--     (executionContext & (RenderContext | CommitContext)) == NoContext,
--     'Cannot flush passive effects while already rendering.',
--   )

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logPassiveEffectsStarted(lanes)
--     end
--   end

--   if enableSchedulingProfiler)
--     markPassiveEffectsStarted(lanes)
--   end

--   if _G.__DEV__)
--     isFlushingPassiveEffects = true
--   end

--   local prevExecutionContext = executionContext
--   executionContext |= CommitContext
--   local prevInteractions = pushInteractions(root)

--   -- It's important that ALL pending passive effect destroy functions are called
--   -- before ANY passive effect create functions are called.
--   -- Otherwise effects in sibling components might interfere with each other.
--   -- e.g. a destroy function in one component may unintentionally override a ref
--   -- value set by a create function in another component.
--   -- Layout effects have the same constraint.
--   commitPassiveUnmountEffects(root.current)
--   commitPassiveMountEffects(root, root.current)

--   if _G.__DEV__)
--     if enableDebugTracing)
--       logPassiveEffectsStopped()
--     end
--   end

--   if enableSchedulingProfiler)
--     markPassiveEffectsStopped()
--   end

--   if _G.__DEV__ and enableDoubleInvokingEffects)
--     commitDoubleInvokeEffectsInDEV(root.current, true)
--   end

--   if _G.__DEV__)
--     isFlushingPassiveEffects = false
--   end

--   if enableSchedulerTracing)
--     popInteractions(((prevInteractions: any): Set<Interaction>))
--     finishPendingInteractions(root, lanes)
--   end

--   executionContext = prevExecutionContext

--   flushSyncCallbackQueue()

--   -- If additional passive effects were scheduled, increment a counter. If this
--   -- exceeds the limit, we'll fire a warning.
--   nestedPassiveUpdateCount =
--     rootWithPendingPassiveEffects == nil ? 0 : nestedPassiveUpdateCount + 1

--   return true
-- end

-- exports.isAlreadyFailedLegacyErrorBoundary(instance: mixed): boolean {
--   return (
--     legacyErrorBoundariesThatAlreadyFailed ~= nil and
--     legacyErrorBoundariesThatAlreadyFailed.has(instance)
--   )
-- end

-- exports.markLegacyErrorBoundaryAsFailed(instance: mixed)
--   if legacyErrorBoundariesThatAlreadyFailed == nil)
--     legacyErrorBoundariesThatAlreadyFailed = new Set([instance])
--   } else {
--     legacyErrorBoundariesThatAlreadyFailed.add(instance)
--   end
-- end

-- function prepareToThrowUncaughtError(error: mixed)
--   if !hasUncaughtError)
--     hasUncaughtError = true
--     firstUncaughtError = error
--   end
-- end
-- export local onUncaughtError = prepareToThrowUncaughtError

-- function captureCommitPhaseErrorOnRoot(
--   rootFiber: Fiber,
--   sourceFiber: Fiber,
--   error: mixed,
-- )
--   local errorInfo = createCapturedValue(error, sourceFiber)
--   local update = createRootErrorUpdate(rootFiber, errorInfo, (SyncLane: Lane))
--   enqueueUpdate(rootFiber, update)
--   local eventTime = requestEventTime()
--   local root = markUpdateLaneFromFiberToRoot(rootFiber, (SyncLane: Lane))
--   if root ~= nil)
--     markRootUpdated(root, SyncLane, eventTime)
--     ensureRootIsScheduled(root, eventTime)
--     schedulePendingInteractions(root, SyncLane)
--   end
-- end

-- exports.captureCommitPhaseError(
--   sourceFiber: Fiber,
--   nearestMountedAncestor: Fiber | nil,
--   error: mixed,
-- )
--   if sourceFiber.tag == HostRoot)
--     -- Error was thrown at the root. There is no parent, so the root
--     -- itself should capture it.
--     captureCommitPhaseErrorOnRoot(sourceFiber, sourceFiber, error)
--     return
--   end

--   local fiber = nil
--   if skipUnmountedBoundaries)
--     fiber = nearestMountedAncestor
--   } else {
--     fiber = sourceFiber.return
--   end

--   while (fiber ~= nil)
--     if fiber.tag == HostRoot)
--       captureCommitPhaseErrorOnRoot(fiber, sourceFiber, error)
--       return
--     } else if fiber.tag == ClassComponent)
--       local ctor = fiber.type
--       local instance = fiber.stateNode
--       if 
--         typeof ctor.getDerivedStateFromError == 'function' or
--         (typeof instance.componentDidCatch == 'function' and
--           !isAlreadyFailedLegacyErrorBoundary(instance))
--       )
--         local errorInfo = createCapturedValue(error, sourceFiber)
--         local update = createClassErrorUpdate(
--           fiber,
--           errorInfo,
--           (SyncLane: Lane),
--         )
--         enqueueUpdate(fiber, update)
--         local eventTime = requestEventTime()
--         local root = markUpdateLaneFromFiberToRoot(fiber, (SyncLane: Lane))
--         if root ~= nil)
--           markRootUpdated(root, SyncLane, eventTime)
--           ensureRootIsScheduled(root, eventTime)
--           schedulePendingInteractions(root, SyncLane)
--         end
--         return
--       end
--     end
--     fiber = fiber.return
--   end
-- end

-- exports.pingSuspendedRoot(
--   root: FiberRoot,
--   wakeable: Wakeable,
--   pingedLanes: Lanes,
-- )
--   local pingCache = root.pingCache
--   if pingCache ~= nil)
--     -- The wakeable resolved, so we no longer need to memoize, because it will
--     -- never be thrown again.
--     pingCache.delete(wakeable)
--   end

--   local eventTime = requestEventTime()
--   markRootPinged(root, pingedLanes, eventTime)

--   if 
--     workInProgressRoot == root and
--     isSubsetOfLanes(workInProgressRootRenderLanes, pingedLanes)
--   )
--     -- Received a ping at the same priority level at which we're currently
--     -- rendering. We might want to restart this render. This should mirror
--     -- the logic of whether or not a root suspends once it completes.

--     -- TODO: If we're rendering sync either due to Sync, Batched or expired,
--     -- we should probably never restart.

--     -- If we're suspended with delay, or if it's a retry, we'll always suspend
--     -- so we can always restart.
--     if 
--       workInProgressRootExitStatus == RootSuspendedWithDelay or
--       (workInProgressRootExitStatus == RootSuspended and
--         includesOnlyRetries(workInProgressRootRenderLanes) and
--         now() - globalMostRecentFallbackTime < FALLBACK_THROTTLE_MS)
--     )
--       -- Restart from the root.
--       prepareFreshStack(root, NoLanes)
--     } else {
--       -- Even though we can't restart right now, we might get an
--       -- opportunity later. So we mark this render as having a ping.
--       workInProgressRootPingedLanes = mergeLanes(
--         workInProgressRootPingedLanes,
--         pingedLanes,
--       )
--     end
--   end

--   ensureRootIsScheduled(root, eventTime)
--   schedulePendingInteractions(root, pingedLanes)
-- end

-- function retryTimedOutBoundary(boundaryFiber: Fiber, retryLane: Lane)
--   -- The boundary fiber (a Suspense component or SuspenseList component)
--   -- previously was rendered in its fallback state. One of the promises that
--   -- suspended it has resolved, which means at least part of the tree was
--   -- likely unblocked. Try rendering again, at a new expiration time.
--   if retryLane == NoLane)
--     retryLane = requestRetryLane(boundaryFiber)
--   end
--   -- TODO: Special case idle priority?
--   local eventTime = requestEventTime()
--   local root = markUpdateLaneFromFiberToRoot(boundaryFiber, retryLane)
--   if root ~= nil)
--     markRootUpdated(root, retryLane, eventTime)
--     ensureRootIsScheduled(root, eventTime)
--     schedulePendingInteractions(root, retryLane)
--   end
-- end

-- exports.retryDehydratedSuspenseBoundary(boundaryFiber: Fiber)
--   local suspenseState: nil | SuspenseState = boundaryFiber.memoizedState
--   local retryLane = NoLane
--   if suspenseState ~= nil)
--     retryLane = suspenseState.retryLane
--   end
--   retryTimedOutBoundary(boundaryFiber, retryLane)
-- end

-- exports.resolveRetryWakeable(boundaryFiber: Fiber, wakeable: Wakeable)
--   local retryLane = NoLane; -- Default
--   local retryCache: WeakSet<Wakeable> | Set<Wakeable> | nil
--   if enableSuspenseServerRenderer)
--     switch (boundaryFiber.tag)
--       case SuspenseComponent:
--         retryCache = boundaryFiber.stateNode
--         local suspenseState: nil | SuspenseState = boundaryFiber.memoizedState
--         if suspenseState ~= nil)
--           retryLane = suspenseState.retryLane
--         end
--         break
--       case SuspenseListComponent:
--         retryCache = boundaryFiber.stateNode
--         break
--       default:
--         invariant(
--           false,
--           'Pinged unknown suspense boundary type. ' +
--             'This is probably a bug in React.',
--         )
--     end
--   } else {
--     retryCache = boundaryFiber.stateNode
--   end

--   if retryCache ~= nil)
--     -- The wakeable resolved, so we no longer need to memoize, because it will
--     -- never be thrown again.
--     retryCache.delete(wakeable)
--   end

--   retryTimedOutBoundary(boundaryFiber, retryLane)
-- end

-- -- Computes the next Just Noticeable Difference (JND) boundary.
-- -- The theory is that a person can't tell the difference between small differences in time.
-- -- Therefore, if we wait a bit longer than necessary that won't translate to a noticeable
-- -- difference in the experience. However, waiting for longer might mean that we can avoid
-- -- showing an intermediate loading state. The longer we have already waited, the harder it
-- -- is to tell small differences in time. Therefore, the longer we've already waited,
-- -- the longer we can wait additionally. At some point we have to give up though.
-- -- We pick a train model where the next boundary commits at a consistent schedule.
-- -- These particular numbers are vague estimates. We expect to adjust them based on research.
-- function jnd(timeElapsed: number)
--   return timeElapsed < 120
--     ? 120
--     : timeElapsed < 480
--     ? 480
--     : timeElapsed < 1080
--     ? 1080
--     : timeElapsed < 1920
--     ? 1920
--     : timeElapsed < 3000
--     ? 3000
--     : timeElapsed < 4320
--     ? 4320
--     : ceil(timeElapsed / 1960) * 1960
-- end

checkForNestedUpdates = function()
  if nestedUpdateCount > NESTED_UPDATE_LIMIT then
    nestedUpdateCount = 0
    -- rootWithNestedUpdates = nil
    invariant(
      false,
      "Maximum update depth exceeded. This can happen when a component " ..
        "repeatedly calls setState inside componentWillUpdate or " ..
        "componentDidUpdate. React limits the number of nested updates to " ..
        "prevent infinite loops."
    )
  end

  if _G.__DEV__ then
    if nestedPassiveUpdateCount > NESTED_PASSIVE_UPDATE_LIMIT then
      nestedPassiveUpdateCount = 0
      console.error(
        "Maximum update depth exceeded. This can happen when a component " ..
          "calls setState inside useEffect, but useEffect either doesn't " ..
          "have a dependency array, or one of the dependencies changes on " ..
          "every render."
      )
    end
  end
end

-- function flushRenderPhaseStrictModeWarningsInDEV()
--   if _G.__DEV__)
--     ReactStrictModeWarnings.flushLegacyContextWarning()

--     if warnAboutDeprecatedLifecycles)
--       ReactStrictModeWarnings.flushPendingUnsafeLifecycleWarnings()
--     end
--   end
-- end

-- local didWarnStateUpdateForNotYetMountedComponent: Set<string> | nil = nil
-- function warnAboutUpdateOnNotYetMountedFiberInDEV(fiber)
--   if _G.__DEV__)
--     if (executionContext & RenderContext) ~= NoContext)
--       -- We local the other warning about render phase updates deal with this one.
--       return
--     end

--     if !(fiber.mode & (BlockingMode | ConcurrentMode)))
--       return
--     end

--     local tag = fiber.tag
--     if 
--       tag ~= IndeterminateComponent and
--       tag ~= HostRoot and
--       tag ~= ClassComponent and
--       tag ~= FunctionComponent and
--       tag ~= ForwardRef and
--       tag ~= MemoComponent and
--       tag ~= SimpleMemoComponent
--     )
--       -- Only warn for user-defined components, not internal ones like Suspense.
--       return
--     end

--     -- We show the whole stack but dedupe on the top component's name because
--     -- the problematic code almost always lies inside that component.
--     local componentName = getComponentName(fiber.type) or 'ReactComponent'
--     if didWarnStateUpdateForNotYetMountedComponent ~= nil)
--       if didWarnStateUpdateForNotYetMountedComponent.has(componentName))
--         return
--       end
--       didWarnStateUpdateForNotYetMountedComponent.add(componentName)
--     } else {
--       didWarnStateUpdateForNotYetMountedComponent = new Set([componentName])
--     end

--     local previousFiber = ReactCurrentFiberCurrent
--     try {
--       setCurrentDebugFiberInDEV(fiber)
--       console.error(
--         "Can't perform a React state update on a component that hasn't mounted yet. " +
--           'This indicates that you have a side-effect in your render function that ' +
--           'asynchronously later calls tries to update the component. Move this work to ' +
--           'useEffect instead.',
--       )
--     } finally {
--       if previousFiber)
--         setCurrentDebugFiberInDEV(fiber)
--       } else {
--         resetCurrentDebugFiberInDEV()
--       end
--     end
--   end
-- end

-- local didWarnStateUpdateForUnmountedComponent: Set<string> | nil = nil
-- function warnAboutUpdateOnUnmountedFiberInDEV(fiber)
--   if _G.__DEV__)
--     local tag = fiber.tag
--     if 
--       tag ~= HostRoot and
--       tag ~= ClassComponent and
--       tag ~= FunctionComponent and
--       tag ~= ForwardRef and
--       tag ~= MemoComponent and
--       tag ~= SimpleMemoComponent
--     )
--       -- Only warn for user-defined components, not internal ones like Suspense.
--       return
--     end

--     if (fiber.flags & PassiveStatic) ~= NoFlags)
--       local updateQueue: FunctionComponentUpdateQueue | nil = (fiber.updateQueue: any)
--       if updateQueue ~= nil)
--         local lastEffect = updateQueue.lastEffect
--         if lastEffect ~= nil)
--           local firstEffect = lastEffect.next

--           local effect = firstEffect
--           do {
--             if effect.destroy ~= undefined)
--               if (effect.tag & HookPassive) ~= NoHookEffect)
--                 return
--               end
--             end
--             effect = effect.next
--           } while (effect ~= firstEffect)
--         end
--       end
--     end

--     -- We show the whole stack but dedupe on the top component's name because
--     -- the problematic code almost always lies inside that component.
--     local componentName = getComponentName(fiber.type) or 'ReactComponent'
--     if didWarnStateUpdateForUnmountedComponent ~= nil)
--       if didWarnStateUpdateForUnmountedComponent.has(componentName))
--         return
--       end
--       didWarnStateUpdateForUnmountedComponent.add(componentName)
--     } else {
--       didWarnStateUpdateForUnmountedComponent = new Set([componentName])
--     end

--     if isFlushingPassiveEffects)
--       -- Do not warn if we are currently flushing passive effects!
--       --
--       -- React can't directly detect a memory leak, but there are some clues that warn about one.
--       -- One of these clues is when an unmounted React component tries to update its state.
--       -- For example, if a component forgets to remove an event listener when unmounting,
--       -- that listener may be called later and try to update state,
--       -- at which point React would warn about the potential leak.
--       --
--       -- Warning signals are the most useful when they're strong.
--       -- (So we should avoid false positive warnings.)
--       -- Updating state from within an effect cleanup function is sometimes a necessary pattern, e.g.:
--       -- 1. Updating an ancestor that a component had registered itself with on mount.
--       -- 2. Resetting state when a component is hidden after going offscreen.
--     } else {
--       local previousFiber = ReactCurrentFiberCurrent
--       try {
--         setCurrentDebugFiberInDEV(fiber)
--         console.error(
--           "Can't perform a React state update on an unmounted component. This " +
--             'is a no-op, but it indicates a memory leak in your application. To ' +
--             'fix, cancel all subscriptions and asynchronous tasks in %s.',
--           tag == ClassComponent
--             ? 'the componentWillUnmount method'
--             : 'a useEffect cleanup function',
--         )
--       } finally {
--         if previousFiber)
--           setCurrentDebugFiberInDEV(fiber)
--         } else {
--           resetCurrentDebugFiberInDEV()
--         end
--       end
--     end
--   end
-- end

-- local beginWork
-- if _G.__DEV__ and replayFailedUnitOfWorkWithInvokeGuardedCallback)
--   local dummyFiber = nil
--   beginWork = (current, unitOfWork, lanes) => {
--     -- If a component throws an error, we replay it again in a synchronously
--     -- dispatched event, so that the debugger will treat it as an uncaught
--     -- error See ReactErrorUtils for more information.

--     -- Before entering the begin phase, copy the work-in-progress onto a dummy
--     -- fiber. If beginWork throws, we'll use this to reset the state.
--     local originalWorkInProgressCopy = assignFiberPropertiesInDEV(
--       dummyFiber,
--       unitOfWork,
--     )
--     try {
--       return originalBeginWork(current, unitOfWork, lanes)
--     } catch (originalError)
--       if 
--         originalError ~= nil and
--         typeof originalError == "table" and
--         typeof originalError.then == 'function'
--       )
--         -- Don't replay promises. Treat everything else like an error.
--         throw originalError
--       end

--       -- Keep this code in sync with handleError; any changes here must have
--       -- corresponding changes there.
--       resetContextDependencies()
--       resetHooksAfterThrow()
--       -- Don't reset current debug fiber, since we're about to work on the
--       -- same fiber again.

--       -- Unwind the failed stack frame
--       unwindInterruptedWork(unitOfWork)

--       -- Restore the original properties of the fiber.
--       assignFiberPropertiesInDEV(unitOfWork, originalWorkInProgressCopy)

--       if enableProfilerTimer and unitOfWork.mode & ProfileMode)
--         -- Reset the profiler timer.
--         startProfilerTimer(unitOfWork)
--       end

--       -- Run beginWork again.
--       invokeGuardedCallback(
--         nil,
--         originalBeginWork,
--         nil,
--         current,
--         unitOfWork,
--         lanes,
--       )

--       if hasCaughtError())
--         local replayError = clearCaughtError()
--         -- `invokeGuardedCallback` sometimes sets an expando `_suppressLogging`.
--         -- Rethrow this error instead of the original one.
--         throw replayError
--       } else {
--         -- This branch is reachable if the render phase is impure.
--         throw originalError
--       end
--     end
--   end
-- } else {
--   beginWork = originalBeginWork
-- end

-- local didWarnAboutUpdateInRender = false
-- local didWarnAboutUpdateInRenderForAnotherComponent
-- if _G.__DEV__ then
--   didWarnAboutUpdateInRenderForAnotherComponent = {}
-- end

warnAboutRenderPhaseUpdatesInDEV = function(fiber)
  -- FIXME: WIP
  -- if _G.__DEV__ then
  --   if
  --     ReactCurrentDebugFiberIsRenderingInDEV and
  --     bit32.band(executionContext, RenderContext) ~= NoContext and
  --     not getIsUpdatingOpaqueValueInRenderPhaseInDEV()
  --   then
  --     if fiber.tag == FunctionComponent or
  --       fiber.tag == ForwardRef or
  --       fiber.tag == SimpleMemoComponent
  --     then
  --       local renderingComponentName =
  --         (workInProgress and getComponentName(workInProgress.type)) or
  --         "Unknown"
  --       -- Dedupe by the rendering component because it's the one that needs to be fixed.
  --       local dedupeKey = renderingComponentName
  --       -- deviation: 
  --       -- if !didWarnAboutUpdateInRenderForAnotherComponent.has(dedupeKey))
  --       if didWarnAboutUpdateInRenderForAnotherComponent[dedupeKey] == nil then
  --         didWarnAboutUpdateInRenderForAnotherComponent[dedupeKey] = true
  --         local setStateComponentName = getComponentName(fiber.type) or "Unknown"
  --         console.error(
  --           "Cannot update a component (`%s`) while rendering a " ..
  --             "different component (`%s`). To locate the bad setState() call inside `%s`, " ..
  --             "follow the stack trace as described in https://reactjs.org/link/setstate-in-render",
  --           setStateComponentName,
  --           renderingComponentName,
  --           renderingComponentName
  --         )
  --       end
  --     elseif fiber.tag == ClassComponent then
  --       if not didWarnAboutUpdateInRender then
  --         console.error(
  --           "Cannot update during an existing state transition (such as " ..
  --             "within `render`). Render methods should be a pure " ..
  --             "function of props and state."
  --         )
  --         didWarnAboutUpdateInRender = true
  --       end
  --     end
  --   end
  -- end
end

-- -- a 'shared' variable that changes when act() opens/closes in tests.
-- export local IsThisRendererActing = {current: (false: boolean)}

-- exports.warnIfNotScopedWithMatchingAct(fiber: Fiber): void {
--   if _G.__DEV__)
--     if 
--       warnsIfNotActing == true and
--       IsSomeRendererActing.current == true and
--       IsThisRendererActing.current ~= true
--     )
--       local previousFiber = ReactCurrentFiberCurrent
--       try {
--         setCurrentDebugFiberInDEV(fiber)
--         console.error(
--           "It looks like you're using the wrong act() around your test interactions.\n" +
--             'Be sure to use the matching version of act() corresponding to your renderer:\n\n' +
--             '-- for react-dom:\n' +
--             -- Break up imports to avoid accidentally parsing them as dependencies.
--             'local {act} fr' +
--             "om 'react-dom/test-utils';\n" +
--             '-- ...\n' +
--             'act(() => ...);\n\n' +
--             '-- for react-test-renderer:\n' +
--             -- Break up imports to avoid accidentally parsing them as dependencies.
--             'local TestRenderer fr' +
--             "om react-test-renderer';\n" +
--             'local {act} = TestRenderer;\n' +
--             '-- ...\n' +
--             'act(() => ...);',
--         )
--       } finally {
--         if previousFiber)
--           setCurrentDebugFiberInDEV(fiber)
--         } else {
--           resetCurrentDebugFiberInDEV()
--         end
--       end
--     end
--   end
-- end

-- exports.warnIfNotCurrentlyActingEffectsInDEV(fiber: Fiber): void {
--   if _G.__DEV__)
--     if 
--       warnsIfNotActing == true and
--       (fiber.mode & StrictMode) ~= NoMode and
--       IsSomeRendererActing.current == false and
--       IsThisRendererActing.current == false
--     )
--       console.error(
--         'An update to %s ran an effect, but was not wrapped in act(...).\n\n' +
--           'When testing, code that causes React state updates should be ' +
--           'wrapped into act(...):\n\n' +
--           'act(() => {\n' +
--           '  --[[ fire events that update state ]]\n' +
--           '});\n' +
--           '--[[ assert on the output ]]\n\n' +
--           "This ensures that you're testing the behavior the user would see " +
--           'in the browser.' +
--           ' Learn more at https:--reactjs.org/link/wrap-tests-with-act',
--         getComponentName(fiber.type),
--       )
--     end
--   end
-- end

-- function warnIfNotCurrentlyActingUpdatesInDEV(fiber: Fiber): void {
--   if _G.__DEV__)
--     if 
--       warnsIfNotActing == true and
--       executionContext == NoContext and
--       IsSomeRendererActing.current == false and
--       IsThisRendererActing.current == false
--     )
--       local previousFiber = ReactCurrentFiberCurrent
--       try {
--         setCurrentDebugFiberInDEV(fiber)
--         console.error(
--           'An update to %s inside a test was not wrapped in act(...).\n\n' +
--             'When testing, code that causes React state updates should be ' +
--             'wrapped into act(...):\n\n' +
--             'act(() => {\n' +
--             '  --[[ fire events that update state ]]\n' +
--             '});\n' +
--             '--[[ assert on the output ]]\n\n' +
--             "This ensures that you're testing the behavior the user would see " +
--             'in the browser.' +
--             ' Learn more at https:--reactjs.org/link/wrap-tests-with-act',
--           getComponentName(fiber.type),
--         )
--       } finally {
--         if previousFiber)
--           setCurrentDebugFiberInDEV(fiber)
--         } else {
--           resetCurrentDebugFiberInDEV()
--         end
--       end
--     end
--   end
-- end

-- export local warnIfNotCurrentlyActingUpdatesInDev = warnIfNotCurrentlyActingUpdatesInDEV

-- -- In tests, we want to enforce a mocked scheduler.
-- local didWarnAboutUnmockedScheduler = false
-- -- TODO Before we release concurrent mode, revisit this and decide whether a mocked
-- -- scheduler is the actual recommendation. The alternative could be a testing build,
-- -- a new lib, or whatever; we dunno just yet. This message is for early adopters
-- -- to get their tests right.

-- exports.warnIfUnmockedScheduler(fiber: Fiber)
--   if _G.__DEV__)
--     if 
--       didWarnAboutUnmockedScheduler == false and
--       Scheduler.unstable_flushAllWithoutAsserting == undefined
--     )
--       if fiber.mode & BlockingMode or fiber.mode & ConcurrentMode)
--         didWarnAboutUnmockedScheduler = true
--         console.error(
--           'In Concurrent or Sync modes, the "scheduler" module needs to be mocked ' +
--             'to guarantee consistent behaviour across tests and browsers. ' +
--             'For example, with jest: \n' +
--             -- Break up requires to avoid accidentally parsing them as dependencies.
--             "jest.mock('scheduler', () => require" +
--             "('scheduler/unstable_mock'));\n\n" +
--             'For more info, visit https:--reactjs.org/link/mock-scheduler',
--         )
--       } else if warnAboutUnmockedScheduler == true)
--         didWarnAboutUnmockedScheduler = true
--         console.error(
--           'Starting from React v18, the "scheduler" module will need to be mocked ' +
--             'to guarantee consistent behaviour across tests and browsers. ' +
--             'For example, with jest: \n' +
--             -- Break up requires to avoid accidentally parsing them as dependencies.
--             "jest.mock('scheduler', () => require" +
--             "('scheduler/unstable_mock'));\n\n" +
--             'For more info, visit https:--reactjs.org/link/mock-scheduler',
--         )
--       end
--     end
--   end
-- end

-- function computeThreadID(root: FiberRoot, lane: Lane | Lanes)
--   -- Interaction threads are unique per root and expiration time.
--   -- NOTE: Intentionally unsound cast. All that matters is that it's a number
--   -- and it represents a batch of work. Could make a helper function instead,
--   -- but meh this is fine for now.
--   return (lane: any) * 1000 + root.interactionThreadID
-- end

-- exports.markSpawnedWork(lane: Lane | Lanes)
--   if !enableSchedulerTracing)
--     return
--   end
--   if spawnedWorkDuringRender == nil)
--     spawnedWorkDuringRender = [lane]
--   } else {
--     spawnedWorkDuringRender.push(lane)
--   end
-- end

-- function scheduleInteractions(
--   root: FiberRoot,
--   lane: Lane | Lanes,
--   interactions: Set<Interaction>,
-- )
--   if !enableSchedulerTracing)
--     return
--   end

--   if interactions.size > 0)
--     local pendingInteractionMap = root.pendingInteractionMap
--     local pendingInteractions = pendingInteractionMap.get(lane)
--     if pendingInteractions ~= nil)
--       interactions.forEach(interaction => {
--         if !pendingInteractions.has(interaction))
--           -- Update the pending async work count for previously unscheduled interaction.
--           interaction.__count++
--         end

--         pendingInteractions.add(interaction)
--       })
--     } else {
--       pendingInteractionMap.set(lane, new Set(interactions))

--       -- Update the pending async work count for the current interactions.
--       interactions.forEach(interaction => {
--         interaction.__count++
--       })
--     end

--     local subscriber = __subscriberRef.current
--     if subscriber ~= nil)
--       local threadID = computeThreadID(root, lane)
--       subscriber.onWorkScheduled(interactions, threadID)
--     end
--   end
-- end

-- function schedulePendingInteractions(root: FiberRoot, lane: Lane | Lanes)
--   -- This is called when work is scheduled on a root.
--   -- It associates the current interactions with the newly-scheduled expiration.
--   -- They will be restored when that expiration is later committed.
--   if !enableSchedulerTracing)
--     return
--   end

--   scheduleInteractions(root, lane, __interactionsRef.current)
-- end

-- function startWorkOnPendingInteractions(root: FiberRoot, lanes: Lanes)
--   -- This is called when new work is started on a root.
--   if !enableSchedulerTracing)
--     return
--   end

--   -- Determine which interactions this batch of work currently includes, So that
--   -- we can accurately attribute time spent working on it, And so that cascading
--   -- work triggered during the render phase will be associated with it.
--   local interactions: Set<Interaction> = new Set()
--   root.pendingInteractionMap.forEach((scheduledInteractions, scheduledLane) => {
--     if includesSomeLane(lanes, scheduledLane))
--       scheduledInteractions.forEach(interaction =>
--         interactions.add(interaction),
--       )
--     end
--   })

--   -- Store the current set of interactions on the FiberRoot for a few reasons:
--   -- We can re-use it in hot functions like performConcurrentWorkOnRoot()
--   -- without having to recalculate it. We will also use it in commitWork() to
--   -- pass to any Profiler onRender() hooks. This also provides DevTools with a
--   -- way to access it when the onCommitRoot() hook is called.
--   root.memoizedInteractions = interactions

--   if interactions.size > 0)
--     local subscriber = __subscriberRef.current
--     if subscriber ~= nil)
--       local threadID = computeThreadID(root, lanes)
--       try {
--         subscriber.onWorkStarted(interactions, threadID)
--       } catch (error)
--         -- If the subscriber throws, rethrow it in a separate task
--         scheduleCallback(ImmediateSchedulerPriority, () => {
--           throw error
--         })
--       end
--     end
--   end
-- end

-- function finishPendingInteractions(root, committedLanes)
--   if !enableSchedulerTracing)
--     return
--   end

--   local remainingLanesAfterCommit = root.pendingLanes

--   local subscriber

--   try {
--     subscriber = __subscriberRef.current
--     if subscriber ~= nil and root.memoizedInteractions.size > 0)
--       -- FIXME: More than one lane can finish in a single commit.
--       local threadID = computeThreadID(root, committedLanes)
--       subscriber.onWorkStopped(root.memoizedInteractions, threadID)
--     end
--   } catch (error)
--     -- If the subscriber throws, rethrow it in a separate task
--     scheduleCallback(ImmediateSchedulerPriority, () => {
--       throw error
--     })
--   } finally {
--     -- Clear completed interactions from the pending Map.
--     -- Unless the render was suspended or cascading work was scheduled,
--     -- In which case– leave pending interactions until the subsequent render.
--     local pendingInteractionMap = root.pendingInteractionMap
--     pendingInteractionMap.forEach((scheduledInteractions, lane) => {
--       -- Only decrement the pending interaction count if we're done.
--       -- If there's still work at the current priority,
--       -- That indicates that we are waiting for suspense data.
--       if !includesSomeLane(remainingLanesAfterCommit, lane))
--         pendingInteractionMap.delete(lane)

--         scheduledInteractions.forEach(interaction => {
--           interaction.__count--

--           if subscriber ~= nil and interaction.__count == 0)
--             try {
--               subscriber.onInteractionScheduledWorkCompleted(interaction)
--             } catch (error)
--               -- If the subscriber throws, rethrow it in a separate task
--               scheduleCallback(ImmediateSchedulerPriority, () => {
--                 throw error
--               })
--             end
--           end
--         })
--       end
--     })
--   end
-- end

-- -- `act` testing API
-- --
-- -- TODO: This is mostly a copy-paste from the legacy `act`, which does not have
-- -- access to the same internals that we do here. Some trade offs in the
-- -- implementation no longer make sense.

-- local isFlushingAct = false
-- local isInsideThisAct = false

-- function shouldForceFlushFallbacksInDEV()
--   -- Never force flush in production. This function should get stripped out.
--   return _G.__DEV__ and actingUpdatesScopeDepth > 0
-- end

-- local flushMockScheduler = Scheduler.unstable_flushAllWithoutAsserting
-- local isSchedulerMocked = typeof flushMockScheduler == 'function'

-- -- Returns whether additional work was scheduled. Caller should keep flushing
-- -- until there's no work left.
-- function flushActWork(): boolean {
--   if flushMockScheduler ~= undefined)
--     local prevIsFlushing = isFlushingAct
--     isFlushingAct = true
--     try {
--       return flushMockScheduler()
--     } finally {
--       isFlushingAct = prevIsFlushing
--     end
--   } else {
--     -- No mock scheduler available. However, the only type of pending work is
--     -- passive effects, which we control. So we can flush that.
--     local prevIsFlushing = isFlushingAct
--     isFlushingAct = true
--     try {
--       local didFlushWork = false
--       while (flushPassiveEffects())
--         didFlushWork = true
--       end
--       return didFlushWork
--     } finally {
--       isFlushingAct = prevIsFlushing
--     end
--   end
-- end

-- function flushWorkAndMicroTasks(onDone: (err: ?Error) => void)
--   try {
--     flushActWork()
--     enqueueTask(() => {
--       if flushActWork())
--         flushWorkAndMicroTasks(onDone)
--       } else {
--         onDone()
--       end
--     })
--   } catch (err)
--     onDone(err)
--   end
-- end

-- -- we track the 'depth' of the act() calls with this counter,
-- -- so we can tell if any async act() calls try to run in parallel.

-- local actingUpdatesScopeDepth = 0
-- local didWarnAboutUsingActInProd = false

-- exports.act(callback: () => Thenable<mixed>): Thenable<void> {
--   if !__DEV__)
--     if didWarnAboutUsingActInProd == false)
--       didWarnAboutUsingActInProd = true
--       -- eslint-disable-next-line react-internal/no-production-logging
--       console.error(
--         'act(...) is not supported in production builds of React, and might not behave as expected.',
--       )
--     end
--   end

--   local previousActingUpdatesScopeDepth = actingUpdatesScopeDepth
--   actingUpdatesScopeDepth++

--   local previousIsSomeRendererActing = IsSomeRendererActing.current
--   local previousIsThisRendererActing = IsThisRendererActing.current
--   local previousIsInsideThisAct = isInsideThisAct
--   IsSomeRendererActing.current = true
--   IsThisRendererActing.current = true
--   isInsideThisAct = true

--   function onDone()
--     actingUpdatesScopeDepth--
--     IsSomeRendererActing.current = previousIsSomeRendererActing
--     IsThisRendererActing.current = previousIsThisRendererActing
--     isInsideThisAct = previousIsInsideThisAct
--     if _G.__DEV__)
--       if actingUpdatesScopeDepth > previousActingUpdatesScopeDepth)
--         -- if it's _less than_ previousActingUpdatesScopeDepth, then we can assume the 'other' one has warned
--         console.error(
--           'You seem to have overlapping act() calls, this is not supported. ' +
--             'Be sure to await previous act() calls before making a new one. ',
--         )
--       end
--     end
--   end

--   local result
--   try {
--     result = batchedUpdates(callback)
--   } catch (error)
--     -- on sync errors, we still want to 'cleanup' and decrement actingUpdatesScopeDepth
--     onDone()
--     throw error
--   end

--   if 
--     result ~= nil and
--     typeof result == "table" and
--     typeof result.then == 'function'
--   )
--     -- setup a boolean that gets set to true only
--     -- once this act() call is await-ed
--     local called = false
--     if _G.__DEV__)
--       if typeof Promise ~= 'undefined')
--         --eslint-disable-next-line no-undef
--         Promise.resolve()
--           .then(() => {})
--           .then(() => {
--             if called == false)
--               console.error(
--                 'You called act(async () => ...) without await. ' +
--                   'This could lead to unexpected testing behaviour, interleaving multiple act ' +
--                   'calls and mixing their scopes. You should - await act(async () => ...);',
--               )
--             end
--           })
--       end
--     end

--     -- in the async case, the returned thenable runs the callback, flushes
--     -- effects and  microtasks in a loop until flushPassiveEffects() == false,
--     -- and cleans up
--     return {
--       then(resolve, reject)
--         called = true
--         result.then(
--           () => {
--             if 
--               actingUpdatesScopeDepth > 1 or
--               (isSchedulerMocked == true and
--                 previousIsSomeRendererActing == true)
--             )
--               onDone()
--               resolve()
--               return
--             end
--             -- we're about to exit the act() scope,
--             -- now's the time to flush tasks/effects
--             flushWorkAndMicroTasks((err: ?Error) => {
--               onDone()
--               if err)
--                 reject(err)
--               } else {
--                 resolve()
--               end
--             })
--           },
--           err => {
--             onDone()
--             reject(err)
--           },
--         )
--       },
--     end
--   } else {
--     if _G.__DEV__)
--       if result ~= undefined)
--         console.error(
--           'The callback passed to act(...) function ' +
--             'must return undefined, or a Promise. You returned %s',
--           result,
--         )
--       end
--     end

--     -- flush effects until none remain, and cleanup
--     try {
--       if 
--         actingUpdatesScopeDepth == 1 and
--         (isSchedulerMocked == false or previousIsSomeRendererActing == false)
--       )
--         -- we're about to exit the act() scope,
--         -- now's the time to flush effects
--         flushActWork()
--       end
--       onDone()
--     } catch (err)
--       onDone()
--       throw err
--     end

--     -- in the sync case, the returned thenable only warns *if* await-ed
--     return {
--       then(resolve)
--         if _G.__DEV__)
--           console.error(
--             'Do not await the result of calling act(...) with sync logic, it is not a Promise.',
--           )
--         end
--         resolve()
--       },
--     end
--   end
-- end

return {}
