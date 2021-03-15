-- upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberErrorDialog.js
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

-- This module is forked in different environments.
-- By default, return `true` to log errors to the console.
-- Forks can return `false` if this isn't desirable.
local exports = {}

exports.showErrorDialog =  function(
  boundary,
  errorInfo
): boolean
  -- ROBLOX TODO: we may replace this with something that sends telemetry
  console.error("!!!! ROBLOX This is where we would report to crash telemetry: " .. tostring(errorInfo.value))
  return true
end

return exports
