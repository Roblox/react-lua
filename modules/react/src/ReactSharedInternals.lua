--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

-- import assign from 'object-assign';
local ReactCurrentDispatcher = require(script.Parent.ReactCurrentDispatcher)
local ReactCurrentBatchConfig = require(script.Parent.ReactCurrentBatchConfig)
local ReactCurrentOwner = require(script.Parent.ReactCurrentOwner)
local ReactDebugCurrentFrame = require(script.Parent.ReactDebugCurrentFrame)
local IsSomeRendererActing = require(script.Parent.IsSomeRendererActing)

local ReactSharedInternals = {
	ReactCurrentDispatcher,
	ReactCurrentBatchConfig,
	ReactCurrentOwner,
	IsSomeRendererActing,
	-- deviation: This is understood by Luau as a sealed table, so we specify
	-- this key to make it safe to assign to it below
	ReactDebugCurrentFrame = nil,
	-- deviation: We shouldn't have to worry about duplicate bundling here
	-- Used by renderers to avoid bundling object-assign twice in UMD bundles:
	-- assign,
}

if _G.__DEV__ then
	ReactSharedInternals.ReactDebugCurrentFrame = ReactDebugCurrentFrame
end

return ReactSharedInternals
