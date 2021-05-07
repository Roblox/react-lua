--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
*]]

local Workspace = script.Parent.Parent
local RobloxJest = require(Workspace.RobloxJest)
RobloxJest.mock(script.Parent.SchedulerHostConfig, function()
	return require(script.Parent.forks["SchedulerHostConfig.mock"])
end)

local Scheduler = require(script.Parent.Scheduler)
local HostConfig = require(script.Parent.forks["SchedulerHostConfig.mock"])

local exports = {}
for key, value in pairs(Scheduler) do
	exports[key] = value
end

exports.unstable_flushAllWithoutAsserting = HostConfig.unstable_flushAllWithoutAsserting
exports.unstable_flushNumberOfYields = HostConfig.unstable_flushNumberOfYields
exports.unstable_flushExpired = HostConfig.unstable_flushExpired
exports.unstable_clearYields = HostConfig.unstable_clearYields
exports.unstable_flushUntilNextPaint = HostConfig.unstable_flushUntilNextPaint
exports.unstable_flushAll = HostConfig.unstable_flushAll
exports.unstable_yieldValue = HostConfig.unstable_yieldValue
exports.unstable_advanceTime = HostConfig.unstable_advanceTime

return exports
