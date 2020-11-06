-- upstream: https://github.com/facebook/react/blob/98d410f5005988644d01c9ec79b7181c3dd6c847/packages/react/src/ReactDebugCurrentFrame.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local ReactDebugCurrentFrame = {}

local currentExtraStackFrame = nil

ReactDebugCurrentFrame.setExtraStackFrame = function (stack: string?)
	if _G.__DEV__ then
		currentExtraStackFrame = stack
	end
end

if _G.__DEV__ then
	ReactDebugCurrentFrame.setExtraStackFrame = function(stack: string?)
		if _G.__DEV__ then
			currentExtraStackFrame = stack
		end
	end

	-- Stack implementation injected by the current renderer.
	ReactDebugCurrentFrame.getCurrentStack = nil

	ReactDebugCurrentFrame.getStackAddendum = function()
		local stack = ''

		-- Add an extra top frame while an element is being validated
		if currentExtraStackFrame then
			stack = stack .. currentExtraStackFrame
		end

		-- Delegate to the injected renderer-specific implementation
		local impl = ReactDebugCurrentFrame.getCurrentStack
		if impl then
			stack = stack .. (impl() or '')
		end

		return stack
	end
end

return ReactDebugCurrentFrame
