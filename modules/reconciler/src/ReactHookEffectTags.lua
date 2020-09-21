--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type HookEffectTag = number

return {
    NoEffect = --[[  ]] 0b000,

    -- Represents whether effect should fire.
    HasEffect = --[[ ]] 0b001,

    -- Represents the phase in which the effect (not the clean-up) fires.
    Layout = --[[    ]] 0b010,
    Passive = --[[   ]] 0b100,
}
