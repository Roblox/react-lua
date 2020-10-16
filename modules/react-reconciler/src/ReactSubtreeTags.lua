--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type SubtreeTag = number

return {
    NoEffect = --[[        ]] 0b00000,
    BeforeMutation = --[[  ]] 0b00001,
    Mutation = --[[        ]] 0b00010,
    Layout = --[[          ]] 0b00100,
    Passive = --[[         ]] 0b01000,
    PassiveStatic = --[[   ]] 0b10000,
}
