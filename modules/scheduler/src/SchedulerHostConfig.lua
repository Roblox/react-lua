-- upstream: https://github.com/facebook/react/blob/00748c53e183952696157088a858352cc77b0010/packages/scheduler/src/SchedulerHostConfig.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

local makeMockSchedulerHostConfig = require(script.Parent.forks["SchedulerHostConfig.mock"])
local makeDefaultSchedulerHostConfig = require(script.Parent.forks["SchedulerHostConfig.default"])

local Workspace = script.Parent.Parent
local Timers = require(Workspace.JSPolyfill.Timers)

-- deviation: React expects this module to be replaced via a bundler. Our
-- workflow does not currently include a bundling step, so instead we expose
-- functions to create the desired kinds of host configs
local Default = makeDefaultSchedulerHostConfig(Timers, delay)

return {
	mock = makeMockSchedulerHostConfig,
	makeDefaultWithArgs = makeDefaultSchedulerHostConfig,
	Default = Default,
}