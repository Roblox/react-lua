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

local ReactTypes = require(Workspace.Shared.ReactTypes)
type ReactContext<T> = ReactTypes.ReactContext<T>;
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
type ContextDependency = ReactInternalTypes.ContextDependency;
-- local type {StackCursor} = require(Workspace../ReactFiberStack.new'
-- local type {Lanes} = require(Workspace../ReactFiberLane'

-- local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
-- local isPrimaryRenderer = ReactFiberHostConfig.isPrimaryRenderer
-- local {createCursor, push, pop} = require(Workspace../ReactFiberStack.new'
-- local {MAX_SIGNED_31_BIT_INT} = require(Workspace../MaxInts'
-- local {
--   ContextProvider,
--   ClassComponent,
--   DehydratedFragment,
-- } = require(Workspace../ReactWorkTags'
-- local {
--   NoLanes,
--   NoTimestamp,
--   isSubsetOfLanes,
--   includesSomeLane,
--   mergeLanes,
--   pickArbitraryLane,
-- } = require(Workspace../ReactFiberLane'

-- local invariant = require(Workspace.shared/invariant'
-- local is = require(Workspace.shared/objectIs'
-- local {createUpdate, enqueueUpdate, ForceUpdate} = require(Workspace../ReactUpdateQueue.new'
-- local {markWorkInProgressReceivedUpdate} = require(Workspace../ReactFiberBeginWork.new'
-- local {enableSuspenseServerRenderer} = require(Workspace.shared/ReactFeatureFlags'

local exports = {}

-- local valueCursor: StackCursor<mixed> = createCursor(null)

-- local rendererSigil
-- if __DEV__)
--   -- Use this to detect multiple renderers using the same context
--   rendererSigil = {}
-- end

local _currentlyRenderingFiber: Fiber | nil = nil
-- FIXME (roblox): change to `ContextDependency<any>` when ContextDependency
-- type can be better aligned
local _lastContextDependency: ContextDependency | nil = nil
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

-- exports.pushProvider<T>(providerFiber: Fiber, nextValue: T): void {
--   local context: ReactContext<T> = providerFiber.type._context

--   if isPrimaryRenderer)
--     push(valueCursor, context._currentValue, providerFiber)

--     context._currentValue = nextValue
--     if __DEV__)
--       if 
--         context._currentRenderer ~= undefined and
--         context._currentRenderer ~= nil and
--         context._currentRenderer ~= rendererSigil
--       )
--         console.error(
--           'Detected multiple renderers concurrently rendering the ' +
--             'same context provider. This is currently unsupported.',
--         )
--       end
--       context._currentRenderer = rendererSigil
--     end
--   } else {
--     push(valueCursor, context._currentValue2, providerFiber)

--     context._currentValue2 = nextValue
--     if __DEV__)
--       if 
--         context._currentRenderer2 ~= undefined and
--         context._currentRenderer2 ~= nil and
--         context._currentRenderer2 ~= rendererSigil
--       )
--         console.error(
--           'Detected multiple renderers concurrently rendering the ' +
--             'same context provider. This is currently unsupported.',
--         )
--       end
--       context._currentRenderer2 = rendererSigil
--     end
--   end
-- end

-- exports.popProvider(providerFiber: Fiber): void {
--   local currentValue = valueCursor.current

--   pop(valueCursor, providerFiber)

--   local context: ReactContext<any> = providerFiber.type._context
--   if isPrimaryRenderer)
--     context._currentValue = currentValue
--   } else {
--     context._currentValue2 = currentValue
--   end
-- end

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

--     if __DEV__)
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

-- exports.prepareToReadContext(
--   workInProgress: Fiber,
--   renderLanes: Lanes,
-- ): void {
--   currentlyRenderingFiber = workInProgress
--   lastContextDependency = nil
--   lastContextWithAllBitsObserved = nil

--   local dependencies = workInProgress.dependencies
--   if dependencies ~= nil)
--     local firstContext = dependencies.firstContext
--     if firstContext ~= nil)
--       if includesSomeLane(dependencies.lanes, renderLanes))
--         -- Context list has a pending update. Mark that this fiber performed work.
--         markWorkInProgressReceivedUpdate()
--       end
--       -- Reset the work-in-progress list
--       dependencies.firstContext = nil
--     end
--   end
-- end

-- FIXME (roblox): introduce generic function signatures
-- exports.readContext<T>(
--   context: ReactContext<T>,
--   observedBits: void | number | boolean,
-- ): T {
exports.readContext = function(
  context: ReactContext<any>,
  observedBits: nil | number | boolean
): any
  unimplemented("readContext")
  return nil
  -- if _G.__DEV__ then
  --   -- This warning would fire if you read context inside a Hook like useMemo.
  --   -- Unlike the class check below, it's not enforced in production for perf.
  --   if _isDisallowedContextReadInDEV then
  --     console.error(
  --       "Context can only be read while React is rendering. " ..
  --         "In classes, you can read it in the render method or getDerivedStateFromProps. " ..
  --         "In function components, you can read it directly in the function body, but not " ..
  --         "inside Hooks like useReducer() or useMemo()."
  --     )
  --   end
  -- end

  -- if lastContextWithAllBitsObserved == context then
  --   -- Nothing to do. We already observe everything in this context.
  -- elseif observedBits == false or observedBits == 0 then
  --   -- Do not observe any updates.
  -- else
  --   local resolvedObservedBits; -- Avoid deopting on observable arguments or heterogeneous types.
  --   if
  --     typeof(observedBits) ~= "number" or
  --     observedBits == MAX_SIGNED_31_BIT_INT
  --   then
  --     -- Observe all updates.
  --     -- lastContextWithAllBitsObserved = ((context: any): ReactContext<mixed>)
  --     lastContextWithAllBitsObserved = context
  --     resolvedObservedBits = MAX_SIGNED_31_BIT_INT
  --   else
  --     resolvedObservedBits = observedBits
  --   end

  --   local contextItem = {
  --     -- context: ((context: any): ReactContext<mixed>),
  --     context = context,
  --     observedBits = resolvedObservedBits,
  --     next = nil,
  --   }

  --   if lastContextDependency == nil then
  --     invariant(
  --       currentlyRenderingFiber ~= nil,
  --       "Context can only be read while React is rendering. " ..
  --         "In classes, you can read it in the render method or getDerivedStateFromProps. " ..
  --         "In function components, you can read it directly in the function body, but not " ..
  --         "inside Hooks like useReducer() or useMemo()."
  --     )

  --     -- This is the first dependency for this component. Create a new list.
  --     lastContextDependency = contextItem
  --     currentlyRenderingFiber.dependencies = {
  --       lanes = NoLanes,
  --       firstContext = contextItem,
  --       responders = nil,
  --     }
  --   else
  --     -- Append a new context item.
  --     lastContextDependency = contextItem
  --     lastContextDependency.next = contextItem
  -- end
  -- return isPrimaryRenderer and context._currentValue or context._currentValue2
end

return exports
