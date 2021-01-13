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
local inspect = require(Workspace.Shared["inspect.roblox"]).inspect

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
type FiberRoot = ReactInternalTypes.FiberRoot;
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel;
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes;
type Lane = ReactFiberLane.Lane;
local ReactCapturedValue = require(script.Parent.ReactCapturedValue)
type CapturedValue<T> = ReactCapturedValue.CapturedValue<T>
local ReactUpdateQueue = require(script.Parent["ReactUpdateQueue.new"])
type Update<T> = ReactUpdateQueue.Update<T>
local ReactTypes = require(Workspace.Shared.ReactTypes)
type Thenable<T, U> = ReactTypes.Thenable<T, U>;
type Wakeable = ReactTypes.Wakeable;
local ReactFiberSuspenseContext = require(script.Parent["ReactFiberSuspenseContext.new"])
type SuspenseContext = ReactFiberSuspenseContext.SuspenseContext

local getComponentName = require(Workspace.Shared.getComponentName)

local ReactWorkTags = require(script.Parent.ReactWorkTags)
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent

local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local DidCapture = ReactFiberFlags.DidCapture
local Incomplete = ReactFiberFlags.Incomplete
local _NoFlags = ReactFiberFlags.NoFlags
local ShouldCapture = ReactFiberFlags.ShouldCapture
local LifecycleEffectMask = ReactFiberFlags.LifecycleEffectMask
local ForceUpdateForLegacySuspense = ReactFiberFlags.ForceUpdateForLegacySuspense
local shouldCaptureSuspense = require(script.Parent["ReactFiberSuspenseComponent.new"]).shouldCaptureSuspense
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local NoMode = ReactTypeOfMode.NoMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local DebugTracingMode = ReactTypeOfMode.DebugTracingMode
local ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
-- local {
local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local createCapturedValue = require(script.Parent.ReactCapturedValue).createCapturedValue

local enqueueCapturedUpdate = ReactUpdateQueue.enqueueCapturedUpdate
local createUpdate = ReactUpdateQueue.createUpdate
local CaptureUpdate = ReactUpdateQueue.CaptureUpdate
local ForceUpdate = ReactUpdateQueue.ForceUpdate
local enqueueUpdate = ReactUpdateQueue.enqueueUpdate
-- local {markFailedErrorBoundaryForHotReloading} = require(Workspace../ReactFiberHotReloading.new'
-- local {
--   suspenseStackCursor,
--   InvisibleParentSuspenseContext,
--   hasSuspenseContext,
-- } = require(Workspace../ReactFiberSuspenseContext.new'

-- ROBLOX FIXME: these will incur a dependency cycle
-- onUncaughtError woudl be very easy to extract out, or to transplant into this file
-- local {
--   renderDidError,
--   onUncaughtError,
--   markLegacyErrorBoundaryAsFailed,
--   isAlreadyFailedLegacyErrorBoundary,
--   pingSuspendedRoot,
-- } = require(Workspace../ReactFiberWorkLoop.new'

local logCapturedError = require(script.Parent.ReactFiberErrorLogger).logCapturedError
-- local {logComponentSuspended} = require(Workspace../DebugTracing'
-- local {markComponentSuspended} = require(Workspace../SchedulingProfiler'

local SyncLane = ReactFiberLane.SyncLane
local NoTimestamp = ReactFiberLane.NoTimestamp
local includesSomeLane = ReactFiberLane.includesSomeLane
local mergeLanes = ReactFiberLane.mergeLanes
local pickArbitraryLane = ReactFiberLane.pickArbitraryLane

-- local PossiblyWeakMap = typeof WeakMap == 'function' ? WeakMap : Map

-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message)
  error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

type Set<T> = { [T]: boolean }

function createRootErrorUpdate(
  fiber: Fiber,
  errorInfo: CapturedValue<any>,
  lane: Lane
): Update<any>
  local update = createUpdate(NoTimestamp, lane)
  -- Unmount the root by rendering nil.
  update.tag = CaptureUpdate
  -- Caution: React DevTools currently depends on this property
  -- being called "element".
  update.payload = {element = nil}
  local _error = errorInfo.value
  update.callback = function()
    console.warn("onUncaughtError: " .. inspect(errorInfo))
    -- onUncaughtError(error)
    logCapturedError(fiber, errorInfo)
  end
  return update
end

function createClassErrorUpdate(
  fiber: Fiber,
  errorInfo: CapturedValue<any>,
  lane: Lane
): Update<any>
  local update = createUpdate(NoTimestamp, lane)
  update.tag = CaptureUpdate
  local getDerivedStateFromError = fiber.type.getDerivedStateFromError
  if typeof(getDerivedStateFromError) == 'function' then
    local error_ = errorInfo.value
    update.payload = function()
      logCapturedError(fiber, errorInfo)
      return getDerivedStateFromError(error_)
    end
  end

  local inst = fiber.stateNode
  if inst ~= nil and typeof(inst.componentDidCatch) == 'function' then
    update.callback = function()
      if _G.__DEV__ then
        unimplemented("markFailedErrorBoundaryForHotReloading")
        -- markFailedErrorBoundaryForHotReloading(fiber)
      end
      if typeof(getDerivedStateFromError) ~= 'function' then
        -- To preserve the preexisting retry behavior of error boundaries,
        -- we keep track of which ones already failed during this batch.
        -- This gets reset before we yield back to the browser.
        -- TODO: Warn in strict mode if getDerivedStateFromError is
        -- not defined.
        unimplemented("markLegacyErrorBoundaryAsFailed")
        -- markLegacyErrorBoundaryAsFailed(this)

        -- Only log here if componentDidCatch is the only error boundary method defined
        logCapturedError(fiber, errorInfo)
      end
      local error_ = errorInfo.value
      local stack = errorInfo.stack
      -- ROBLOX devation: used to the `this` upstream, but I *think* they mean `inst`
      inst.componentDidCatch(error_, {
        componentStack = stack or '',
      })
      if _G.__DEV__ then
        if typeof(getDerivedStateFromError) ~= 'function' then
          -- If componentDidCatch is the only error boundary method defined,
          -- then it needs to call setState to recover from errors.
          -- If no state update is scheduled then the boundary will swallow the error.
          if not includesSomeLane(fiber.lanes, SyncLane) then
            console.error(
              '%s: Error boundaries should implement getDerivedStateFromError(). ' ..
                'In that method, return a state update to display an error message or fallback UI.',
              getComponentName(fiber.type) or 'Unknown'
            )
          end
        end
      end
    end
  elseif _G.__DEV__ then
    update.callback = function()
      unimplemented("markFailedErrorBoundaryForHotReloading")
      -- markFailedErrorBoundaryForHotReloading(fiber)
    end
  end
  return update
end

function attachPingListener(root: FiberRoot, wakeable: Wakeable, lanes: Lanes)
  -- Attach a listener to the promise to "ping" the root and retry. But only if
  -- one does not already exist for the lanes we're currently rendering (which
  -- acts like a "thread ID" here).
  local _pingCache = root.pingCache
  local _threadIDs

  unimplemented("attachPingListener")
  -- if pingCache == nil then
  --   pingCache = root.pingCache = new PossiblyWeakMap()
  --   threadIDs = new Set()
  --   pingCache.set(wakeable, threadIDs)
  -- } else {
  --   threadIDs = pingCache.get(wakeable)
  --   if threadIDs == undefined)
  --     threadIDs = new Set()
  --     pingCache.set(wakeable, threadIDs)
  --   }
  -- }
  -- if !threadIDs.has(lanes))
  --   -- Memoize using the thread ID to prevent redundant listeners.
  --   threadIDs.add(lanes)
  --   local ping = pingSuspendedRoot.bind(null, root, wakeable, lanes)
  --   wakeable.then(ping, ping)
  -- }
end

function throwException(
  root: FiberRoot,
  returnFiber: Fiber,
  sourceFiber: Fiber,
  value: any,
  rootRenderLanes: Lanes
)
  -- The source fiber did not complete.
  sourceFiber.flags = bit32.bor(sourceFiber.flags, Incomplete)

  if
    value ~= nil and
    typeof(value) == 'table' and
    typeof(value.then_) == 'function'
  then
    -- This is a wakeable.
    local wakeable: Wakeable = value

    if _G.__DEV__ then
      if enableDebugTracing then
        if bit32.band(sourceFiber.mode, DebugTracingMode) then
          local _name = getComponentName(sourceFiber.type) or 'Unknown'
          unimplemented("logComponentSuspended")
          -- logComponentSuspended(name, wakeable)
        end
      end
    end

    if enableSchedulingProfiler then
      unimplemented("markComponentSuspended")
      -- markComponentSuspended(sourceFiber, wakeable)
    end

    if bit32.band(sourceFiber.mode, BlockingMode) == NoMode then
      -- Reset the memoizedState to what it was before we attempted
      -- to render it.
      local currentSource = sourceFiber.alternate
      if currentSource then
        sourceFiber.updateQueue = currentSource.updateQueue
        sourceFiber.memoizedState = currentSource.memoizedState
        sourceFiber.lanes = currentSource.lanes
      else
        sourceFiber.updateQueue = nil
        sourceFiber.memoizedState = nil
      end
    end

    console.warn("throwException: hasSuspenseContext unimplemented")
    local hasInvisibleParentBoundary
    -- local hasInvisibleParentBoundary = hasSuspenseContext(
    --   suspenseStackCursor.current,
    --   (InvisibleParentSuspenseContext: SuspenseContext),
    -- )

    -- Schedule the nearest Suspense to re-render the timed out view.
    local workInProgress = returnFiber
    repeat
      if
        workInProgress.tag == SuspenseComponent and
        shouldCaptureSuspense(workInProgress, hasInvisibleParentBoundary)
      then
        -- Found the nearest boundary.

        -- Stash the promise on the boundary fiber. If the boundary times out, we'll
        -- attach another listener to flip the boundary back to its normal state.
        local wakeables: Set<Wakeable> = workInProgress.updateQueue
        if wakeables == nil then
          local updateQueue = {}
          updateQueue[wakeable] = true
          workInProgress.updateQueue = updateQueue
        else
          wakeables[wakeable] = true
        end

        -- If the boundary is outside of blocking mode, we should *not*
        -- suspend the commit. Pretend as if the suspended component rendered
        -- nil and keep rendering. In the commit phase, we'll schedule a
        -- subsequent synchronous update to re-render the Suspense.
        --
        -- Note: It doesn't matter whether the component that suspended was
        -- inside a blocking mode tree. If the Suspense is outside of it, we
        -- should *not* suspend the commit.
        if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
          workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
          sourceFiber.flags = bit32.bor(sourceFiber.flags, ForceUpdateForLegacySuspense)

          -- We're going to commit this fiber even though it didn't complete.
          -- But we shouldn't call any lifecycle methods or callbacks. Remove
          -- all lifecycle effect tags.
          sourceFiber.flags = bit32.band(sourceFiber.flags, bit32.bnot(bit32.bor(LifecycleEffectMask, Incomplete)))

          if sourceFiber.tag == ClassComponent then
            local currentSourceFiber = sourceFiber.alternate
            if currentSourceFiber == nil then
              -- This is a new mount. Change the tag so it's not mistaken for a
              -- completed class component. For example, we should not call
              -- componentWillUnmount if it is deleted.
              sourceFiber.tag = IncompleteClassComponent
            else
              -- When we try rendering again, we should not reuse the current fiber,
              -- since it's known to be in an inconsistent state. Use a force update to
              -- prevent a bail out.
              local update = createUpdate(NoTimestamp, SyncLane)
              update.tag = ForceUpdate
              enqueueUpdate(sourceFiber, update)
            end
          end

          -- The source fiber did not complete. Mark it with Sync priority to
          -- indicate that it still has pending work.
          sourceFiber.lanes = mergeLanes(sourceFiber.lanes, SyncLane)

          -- Exit without suspending.
          return
        end

        -- Confirmed that the boundary is in a concurrent mode tree. Continue
        -- with the normal suspend path.
        --
        -- After this we'll use a set of heuristics to determine whether this
        -- render pass will run to completion or restart or "suspend" the commit.
        -- The actual logic for this is spread out in different places.
        --
        -- This first principle is that if we're going to suspend when we complete
        -- a root, then we should also restart if we get an update or ping that
        -- might unsuspend it, and vice versa. The only reason to suspend is
        -- because you think you might want to restart before committing. However,
        -- it doesn't make sense to restart only while in the period we're suspended.
        --
        -- Restarting too aggressively is also not good because it starves out any
        -- intermediate loading state. So we use heuristics to determine when.

        -- Suspense Heuristics
        --
        -- If nothing threw a Promise or all the same fallbacks are already showing,
        -- then don't suspend/restart.
        --
        -- If this is an initial render of a new tree of Suspense boundaries and
        -- those trigger a fallback, then don't suspend/restart. We want to ensure
        -- that we can show the initial loading state as quickly as possible.
        --
        -- If we hit a "Delayed" case, such as when we'd switch from content back into
        -- a fallback, then we should always suspend/restart. Transitions apply
        -- to this case. If none is defined, JND is used instead.
        --
        -- If we're already showing a fallback and it gets "retried", allowing us to show
        -- another level, but there's still an inner boundary that would show a fallback,
        -- then we suspend/restart for 500ms since the last time we showed a fallback
        -- anywhere in the tree. This effectively throttles progressive loading into a
        -- consistent train of commits. This also gives us an opportunity to restart to
        -- get to the completed state slightly earlier.
        --
        -- If there's ambiguity due to batching it's resolved in preference of:
        -- 1) "delayed", 2) "initial render", 3) "retry".
        --
        -- We want to ensure that a "busy" state doesn't get force committed. We want to
        -- ensure that new initial loading states can commit as soon as possible.

        attachPingListener(root, wakeable, rootRenderLanes)

        workInProgress.flags = bit32.bor(workInProgress.flags, ShouldCapture)
        workInProgress.lanes = rootRenderLanes

        return
      end
      -- This boundary already captured during this render. Continue to the next
      -- boundary.
      workInProgress = workInProgress.return_
    until workInProgress ~= nil
    -- No boundary was found. Fallthrough to error mode.
    -- TODO: Use invariant so the message is stripped in prod?
    value =
      (getComponentName(sourceFiber.type) or 'A React component') ..
        ' suspended while rendering, but no fallback UI was specified.\n' ..
        '\n' ..
        'Add a <Suspense fallback=...> component higher in the tree to ' ..
        'provide a loading indicator or placeholder to display.'
  end

  -- We didn't find a boundary that could handle this type of exception. Start
  -- over and traverse parent path again, this time treating the exception
  -- as an error.
  unimplemented("renderDidError")
  -- renderDidError()

  value = createCapturedValue(value, sourceFiber)
  local workInProgress = returnFiber
  repeat
    if workInProgress.tag == HostRoot then
      local errorInfo = value
      workInProgress.flags = bit32.bor(workInProgress.flags, ShouldCapture)
      local lane = pickArbitraryLane(rootRenderLanes)
      workInProgress.lanes = mergeLanes(workInProgress.lanes, lane)
      local update = createRootErrorUpdate(workInProgress, errorInfo, lane)
      enqueueCapturedUpdate(workInProgress, update)
      return
    elseif workInProgress.tag == ClassComponent then
      -- Capture and retry
      local _errorInfo = value
      local _ctor = workInProgress.type
      local _instance = workInProgress.stateNode
      unimplemented("isAlreadyFailedLegacyErrorBoundary")
      -- if
      -- 	bit32.band(workInProgress.flags, DidCapture) == NoFlags and
      -- 	(typeof(ctor.getDerivedStateFromError) == 'function' or
      -- 		(instance ~= nil and
      -- 			typeof(instance.componentDidCatch) == 'function' and
      -- 			not isAlreadyFailedLegacyErrorBoundary(instance)))
      -- then
      -- 	workInProgress.flags |= ShouldCapture
      -- 	local lane = pickArbitraryLane(rootRenderLanes)
      -- 	workInProgress.lanes = mergeLanes(workInProgress.lanes, lane)
      -- 	-- Schedule the error boundary to re-render using updated state
      -- 	local update = createClassErrorUpdate(
      -- 		workInProgress,
      -- 		errorInfo,
      -- 		lane,
      -- 	)
      -- 	enqueueCapturedUpdate(workInProgress, update)
      -- 	return
      -- end
    end
    workInProgress = workInProgress.return_
  until workInProgress ~= nil
end

return {
  throwException = throwException,
  createRootErrorUpdate = createRootErrorUpdate,
  createClassErrorUpdate = createClassErrorUpdate
}
