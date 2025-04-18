--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/SchedulingProfiler.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local exports = {}
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local WeakMap = LuauPolyfill.WeakMap
type WeakMap<K, V> = LuauPolyfill.WeakMap<K, V>

local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lane = ReactFiberLane.Lane
type Lanes = ReactFiberLane.Lanes

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot

local ReactTypes = require(Packages.Shared)
type Wakeable = ReactTypes.Wakeable

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local ReactVersion = require(Packages.Shared).ReactVersion
local getComponentName = require(Packages.Shared).getComponentName

-- /**
--  * If performance exists and supports the subset of the User Timing API that we
--  * require.
--  */
local supportsUserTiming = _G.performance ~= nil
local performance = _G.performance
	or {
		mark = function(str)
			debug.profilebegin(str)
			debug.profileend()
		end,
	}

function formatLanes(laneOrLanes: Lane | Lanes): string
	return tostring(laneOrLanes)
end

-- ROBLOX deviation START: profiler event callback
export type ProfilerEvent = number
export type ProfilerEventCallback = (type: ProfilerEvent, root: FiberRoot?) -> ()
local profilerEventCallback: ProfilerEventCallback? = nil
local profilerEventTypes = {
	CommitStart = 0,
	CommitStop = 1,
	LayoutEffectsStart = 2,
	LayoutEffectsStop = 3,
	PassiveEffectsStart = 4,
	PassiveEffectsStop = 5,
	RenderStart = 6,
	RenderYield = 7,
	RenderStop = 8,
} :: { [string]: ProfilerEvent }
-- ROBLOX deviation END

-- Create a mark on React initialization
if enableSchedulingProfiler then
	if supportsUserTiming then
		performance.mark("--react-init-" .. tostring(ReactVersion))
	end
end

exports.markCommitStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--commit-start-" .. formatLanes(lanes))
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.CommitStart)
		end
	end
end

exports.markCommitStopped = function(root: FiberRoot): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--commit-stop")
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.CommitStop, root)
		end
	end
end

-- ROBLOX deviation: we use our custom Map
-- local PossiblyWeakMap = typeof WeakMap === 'function' ? WeakMap : Map

-- $FlowFixMe: Flow cannot handle polymorphic WeakMaps
local wakeableIDs: WeakMap<Wakeable, number> = WeakMap.new()
local wakeableID: number = 0
function getWakeableID(wakeable: Wakeable): number
	if not wakeableIDs:has(wakeable) then
		wakeableIDs:set(wakeable, wakeableID)
		wakeableID += 1
	end
	return wakeableIDs:get(wakeable)
end

exports.markComponentSuspended = function(fiber: Fiber, wakeable: Wakeable): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			local id = getWakeableID(wakeable)
			local componentName = getComponentName(fiber.type) or "Unknown"
			-- TODO Add component stack id
			performance.mark(
				"--suspense-suspend-" .. tostring(id) .. "-" .. componentName
			)
			wakeable:andThen(function()
				performance.mark(
					"--suspense-resolved-" .. tostring(id) .. "-" .. componentName
				)
			end, function()
				performance.mark(
					"--suspense-rejected-" .. tostring(id) .. "-" .. componentName
				)
			end)
		end
	end
end

exports.markLayoutEffectsStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--layout-effects-start-" .. formatLanes(lanes))
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.LayoutEffectsStart)
		end
	end
end

exports.markLayoutEffectsStopped = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--layout-effects-stop")
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.LayoutEffectsStop)
		end
	end
end

exports.markPassiveEffectsStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--passive-effects-start-" .. formatLanes(lanes))
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.PassiveEffectsStart)
		end
	end
end

exports.markPassiveEffectsStopped = function(root: FiberRoot): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--passive-effects-stop")
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.PassiveEffectsStop, root)
		end
	end
end

exports.markRenderStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--render-start-" .. formatLanes(lanes))
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.RenderStart)
		end
	end
end

exports.markRenderYielded = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--render-yield")
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.RenderYield)
		end
	end
end

exports.markRenderStopped = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--render-stop")
		end
		-- ROBLOX deviation: profiler event callback
		if profilerEventCallback then
			profilerEventCallback(profilerEventTypes.RenderStop)
		end
	end
end

exports.markRenderScheduled = function(lane: Lane): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--schedule-render-" .. formatLanes(lane))
		end
	end
end

exports.markForceUpdateScheduled = function(fiber: Fiber, lane: Lane): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			local componentName = getComponentName(fiber.type) or "Unknown"
			-- TODO Add component stack id
			performance.mark(
				"--schedule-forced-update-" .. formatLanes(lane) .. "-" .. componentName
			)
		end
	end
end

exports.markStateUpdateScheduled = function(fiber: Fiber, lane: Lane): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			local componentName = getComponentName(fiber.type) or "Unknown"
			-- TODO Add component stack id
			performance.mark(
				"--schedule-state-update-" .. formatLanes(lane) .. "-" .. componentName
			)
		end
	end
end

-- ROBLOX deviation START: profiler event callback
exports.profilerEventTypes = profilerEventTypes

exports.registerProfilerEventCallback = function(callback: ProfilerEventCallback)
	if profilerEventCallback then
		warn("SchedulingProfiler: Another event callback was already registered.")
	end
	profilerEventCallback = callback
end
-- ROBLOX deviation END

return exports
