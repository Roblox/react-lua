-- upstream: https://github.com/facebook/react/blob/607148673b3156d051d1fed17cd49e83698dce54/packages/react/src/ReactSharedInternals.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

--[[
	ROBLOX deviation: ReactSharedInternals captures singleton state across the
	whole workspace. This file and the modules it requires were moved from React
	to untangle a cyclic workspace member dependency.

	Before:
	* ReactSharedInternals (and the 5 associated modules) lived in React
	* React had a dependency on Shared
	* Shared reached into React source to re-export ReactSharedInternals (cycle)

	After:
	* ReactSharedInternals (and the 5 associated modules) live in Shared
	* React depends on Shared
	* Shared has no intra-workspace dependencies (no cycles)
]]

-- import assign from 'object-assign';
local ReactCurrentDispatcher = require(script.ReactCurrentDispatcher)
local ReactCurrentBatchConfig = require(script.ReactCurrentBatchConfig)
local ReactCurrentOwner = require(script.ReactCurrentOwner)
local ReactDebugCurrentFrame = require(script.ReactDebugCurrentFrame)
local IsSomeRendererActing = require(script.IsSomeRendererActing)

local ReactSharedInternals = {
	ReactCurrentDispatcher = ReactCurrentDispatcher,
	ReactCurrentBatchConfig = ReactCurrentBatchConfig,
	ReactCurrentOwner = ReactCurrentOwner,
	IsSomeRendererActing = IsSomeRendererActing,
	-- deviation: This is understood by Luau as a sealed table, so we specify
	-- this key to make it safe to assign to it below
	ReactDebugCurrentFrame = {},
	-- deviation: We shouldn't have to worry about duplicate bundling here
	-- Used by renderers to avoid bundling object-assign twice in UMD bundles:
	-- assign,
}

if _G.__DEV__ then
	ReactSharedInternals.ReactDebugCurrentFrame = ReactDebugCurrentFrame
end

return ReactSharedInternals
