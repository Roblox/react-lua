-- upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react-reconciler/src/ReactMutableSource.js
-- [[
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
-- ]]

local Packages = script.Parent.Parent
local ReactTypes = require(Packages.Shared)
type MutableSourceGetVersionFn = ReactTypes.MutableSourceGetVersionFn
type MutableSource<T> = ReactTypes.MutableSource<T>

-- ROBLOX TODO: Luau function generics
-- local function createMutableSource<Source: $NonMaybeType<mixed>> (
--     source: Source,
--     getVersion: MutableSourceGetVersionFn
--   ): MutableSource<Source>
local function createMutableSource (
  source: any,
  getVersion: MutableSourceGetVersionFn
): MutableSource<any>
  local mutableSource: MutableSource<any> = {
    _getVersion = getVersion,
    _source = source,
    _workInProgressVersionPrimary = nil,
    _workInProgressVersionSecondary = nil,
  }

  if _G.__DEV__ then
    mutableSource._currentPrimaryRenderer = nil
    mutableSource._currentSecondaryRenderer = nil
  end

  return mutableSource
end

return createMutableSource