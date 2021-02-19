-- upstream: https://github.com/facebook/react/blob/0cf22a56a18790ef34c71bef14f64695c0498619/packages/react/src/ReactBaseClasses.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]
local Workspace = script.Parent.Parent
local Packages = Workspace.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
-- ROBLOX: use patched console from shared
local console = require(Workspace.Shared.console)

local invariant = require(Workspace.Shared.invariant)
local ReactNoopUpdateQueue = require(script.Parent.ReactNoopUpdateQueue)
local emptyObject = {}

if _G.__DEV__ then
  Object.freeze(emptyObject)
end

--[[*
 * Base class helpers for the updating state of a component.
]]
-- FIXME: Due to metatable inheritance, this field will be accessible and true
-- on class component _instances_ as well as class component definitions; this
-- is probably not correct
local componentClassPrototype = {}
componentClassPrototype.isReactComponent = true

local componentClassMetatable = {
  __index = componentClassPrototype,
  __tostring = function(self)
    return self.__componentName
  end,
}

local Component = {}
setmetatable(Component, componentClassMetatable)
Component.__componentName = "Component"

-- deviation: Lua doesn't expose inheritance in a class-syntax way
--[[
  A method called by consumers of Roact to create a new component class.
  Components can not be extended beyond this point, with the exception of
  PureComponent.
]]
function Component:extend(name)
  assert(typeof(name) == "string", "Component class name must be a string")

  local class = {}

  for key, value in pairs(self) do
    -- Roact opts to make consumers use composition over inheritance, which
    -- lines up with React.
    -- https://reactjs.org/docs/composition-vs-inheritance.html
    if key ~= "extend" then
      class[key] = value
    end
  end

  class.__index = class
  class.__componentName = name

  function class.__ctor(props, context, updater)
    local instance = {}

    instance.props = props
    instance.context = context
    -- If a component has string refs, we will assign a different object later.
    instance.refs = emptyObject
    -- We initialize the default updater but the real one gets injected by the
    -- renderer.
    instance.updater = updater or ReactNoopUpdateQueue

    -- ROBLOX TODO: We should consider using a more idiomatic Lua approach for
    -- warning/blocking lifecycle calls during initialization. For now,
    -- ReactNoopUpdateQueue accomplishes this, but we might be able to be more
    -- thorough if we use a dummy metamethod that warns precisely on all sorts
    -- of misbehavior
    instance = setmetatable(instance, class)

    -- deviation: TODO: revisit this; make sure that we properly initialize
    -- things like `state` if its necessary, consider if we want some sort of
    -- alternate naming or syntax for the constructor equivalent
    if typeof(class.init) == 'function' then
      class.init(instance, props, context)
    end

    return instance
  end

  setmetatable(class, getmetatable(self))

  return class
end

--[[*
 * Sets a subset of the state. Always use this to mutate
 * state. You should treat `self.state` as immutable.
 *
 * There is no guarantee that `self.state` will be immediately updated, so
 * accessing `self.state` after calling this method may return the old value.
 *
 * There is no guarantee that calls to `setState` will run synchronously,
 * as they may eventually be batched together.  You can provide an optional
 * callback that will be executed when the call to setState is actually
 * completed.
 *
 * When a function is provided to setState, it will be called at some point in
 * the future (not synchronously). It will be called with the up to date
 * component arguments (state, props, context). These values can be different
 * from self.* because your function may be called after receiveProps but before
 * shouldComponentUpdate, and this new state, props, and context will not yet be
 * assigned to self.
 *
 * @param {object|function} partialState Next partial state or function to
 *        produce next partial state to be merged with current state.
 * @param {?function} callback Called after state is updated.
 * @final
 * @protected
 ]]
function Component:setState(partialState, callback)
  invariant(
    typeof(partialState) == 'table' or typeof(partialState) == 'function' or partialState == nil,
    'setState(...): takes an object of state variables to update or a ' .. 'function which returns an object of state variables.'
  )
  self.updater.enqueueSetState(self, partialState, callback, 'setState')
end

--[[*
 * Forces an update. This should only be invoked when it is known with
 * certainty that we are **not** in a DOM transaction.
 *
 * You may want to call this when you know that some deeper aspect of the
 * component's state has changed but `setState` was not called.
 *
 * This will not invoke `shouldComponentUpdate`, but it will invoke
 * `componentWillUpdate` and `componentDidUpdate`.
 *
 * @param {?function} callback Called after update is complete.
 * @final
 * @protected
 ]]


function Component:forceUpdate(callback)
  self.updater.enqueueForceUpdate(self, callback, 'forceUpdate')
end
--[[*
 * Deprecated APIs. These APIs used to exist on classic React classes but since
 * we would like to deprecate them, we're not going to move them over to this
 * modern base class. Instead, we define a getter that warns if it's accessed.
 ]]


if _G.__DEV__ then
  local deprecatedAPIs = {
    isMounted = {'isMounted', 'Instead, make sure to clean up subscriptions and pending requests in ' .. 'componentWillUnmount to prevent memory leaks.'},
    replaceState = {'replaceState', 'Refactor your code to use setState instead (see ' .. 'https:--github.com/facebook/react/issues/3236).'}
  }

  local defineDeprecationWarning = function (methodName, info)
    Component[methodName] =
      function()
        console.warn('%s(...) is deprecated in plain JavaScript React classes. %s', info[1], info[2])
        return nil
      end
  end

  for fnName, _ in pairs(deprecatedAPIs) do
    if deprecatedAPIs[fnName] ~= nil then
      defineDeprecationWarning(fnName, deprecatedAPIs[fnName])
    end
  end
end

--[[*
 * Convenience component with default shallow equality check for sCU.
 ]]
-- deviation: work within the `extend` framework defined above to emulate JS's
-- class inheritance
local PureComponent = Component:extend("PureComponent")

-- When extend()ing a component, you don't get an extend method.
-- This is to promote composition over inheritance.
-- PureComponent is an exception to this rule.
PureComponent.extend = Component.extend

-- deviation: We copy members directly from the Component prototype above; we
-- don't need to redefine the constructor or do dummy function trickery to apply
-- it without jumping around
local pureComponentClassPrototype = {}
Object.assign(pureComponentClassPrototype, componentClassPrototype)
pureComponentClassPrototype.isPureReactComponent = true

-- ROBLOX: FIXME: we should clean this up and align the implementations of
-- Component and PureComponent more clearly and explicitly
setmetatable(PureComponent, {
  __index = pureComponentClassPrototype
})

return {
  Component = Component,
  PureComponent = PureComponent,
}
