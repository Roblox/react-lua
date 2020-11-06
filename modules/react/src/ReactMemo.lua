-- upstream: https://github.com/facebook/react/blob/41694201988c5e651f0c3bc69921d5c9717be88b/packages/react/src/ReactMemo.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

local Workspace = script.Parent.Parent
local REACT_MEMO_TYPE = require(Workspace.Shared.ReactSymbols).REACT_MEMO_TYPE
local isValidElementType = require(Workspace.Shared.isValidElementType)
local console = require(Workspace.RobloxJSPolyfill.console)

local exports = {}

exports.memo = function(_type, compare)
  if _G.__DEV__  then
    if not isValidElementType(type) then
      console.error('memo: The first argument must be a component. Instead ' .. 'received: ', tostring(type))
    end
  end

  local elementType = {
    ["$$typeof"] = REACT_MEMO_TYPE,
    type = _type,
    compare = compare or nil
  }

  if _G.__DEV__ then
    local ownName = nil
    elementType.displayName = function(...)
      if #{...} == 0 then
        return ownName
      end

      local name = ({...})[1]
      ownName = name

      if _type.displayName == nil then
        _type.displayName = name
      end

      return nil
    end
  end

  return elementType
end

return exports
