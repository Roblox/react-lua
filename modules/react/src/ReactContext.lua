-- upstream: https://github.com/facebook/react/blob/7516bdfce3f0f8c675494b5c5d0e7ae441bef1d9/packages/react/src/ReactContext.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
]]
local Workspace = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Workspace.Shared.console)

local ReactSymbols = require(Workspace.Shared.ReactSymbols)
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE


local exports = {}

exports.createContext = function(defaultValue, calculateChangedBits)
  if calculateChangedBits == nil then
    calculateChangedBits = nil
  else
    if _G.__DEV__ then
      if calculateChangedBits ~= nil and typeof(calculateChangedBits) ~= 'function' then
        console.error('createContext: Expected the optional second argument to be a ' + 'function. Instead received: %s', calculateChangedBits)
      end
    end
  end

  local context = {
    ["$$typeof"] = REACT_CONTEXT_TYPE,
    _calculateChangedBits = calculateChangedBits,
    -- As a workaround to support multiple concurrent renderers, we categorize
    -- some renderers as primary and others as secondary. We only expect
    -- there to be two concurrent renderers at most: React Native (primary) and
    -- Fabric (secondary); React DOM (primary) and React ART (secondary).
    -- Secondary renderers store their context values on separate fields.
    _currentValue = defaultValue,
    _currentValue2 = defaultValue,
    -- Used to track how many concurrent renderers this context currently
    -- supports within in a single renderer. Such as parallel server rendering.
    _threadCount = 0,
    -- These are circular
    Provider = nil,
    Consumer = nil,
    -- Luau: tables declared this way are considered sealed, so define we
    -- displayName as nil for it to be populated later
    displayName = nil,
  }
  context.Provider = {
    ["$$typeof"] = REACT_PROVIDER_TYPE,
    _context = context
  }

  local hasWarnedAboutDisplayNameOnConsumer = false

  if _G.__DEV__ then
    -- A separate object, but proxies back to the original context object for
    -- backwards compatibility. It has a different $$typeof, so we can properly
    -- warn for the incorrect usage of Context as a Consumer.
    local Consumer = {
      ["$$typeof"] = REACT_CONTEXT_TYPE,
      _context = context,
      _calculateChangedBits = context._calculateChangedBits
    }

    setmetatable(Consumer, {
      __index = function(self, key)
        -- deviation: don't implement already-deprecated things like Consumer.Provider, Consumer.Consumer, etc
        if key == "_currentValue" then
          return context._currentValue
        elseif key == "_currentValue2" then
          return context._currentValue2
        elseif key == "_threadCount" then
          return context._threadCount
        elseif key == "displayName" then
          return context.displayName
        end
        return nil
      end,
      __newindex = function(self, key, value)
        if key == "_currentValue" then
          context._currentValue = value
        elseif key == "_currentValue2" then
          context._currentValue2 = value
        elseif key == "_threadCount" then
          context._threadCount = value
        elseif key == "displayName" then
          if not hasWarnedAboutDisplayNameOnConsumer then
            console.warn('Setting `displayName` on Context.Consumer has no effect. ' ..
              "You should set it directly on the context with Context.displayName = " ..
              value .. "."
            )
            hasWarnedAboutDisplayNameOnConsumer = true
          end
        end
      end,
    })

    context.Consumer = Consumer
  else
    context.Consumer = context
  end

  if _G.__DEV__ then
    context._currentRenderer = nil
    context._currentRenderer2 = nil
  end

  return context
end

return exports
