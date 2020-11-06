-- upstream: https://github.com/facebook/react/blob/376d5c1b5aa17724c5fea9412f8fcde14a7b23f1/packages/react/src/ReactCurrentDispatcher.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

--[[*
* Keeps track of the current dispatcher.
]]
local ReactCurrentDispatcher = {
	--[[
		* @internal
		* @type {ReactComponent}
		*/
	]]
	current = nil,
}

return ReactCurrentDispatcher
