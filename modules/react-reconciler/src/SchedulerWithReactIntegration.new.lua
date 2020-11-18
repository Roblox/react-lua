-- upstream: https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/SchedulerWithReactIntegration.new.js
-- upstream https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/SchedulerWithReactIntegration.new.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

local Workspace = script.Parent.Parent

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
export type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel;

-- Intentionally not named imports because Rollup would use dynamic dispatch for
-- CommonJS interop named imports.
local Scheduler = require(Workspace.Scheduler)
local __interactionsRef = require(Workspace.Scheduler.tracing).__interactionsRef
-- local ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
-- local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
-- local decoupleUpdatePriorityFromScheduler = ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local invariant = require(Workspace.Shared.invariant)
-- local ReactFiberLane = require(script.Parent.ReactFiberLane)
-- local SyncLanePriority = ReactFiberLane.SyncLanePriority
-- local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
-- local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority

-- local Scheduler_runWithPriority = Scheduler.unstable_runWithPriority
-- local Scheduler_scheduleCallback = Scheduler.unstable_scheduleCallback
-- local Scheduler_cancelCallback = Scheduler.unstable_cancelCallback
-- local Scheduler_shouldYield = Scheduler.unstable_shouldYield
-- local Scheduler_requestPaint = Scheduler.unstable_requestPaint
-- local Scheduler_now = Scheduler.unstable_now
local Scheduler_getCurrentPriorityLevel = Scheduler.unstable_getCurrentPriorityLevel
local Scheduler_ImmediatePriority = Scheduler.unstable_ImmediatePriority
local Scheduler_UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
local Scheduler_NormalPriority = Scheduler.unstable_NormalPriority
local Scheduler_LowPriority = Scheduler.unstable_LowPriority
local Scheduler_IdlePriority = Scheduler.unstable_IdlePriority

-- deviation: Instead of defining these here, we require them from a small file
-- with _just_ these constant definitions; it helps us avoid a circular require
-- issue with `ReactFiberLanes`
local ReactFiberSchedulerPriorities = require(script.Parent["ReactFiberSchedulerPriorities.roblox"])
local ImmediatePriority = ReactFiberSchedulerPriorities.ImmediatePriority
local UserBlockingPriority = ReactFiberSchedulerPriorities.UserBlockingPriority
local NormalPriority = ReactFiberSchedulerPriorities.NormalPriority
local LowPriority = ReactFiberSchedulerPriorities.LowPriority
local IdlePriority = ReactFiberSchedulerPriorities.IdlePriority
local NoPriority = ReactFiberSchedulerPriorities.NoPriority

-- if enableSchedulerTracing)
--   -- Provide explicit error message when production+profiling bundle of e.g.
--   -- react-dom is used with production (non-profiling) bundle of
--   -- scheduler/tracing
--   invariant(
--     __interactionsRef ~= nil and __interactionsRef.current ~= nil,
--     'It is not supported to run the profiling version of a renderer (for ' +
--       'example, `react-dom/profiling`) without also replacing the ' +
--       '`scheduler/tracing` module with `scheduler/tracing-profiling`. Your ' +
--       'bundler might have a setting for aliasing both modules. Learn more at ' +
--       'https:--reactjs.org/link/profiling',
--   )
-- end

-- export type SchedulerCallback = (isSync: boolean) => SchedulerCallback | nil

-- type SchedulerCallbackOptions = {timeout?: number, ...}

-- local fakeCallbackNode = {}

-- export local shouldYield = Scheduler_shouldYield
-- export local requestPaint =
--   -- Fall back gracefully if we're running an older version of Scheduler.
--   Scheduler_requestPaint ~= undefined ? Scheduler_requestPaint : () => {}

-- local syncQueue: Array<SchedulerCallback> | nil = nil
-- local immediateQueueCallbackNode: mixed | nil = nil
-- local isFlushingSyncQueue: boolean = false
-- local initialTimeMs: number = Scheduler_now()

-- -- If the initial timestamp is reasonably small, use Scheduler's `now` directly.
-- -- This will be the case for modern browsers that support `performance.now`. In
-- -- older browsers, Scheduler falls back to `Date.now`, which returns a Unix
-- -- timestamp. In that case, subtract the module initialization time to simulate
-- -- the behavior of performance.now and keep our times small enough to fit
-- -- within 32 bits.
-- -- TODO: Consider lifting this into Scheduler.
-- export local now =
--   initialTimeMs < 10000 ? Scheduler_now : () => Scheduler_now() - initialTimeMs

local function getCurrentPriorityLevel(): ReactPriorityLevel
  local currentPriorityLevel = Scheduler_getCurrentPriorityLevel()
  if currentPriorityLevel == Scheduler_ImmediatePriority then
    return ImmediatePriority
  elseif currentPriorityLevel == Scheduler_UserBlockingPriority then
    return UserBlockingPriority
  elseif currentPriorityLevel == Scheduler_NormalPriority then
    return NormalPriority
  elseif currentPriorityLevel == Scheduler_LowPriority then
    return LowPriority
  elseif currentPriorityLevel == Scheduler_IdlePriority then
    return IdlePriority
  else
    invariant(false, "Unknown priority level.")
    -- deviation: FIXME: Luau needs explicit return here
    return NoPriority
  end
end

-- function reactPriorityToSchedulerPriority(reactPriorityLevel)
--   switch (reactPriorityLevel)
--     case ImmediatePriority:
--       return Scheduler_ImmediatePriority
--     case UserBlockingPriority:
--       return Scheduler_UserBlockingPriority
--     case NormalPriority:
--       return Scheduler_NormalPriority
--     case LowPriority:
--       return Scheduler_LowPriority
--     case IdlePriority:
--       return Scheduler_IdlePriority
--     default:
--       invariant(false, 'Unknown priority level.')
--   end
-- end

-- exports.runWithPriority<T>(
--   reactPriorityLevel: ReactPriorityLevel,
--   fn: () => T,
-- ): T {
--   local priorityLevel = reactPriorityToSchedulerPriority(reactPriorityLevel)
--   return Scheduler_runWithPriority(priorityLevel, fn)
-- end

-- exports.scheduleCallback(
--   reactPriorityLevel: ReactPriorityLevel,
--   callback: SchedulerCallback,
--   options: SchedulerCallbackOptions | void | nil,
-- )
--   local priorityLevel = reactPriorityToSchedulerPriority(reactPriorityLevel)
--   return Scheduler_scheduleCallback(priorityLevel, callback, options)
-- end

-- exports.scheduleSyncCallback(callback: SchedulerCallback)
--   -- Push this callback into an internal queue. We'll flush these either in
--   -- the next tick, or earlier if something calls `flushSyncCallbackQueue`.
--   if syncQueue == nil)
--     syncQueue = [callback]
--     -- Flush the queue in the next tick, at the earliest.
--     immediateQueueCallbackNode = Scheduler_scheduleCallback(
--       Scheduler_ImmediatePriority,
--       flushSyncCallbackQueueImpl,
--     )
--   } else {
--     -- Push onto existing queue. Don't need to schedule a callback because
--     -- we already scheduled one when we created the queue.
--     syncQueue.push(callback)
--   end
--   return fakeCallbackNode
-- end

-- exports.cancelCallback(callbackNode: mixed)
--   if callbackNode ~= fakeCallbackNode)
--     Scheduler_cancelCallback(callbackNode)
--   end
-- end

-- exports.flushSyncCallbackQueue(): boolean {
--   if immediateQueueCallbackNode ~= nil)
--     local node = immediateQueueCallbackNode
--     immediateQueueCallbackNode = nil
--     Scheduler_cancelCallback(node)
--   end
--   return flushSyncCallbackQueueImpl()
-- end

-- function flushSyncCallbackQueueImpl()
--   if !isFlushingSyncQueue and syncQueue ~= nil)
--     -- Prevent re-entrancy.
--     isFlushingSyncQueue = true
--     local i = 0
--     if decoupleUpdatePriorityFromScheduler)
--       local previousLanePriority = getCurrentUpdateLanePriority()
--       try {
--         local isSync = true
--         local queue = syncQueue
--         setCurrentUpdateLanePriority(SyncLanePriority)
--         runWithPriority(ImmediatePriority, () => {
--           for (; i < queue.length; i++)
--             local callback = queue[i]
--             do {
--               callback = callback(isSync)
--             } while (callback ~= nil)
--           end
--         })
--         syncQueue = nil
--       } catch (error)
--         -- If something throws, leave the remaining callbacks on the queue.
--         if syncQueue ~= nil)
--           syncQueue = syncQueue.slice(i + 1)
--         end
--         -- Resume flushing in the next tick
--         Scheduler_scheduleCallback(
--           Scheduler_ImmediatePriority,
--           flushSyncCallbackQueue,
--         )
--         throw error
--       } finally {
--         setCurrentUpdateLanePriority(previousLanePriority)
--         isFlushingSyncQueue = false
--       end
--     } else {
--       try {
--         local isSync = true
--         local queue = syncQueue
--         runWithPriority(ImmediatePriority, () => {
--           for (; i < queue.length; i++)
--             local callback = queue[i]
--             do {
--               callback = callback(isSync)
--             } while (callback ~= nil)
--           end
--         })
--         syncQueue = nil
--       } catch (error)
--         -- If something throws, leave the remaining callbacks on the queue.
--         if syncQueue ~= nil)
--           syncQueue = syncQueue.slice(i + 1)
--         end
--         -- Resume flushing in the next tick
--         Scheduler_scheduleCallback(
--           Scheduler_ImmediatePriority,
--           flushSyncCallbackQueue,
--         )
--         throw error
--       } finally {
--         isFlushingSyncQueue = false
--       end
--     end
--     return true
--   } else {
--     return false
--   end
-- end

return {
  getCurrentPriorityLevel = getCurrentPriorityLevel,
}
