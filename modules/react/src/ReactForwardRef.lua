-- upstream: https://github.com/facebook/react/blob/41694201988c5e651f0c3bc69921d5c9717be88b/packages/react/src/ReactForwardRef.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
*]]

local Workspace = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Workspace.Shared.console)

local ReactSymbols = require(Workspace.Shared.ReactSymbols)
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE

-- deviation: strip flow types
local exports = {}
exports.forwardRef = function(render)
  if _G.__DEV__ then
    -- deviation: instead of checking for nil, check for the case where we were
    -- given a table (which we can index to see if it's the Memo type)
    if typeof(render) == "table" and render["$$typeof"] == REACT_MEMO_TYPE then
      console.error(
        'forwardRef requires a render function but received a `memo` ' ..
          'component. Instead of forwardRef(memo(...)), use ' ..
          'memo(forwardRef(...)).'
      )
    elseif typeof(render) ~= 'function' then
      console.error(
        'forwardRef requires a render function but was given %s.',
        typeof(render)
      )
    else
      -- deviation: in Luau, we don't have a way to check how many arguments a
      -- function takes at runtime

      -- if render.length !== 0 && render.length !== 2 then
      --   console.error(
      --     'forwardRef render functions accept exactly two parameters: props and ref. %s',
      --     render.length === 1
      --       ? 'Did you forget to use the ref parameter?'
      --       : 'Any additional parameter will be undefined.',
      --   );
      -- }
    end

    -- deviation: in Luau, functions cannot have fields; for now, we don't
    -- support defaultProps and propTypes on function components anyways, so
    -- this check can safely be a no-op

    -- if render ~= null then
    --   if (render.defaultProps != null || render.propTypes != null) {
    --     console.error(
    --       'forwardRef render functions do not support propTypes or defaultProps. ' +
    --         'Did you accidentally pass a React component?',
    --     );
    --   }
    -- }
  end

  local elementType = {
    ["$$typeof"] = REACT_FORWARD_REF_TYPE,
    render = render,
  }
  if _G.__DEV__ then
    local ownName
    -- deviation: use metatables to approximate Object.defineProperty logic
    setmetatable(elementType, {
      __index = function(self, key)
        if key == "displayName" then
          return ownName
        end
        return nil
      end,
      __newindex = function(self, key, value)
        if key == "displayName" then
          ownName = value
          -- deviation: render is a function and cannot have properties
          -- if (render.displayName == null) {
          --   render.displayName = name;
          -- }
        end
      end,
    })
  end
  return elementType
end

return exports
