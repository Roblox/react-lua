-- upstream: https://github.com/facebook/react/blob/1eaafc9ade46ba708b2361b324dd907d019e3939/packages/react-reconciler/src/ReactFiberNewContext.new.js
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

local Workspace = script.Parent.Parent
local Packages = Workspace.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local Number = LuauPolyfill.Number

-- ROBLOX: use patched console from shared
local console = require(Workspace.Shared.console)

local ReactTypes = require(Workspace.Shared.ReactTypes)
type ReactContext<T> = ReactTypes.ReactContext<T>
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type ContextDependency = ReactInternalTypes.ContextDependency

local ReactFiberStack = require(script.Parent["ReactFiberStack.new"])
type StackCursor<T> = ReactFiberStack.StackCursor<T>

local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
local isPrimaryRenderer = ReactFiberHostConfig.isPrimaryRenderer
local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop
-- local {MAX_SIGNED_31_BIT_INT} = require(Workspace../MaxInts'
-- local {
--   ContextProvider,
--   ClassComponent,
--   DehydratedFragment,
-- } = require(Workspace../ReactWorkTags'
local includesSomeLane = require(script.Parent.ReactFiberLane).includesSomeLane
-- local {
--   NoLanes,
--   NoTimestamp,
--   isSubsetOfLanes,
--   includesSomeLane,
--   mergeLanes,
--   pickArbitraryLane,
-- } = require(Workspace../ReactFiberLane'
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
local NoLanes = ReactFiberLane.NoLanes

local invariant = require(Workspace.Shared.invariant)
-- local is = require(Workspace.shared/objectIs'
-- local {createUpdate, enqueueUpdate, ForceUpdate} = require(Workspace../ReactUpdateQueue.new'
-- local markWorkInProgressReceivedUpdate = require(script.Parent["ReactFiberBeginWork.new"]).markWorkInProgressReceivedUpdate
-- local {enableSuspenseServerRenderer} = require(Workspace.shared/ReactFeatureFlags'

local exports = {}

local valueCursor: StackCursor<any> = createCursor(nil)

local rendererSigil
if _G.__DEV__ then
  -- Use this to detect multiple renderers using the same context
  rendererSigil = {}
end

local _currentlyRenderingFiber = nil
-- FIXME (roblox): change to `ContextDependency<any>` when ContextDependency
-- type can be better aligned
local _lastContextDependency = nil
local _lastContextWithAllBitsObserved: ReactContext<any> | nil = nil

local _isDisallowedContextReadInDEV: boolean = false

exports.resetContextDependencies = function()
  -- This is called right before React yields execution, to ensure `readContext`
  -- cannot be called outside the render phase.
  _currentlyRenderingFiber = nil
  _lastContextDependency = nil
  _lastContextWithAllBitsObserved = nil
  if _G.__DEV__ then
    _isDisallowedContextReadInDEV = false
  end
end

exports.enterDisallowedContextReadInDEV = function()
  if _G.__DEV__ then
    _isDisallowedContextReadInDEV = true
  end
end

exports.exitDisallowedContextReadInDEV = function()
  if _G.__DEV__ then
    _isDisallowedContextReadInDEV = false
  end
end

exports.pushProvider = function(providerFiber: Fiber, nextValue)
  local context: ReactContext<any> = providerFiber.type._context

  if isPrimaryRenderer then
    push(valueCursor, context._currentValue, providerFiber)

    context._currentValue = nextValue
    if _G.__DEV__ then
      if
        context._currentRenderer ~= nil and
        context._currentRenderer ~= rendererSigil
      then
        console.error(
          'Detected multiple renderers concurrently rendering the ' ..
            'same context provider. This is currently unsupported.'
        )
      end
      context._currentRenderer = rendererSigil
    end
  else
    push(valueCursor, context._currentValue2, providerFiber)

    context._currentValue2 = nextValue
    if _G.__DEV__ then
      if
        context._currentRenderer2 ~= nil and
        context._currentRenderer2 ~= rendererSigil
      then
        console.error(
          'Detected multiple renderers concurrently rendering the ' ..
            'same context provider. This is currently unsupported.'
        )
      end
      context._currentRenderer2 = rendererSigil
    end
  end
end

exports.popProvider = function(providerFiber: Fiber)
  local currentValue = valueCursor.current

  pop(valueCursor, providerFiber)

  local context: ReactContext<any> = providerFiber.type._context
  if isPrimaryRenderer then
    context._currentValue = currentValue
  else
    context._currentValue2 = currentValue
  end
end

-- exports.calculateChangedBits<T>(
--   context: ReactContext<T>,
--   newValue: T,
--   oldValue: T,
-- )
--   if is(oldValue, newValue))
--     -- No change
--     return 0
--   } else {
--     local changedBits =
--       typeof context._calculateChangedBits == 'function'
--         ? context._calculateChangedBits(oldValue, newValue)
--         : MAX_SIGNED_31_BIT_INT

--     if _G.__DEV__ then
--       if (changedBits & MAX_SIGNED_31_BIT_INT) ~= changedBits)
--         console.error(
--           'calculateChangedBits: Expected the return value to be a ' +
--             '31-bit integer. Instead received: %s',
--           changedBits,
--         )
--       end
--     end
--     return changedBits | 0
--   end
-- end

-- exports.scheduleWorkOnParentPath(
--   parent: Fiber | nil,
--   renderLanes: Lanes,
-- )
--   -- Update the child lanes of all the ancestors, including the alternates.
--   local node = parent
--   while (node ~= nil)
--     local alternate = node.alternate
--     if !isSubsetOfLanes(node.childLanes, renderLanes))
--       node.childLanes = mergeLanes(node.childLanes, renderLanes)
--       if alternate ~= nil)
--         alternate.childLanes = mergeLanes(alternate.childLanes, renderLanes)
--       end
--     } else if
--       alternate ~= nil and
--       !isSubsetOfLanes(alternate.childLanes, renderLanes)
--     )
--       alternate.childLanes = mergeLanes(alternate.childLanes, renderLanes)
--     } else {
--       -- Neither alternate was updated, which means the rest of the
--       -- ancestor path already has sufficient priority.
--       break
--     end
--     node = node.return
--   end
-- end

-- exports.propagateContextChange(
--   workInProgress: Fiber,
--   context: ReactContext<mixed>,
--   changedBits: number,
--   renderLanes: Lanes,
-- ): void {
--   local fiber = workInProgress.child
--   if fiber ~= nil)
--     -- Set the return pointer of the child to the work-in-progress fiber.
--     fiber.return = workInProgress
--   end
--   while (fiber ~= nil)
--     local nextFiber

--     -- Visit this fiber.
--     local list = fiber.dependencies
--     if list ~= nil)
--       nextFiber = fiber.child

--       local dependency = list.firstContext
--       while (dependency ~= nil)
--         -- Check if the context matches.
--         if
--           dependency.context == context and
--           (dependency.observedBits & changedBits) ~= 0
--         )
--           -- Match! Schedule an update on this fiber.

--           if fiber.tag == ClassComponent)
--             -- Schedule a force update on the work-in-progress.
--             local update = createUpdate(
--               NoTimestamp,
--               pickArbitraryLane(renderLanes),
--             )
--             update.tag = ForceUpdate
--             -- TODO: Because we don't have a work-in-progress, this will add the
--             -- update to the current fiber, too, which means it will persist even if
--             -- this render is thrown away. Since it's a race condition, not sure it's
--             -- worth fixing.
--             enqueueUpdate(fiber, update)
--           end
--           fiber.lanes = mergeLanes(fiber.lanes, renderLanes)
--           local alternate = fiber.alternate
--           if alternate ~= nil)
--             alternate.lanes = mergeLanes(alternate.lanes, renderLanes)
--           end
--           scheduleWorkOnParentPath(fiber.return, renderLanes)

--           -- Mark the updated lanes on the list, too.
--           list.lanes = mergeLanes(list.lanes, renderLanes)

--           -- Since we already found a match, we can stop traversing the
--           -- dependency list.
--           break
--         end
--         dependency = dependency.next
--       end
--     } else if fiber.tag == ContextProvider)
--       -- Don't scan deeper if this is a matching provider
--       nextFiber = fiber.type == workInProgress.type ? nil : fiber.child
--     } else if
--       enableSuspenseServerRenderer and
--       fiber.tag == DehydratedFragment
--     )
--       -- If a dehydrated suspense boundary is in this subtree, we don't know
--       -- if it will have any context consumers in it. The best we can do is
--       -- mark it as having updates.
--       local parentSuspense = fiber.return
--       invariant(
--         parentSuspense ~= nil,
--         'We just came from a parent so we must have had a parent. This is a bug in React.',
--       )
--       parentSuspense.lanes = mergeLanes(parentSuspense.lanes, renderLanes)
--       local alternate = parentSuspense.alternate
--       if alternate ~= nil)
--         alternate.lanes = mergeLanes(alternate.lanes, renderLanes)
--       end
--       -- This is intentionally passing this fiber as the parent
--       -- because we want to schedule this fiber as having work
--       -- on its children. We'll use the childLanes on
--       -- this fiber to indicate that a context has changed.
--       scheduleWorkOnParentPath(parentSuspense, renderLanes)
--       nextFiber = fiber.sibling
--     } else {
--       -- Traverse down.
--       nextFiber = fiber.child
--     end

--     if nextFiber ~= nil)
--       -- Set the return pointer of the child to the work-in-progress fiber.
--       nextFiber.return = fiber
--     } else {
--       -- No child. Traverse to next sibling.
--       nextFiber = fiber
--       while (nextFiber ~= nil)
--         if nextFiber == workInProgress)
--           -- We're back to the root of this subtree. Exit.
--           nextFiber = nil
--           break
--         end
--         local sibling = nextFiber.sibling
--         if sibling ~= nil)
--           -- Set the return pointer of the sibling to the work-in-progress fiber.
--           sibling.return = nextFiber.return
--           nextFiber = sibling
--           break
--         end
--         -- No more siblings. Traverse up.
--         nextFiber = nextFiber.return
--       end
--     end
--     fiber = nextFiber
--   end
-- end

exports.prepareToReadContext = function(
  workInProgress: Fiber,
  renderLanes: Lanes
)
  _currentlyRenderingFiber = workInProgress
  _lastContextDependency = nil
  _lastContextWithAllBitsObserved = nil

  local dependencies = workInProgress.dependencies
  if dependencies ~= nil then
    local firstContext = dependencies.firstContext
    if firstContext ~= nil then
      if includesSomeLane(dependencies.lanes, renderLanes) then
        -- Context list has a pending update. Mark that this fiber performed work.
        unimplemented("cycle markWorkInProgressReceivedUpdate")
      end
      -- Reset the work-in-progress list
      dependencies.firstContext = nil
    end
  end
end

-- FIXME (roblox): introduce generic function signatures
-- exports.readContext<T>(
--   context: ReactContext<T>,
--   observedBits: void | number | boolean,
-- ): T {
exports.readContext = function(
  context: ReactContext<any>,
  observedBits: nil | number | boolean
): any
  if _G.__DEV__ then
    -- This warning would fire if you read context inside a Hook like useMemo.
    -- Unlike the class check below, it's not enforced in production for perf.
    if _isDisallowedContextReadInDEV then
      console.error(
        "Context can only be read while React is rendering. " ..
          "In classes, you can read it in the render method or getDerivedStateFromProps. " ..
          "In function components, you can read it directly in the function body, but not " ..
          "inside Hooks like useReducer() or useMemo()."
      )
    end
  end

  if _lastContextWithAllBitsObserved == context then
    -- Nothing to do. We already observe everything in this context.
  elseif observedBits == false or observedBits == 0 then
    -- Do not observe any updates.
  else
    local resolvedObservedBits -- Avoid deopting on observable arguments or heterogeneous types.
    if
      typeof(observedBits) ~= "number" or
      observedBits == Number.MAX_SAFE_INTEGER
    then
      -- Observe all updates.
      -- lastContextWithAllBitsObserved = ((context: any): ReactContext<mixed>)
      _lastContextWithAllBitsObserved = context
      resolvedObservedBits = Number.MAX_SAFE_INTEGER
    else
      resolvedObservedBits = observedBits
    end

    local contextItem = {
      -- context: ((context: any): ReactContext<mixed>),
      context = context,
      observedBits = resolvedObservedBits,
      next = nil,
    }

    if _lastContextDependency == nil then
      invariant(
        _currentlyRenderingFiber ~= nil,
        "Context can only be read while React is rendering. " ..
          "In classes, you can read it in the render method or getDerivedStateFromProps. " ..
          "In function components, you can read it directly in the function body, but not " ..
          "inside Hooks like useReducer() or useMemo()."
      )

      -- This is the first dependency for this component. Create a new list.
      _lastContextDependency = contextItem
      _currentlyRenderingFiber.dependencies = {
        lanes = NoLanes,
        firstContext = contextItem,
        responders = nil,
      }
    else
      -- Append a new context item.
      _lastContextDependency = contextItem
      _lastContextDependency.next = contextItem
    end
  end
  return isPrimaryRenderer and context._currentValue or context._currentValue2
end

return exports
