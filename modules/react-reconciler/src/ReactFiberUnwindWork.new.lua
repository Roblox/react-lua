--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message)
  error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes;
-- local type {SuspenseState} = require(script.Parent.ReactFiberSuspenseComponent.new)

-- local {resetWorkInProgressVersions as resetMutableSourceWorkInProgressVersions} = require(script.Parent.ReactMutableSource.new)
-- local {
--   ClassComponent,
--   HostRoot,
--   HostComponent,
--   HostPortal,
--   ContextProvider,
--   SuspenseComponent,
--   SuspenseListComponent,
--   OffscreenComponent,
--   LegacyHiddenComponent,
-- } = require(script.Parent.ReactWorkTags)
-- local {DidCapture, NoFlags, ShouldCapture} = require(script.Parent.ReactFiberFlags)
-- local {NoMode, ProfileMode} = require(script.Parent.ReactTypeOfMode)
-- local {
--   enableSuspenseServerRenderer,
--   enableProfilerTimer,
-- } = require(Workspace.shared/ReactFeatureFlags'

-- local {popHostContainer, popHostContext} = require(script.Parent.ReactFiberHostContext.new)
-- local {popSuspenseContext} = require(script.Parent.ReactFiberSuspenseContext.new)
-- local {resetHydrationState} = require(script.Parent.ReactFiberHydrationContext.new)
-- local {
--   isContextProvider as isLegacyContextProvider,
--   popContext as popLegacyContext,
--   popTopLevelContextObject as popTopLevelLegacyContextObject,
-- } = require(script.Parent.ReactFiberContext.new)
-- local {popProvider} = require(script.Parent.ReactFiberNewContext.new)
-- local {popRenderLanes} = require(script.Parent.ReactFiberWorkLoop.new)
-- local {transferActualDuration} = require(script.Parent.ReactProfilerTimer.new)

-- local invariant = require(Workspace.shared/invariant'

local function unwindWork(workInProgress: Fiber, renderLanes: Lanes)
  unimplemented("unwindWork")
--   switch (workInProgress.tag)
--     case ClassComponent: {
--       local Component = workInProgress.type
--       if isLegacyContextProvider(Component))
--         popLegacyContext(workInProgress)
--       end
--       local flags = workInProgress.flags
--       if flags & ShouldCapture)
--         workInProgress.flags = (flags & ~ShouldCapture) | DidCapture
--         if 
--           enableProfilerTimer and
--           (workInProgress.mode & ProfileMode) ~= NoMode
--         )
--           transferActualDuration(workInProgress)
--         end
--         return workInProgress
--       end
--       return nil
--     end
--     case HostRoot: {
--       popHostContainer(workInProgress)
--       popTopLevelLegacyContextObject(workInProgress)
--       resetMutableSourceWorkInProgressVersions()
--       local flags = workInProgress.flags
--       invariant(
--         (flags & DidCapture) == NoFlags,
--         'The root failed to unmount after an error. This is likely a bug in ' +
--           'React. Please file an issue.',
--       )
--       workInProgress.flags = (flags & ~ShouldCapture) | DidCapture
--       return workInProgress
--     end
--     case HostComponent: {
--       -- TODO: popHydrationState
--       popHostContext(workInProgress)
--       return nil
--     end
--     case SuspenseComponent: {
--       popSuspenseContext(workInProgress)
--       if enableSuspenseServerRenderer)
--         local suspenseState: nil | SuspenseState =
--           workInProgress.memoizedState
--         if suspenseState ~= nil and suspenseState.dehydrated ~= nil)
--           invariant(
--             workInProgress.alternate ~= nil,
--             'Threw in newly mounted dehydrated component. This is likely a bug in ' +
--               'React. Please file an issue.',
--           )
--           resetHydrationState()
--         end
--       end
--       local flags = workInProgress.flags
--       if flags & ShouldCapture)
--         workInProgress.flags = (flags & ~ShouldCapture) | DidCapture
--         -- Captured a suspense effect. Re-render the boundary.
--         if 
--           enableProfilerTimer and
--           (workInProgress.mode & ProfileMode) ~= NoMode
--         )
--           transferActualDuration(workInProgress)
--         end
--         return workInProgress
--       end
--       return nil
--     end
--     case SuspenseListComponent: {
--       popSuspenseContext(workInProgress)
--       -- SuspenseList doesn't actually catch anything. It should've been
--       -- caught by a nested boundary. If not, it should bubble through.
--       return nil
--     end
--     case HostPortal:
--       popHostContainer(workInProgress)
--       return nil
--     case ContextProvider:
--       popProvider(workInProgress)
--       return nil
--     case OffscreenComponent:
--     case LegacyHiddenComponent:
--       popRenderLanes(workInProgress)
--       return nil
--     default:
--       return nil
--   end
end

function unwindInterruptedWork(interruptedWork: Fiber)
  unimplemented("unwindInterruptedWork")
  -- switch (interruptedWork.tag)
  --   case ClassComponent: {
  --     local childContextTypes = interruptedWork.type.childContextTypes
  --     if childContextTypes ~= nil and childContextTypes ~= undefined)
  --       popLegacyContext(interruptedWork)
  --     end
  --     break
  --   end
  --   case HostRoot: {
  --     popHostContainer(interruptedWork)
  --     popTopLevelLegacyContextObject(interruptedWork)
  --     resetMutableSourceWorkInProgressVersions()
  --     break
  --   end
  --   case HostComponent: {
  --     popHostContext(interruptedWork)
  --     break
  --   end
  --   case HostPortal:
  --     popHostContainer(interruptedWork)
  --     break
  --   case SuspenseComponent:
  --     popSuspenseContext(interruptedWork)
  --     break
  --   case SuspenseListComponent:
  --     popSuspenseContext(interruptedWork)
  --     break
  --   case ContextProvider:
  --     popProvider(interruptedWork)
  --     break
  --   case OffscreenComponent:
  --   case LegacyHiddenComponent:
  --     popRenderLanes(interruptedWork)
  --     break
  --   default:
  --     break
  -- end
end

return {
  unwindWork = unwindWork,
  unwindInterruptedWork = unwindInterruptedWork,
}
