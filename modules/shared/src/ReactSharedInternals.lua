-- upstream: https://github.com/facebook/react/blob/26666427d6ed5cbc581e65e43608fa1acec3bcf8/packages/shared/ReactSharedInternals.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local Workspace = script.Parent.Parent
local React = require(Workspace.React.React)
local ReactSharedInternals = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED

return ReactSharedInternals
