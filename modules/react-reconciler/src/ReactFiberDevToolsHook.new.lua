-- upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberDevToolsHook.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Workspace = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Workspace.Shared.console)

local exports = {}

local enableProfilerTimer = require(Workspace.Shared.ReactFeatureFlags).enableProfilerTimer

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactTypes = require(Workspace.Shared.ReactTypes)
type ReactNodeList = ReactTypes.ReactNodeList

local DidCapture = require(script.Parent.ReactFiberFlags).DidCapture

-- ROBLOX deviation: we'll inject this a different way
-- declare var __REACT_DEVTOOLS_GLOBAL_HOOK__: Object | void

local rendererID = nil
local injectedHook = nil
local hasLoggedError = false


exports.isDevToolsPresent =
  typeof(_G.__REACT_DEVTOOLS_GLOBAL_HOOK__) ~= 'nil'

exports.injectInternals = function(internals): boolean
  if typeof(_G.__REACT_DEVTOOLS_GLOBAL_HOOK__) == 'nil' then
    -- No DevTools
    return false
  end
  local hook = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__
  if hook.isDisabled then
    -- This isn't a real property on the hook, but it can be set to opt out
    -- of DevTools integration and associated warnings and logs.
    -- http://github.com/facebook/react/issues/3877
    return true
  end
  if not hook.supportsFiber then
    if _G.__DEV__ then
      console.error(
        'The installed version of React DevTools is too old and will not work ' ..
          'with the current version of React. Please update React DevTools. ' ..
          'https://reactjs.org/link/react-devtools'
      )
    end
    -- DevTools exists, even though it doesn't support Fiber.
    return true
  end
  local ok, err = pcall(function()
    rendererID = hook.inject(internals)
    -- We have successfully injected, so now it is safe to set up hooks.
    injectedHook = hook
  end)

  if not ok then
    -- Catch all errors because it is unsafe to throw during initialization.
    if _G.__DEV__ then
      console.error('React instrumentation encountered an error: %s.', err)
    end
  end
  -- DevTools exists
  return true
end

exports.onScheduleRoot = function(root: FiberRoot, children: ReactNodeList)
  if _G.__DEV__ then
    if
      injectedHook and
      typeof(injectedHook.onScheduleFiberRoot) == 'function'
    then
      local ok, err = pcall(function()
        injectedHook.onScheduleFiberRoot(rendererID, root, children)
      end)

      if not ok then
        if _G.__DEV__ and not hasLoggedError then
          hasLoggedError = true
          console.error('React instrumentation encountered an error: %s', err)
        end
      end
    end
  end
end

exports.onCommitRoot = function(
  root: FiberRoot,
  priorityLevel: ReactPriorityLevel
)
  if injectedHook and typeof(injectedHook.onCommitFiberRoot) == 'function' then
    local ok, err = pcall(function()
      local didError = bit32.band(root.current.flags, DidCapture) == DidCapture
      if enableProfilerTimer then
        injectedHook.onCommitFiberRoot(
          rendererID,
          root,
          priorityLevel,
          didError
        )
      else
        injectedHook.onCommitFiberRoot(rendererID, root, nil, didError)
      end
    end)
    if not ok then
      if _G.__DEV__ then
        if not hasLoggedError then
          hasLoggedError = true
          console.error('React instrumentation encountered an error: %s', err)
        end
      end
    end
  end
end

exports.onCommitUnmount = function(fiber: Fiber)
  if injectedHook and typeof(injectedHook.onCommitFiberUnmount) == 'function' then
    local ok, err = pcall(function()
      injectedHook.onCommitFiberUnmount(rendererID, fiber)
    end)
    if not ok then
      if _G.__DEV__ then
        if not hasLoggedError then
          hasLoggedError = true
          console.error('React instrumentation encountered an error: %s', err)
        end
      end
    end
  end
end

return exports
