-- upstream: https://github.com/facebook/react/blob/37cb732c59863297e48f69ac1f6e2ba1aa1886f0/packages/react-reconciler/src/ReactFiberFlags.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Workspace = script.Parent.Parent

local ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
local enableCreateEventHandleAPI = ReactFeatureFlags.enableCreateEventHandleAPI

export type Flags = number

local exports = {}

-- // Don't change these two values. They're used by React Dev Tools.
exports.NoFlags = --[[                      ]] 0b0000000000000000000
exports.PerformedWork = --[[                ]] 0b0000000000000000001

-- // You can change the rest (and add more).
exports.Placement = --[[                    ]] 0b0000000000000000010
exports.Update = --[[                       ]] 0b0000000000000000100
exports.PlacementAndUpdate = --[[           ]] 0b0000000000000000110
exports.Deletion = --[[                     ]] 0b0000000000000001000
exports.ContentReset = --[[                 ]] 0b0000000000000010000
exports.Callback = --[[                     ]] 0b0000000000000100000
exports.DidCapture = --[[                   ]] 0b0000000000001000000
exports.Ref = --[[                          ]] 0b0000000000010000000
exports.Snapshot = --[[                     ]] 0b0000000000100000000
exports.Passive = --[[                      ]] 0b0000000001000000000
exports.Hydrating = --[[                    ]] 0b0000000010000000000
exports.HydratingAndUpdate = --[[           ]] 0b0000000010000000100
exports.Visibility = --[[                   ]] 0b0000000100000000000

exports.LifecycleEffectMask = bit32.bor(
	exports.Passive, exports.Update,
	exports.Callback, exports.Ref, exports.Snapshot
)

-- // Union of all commit flags (flags with the lifetime of a particular commit)
exports.HostEffectMask = --[[               ]] 0b0000000111111111111

-- // These are not really side effects, but we still reuse this field.
exports.Incomplete = --[[                   ]] 0b0000001000000000000
exports.ShouldCapture = --[[                ]] 0b0000010000000000000
-- // TODO (effects) Remove this bit once the new reconciler is synced to the old.
exports.PassiveUnmountPendingDev = --[[     ]] 0b0000100000000000000
exports.ForceUpdateForLegacySuspense = --[[ ]] 0b0001000000000000000

-- // Static tags describe aspects of a fiber that are not specific to a render,
-- // e.g. a fiber uses a passive effect (even if there are no updates on this particular render).
-- // This enables us to defer more work in the unmount case,
-- // since we can defer traversing the tree during layout to look for Passive effects,
-- // and instead rely on the static flag as a signal that there may be cleanup work.
exports.PassiveStatic = --[[                ]] 0b0010000000000000000

-- // These flags allow us to traverse to fibers that have effects on mount
-- // without traversing the entire tree after every commit for
-- // double invoking
exports.MountLayoutDev = --[[               ]] 0b0100000000000000000
exports.MountPassiveDev = --[[              ]] 0b1000000000000000000

-- // Groups of flags that are used in the commit phase to skip over trees that
-- // don't contain effects, by checking subtreeFlags.

exports.BeforeMutationMask = bit32.bor(
	exports.Snapshot,
	enableCreateEventHandleAPI and
		-- // createEventHandle needs to visit deleted and hidden trees to
		-- // fire beforeblur
		-- // TODO: Only need to visit Deletions during BeforeMutation phase if an
		-- // element is focused.
		bit32.bor(exports.Deletion, exports.Visibility)
		or 0
)

exports.MutationMask = bit32.bor(
	exports.Placement, exports.Update, exports.Deletion,
	exports.ContentReset, exports.Ref, exports.Hydrating, exports.Visibility
)
exports.LayoutMask = bit32.bor(exports.Update, exports.Callback, exports.Ref)
exports.PassiveMask = bit32.bor(exports.Passive, exports.Deletion)

-- // Union of tags that don't get reset on clones.
-- // This allows certain concepts to persist without recalculting them,
-- // e.g. whether a subtree contains passive effects or portals.
exports.StaticMask = exports.PassiveStatic

return exports
