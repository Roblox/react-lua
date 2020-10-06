--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * Keeps track of the current owner.
 *
 * The current owner is the component who should own any components that are
 * currently being constructed.
]]
local ReactCurrentOwner = {
  --[[*
   * @internal
   * @type {ReactComponent}
   ]]
  current = nil,
}

return ReactCurrentOwner
