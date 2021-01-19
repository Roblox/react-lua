-- upstream: https://github.com/facebook/react/blob/72d00ab623502983ebd7ac0756cf2787df109811/packages/react-reconciler/src/ReactFiberComponentStack.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Workspace = script.Parent.Parent

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;

local ReactWorkTags = require(script.Parent.ReactWorkTags)
local HostComponent = ReactWorkTags.HostComponent
local LazyComponent = ReactWorkTags.LazyComponent
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local FunctionComponent = ReactWorkTags.FunctionComponent
local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
local ForwardRef = ReactWorkTags.ForwardRef
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local ClassComponent = ReactWorkTags.ClassComponent

local ReactComponentStackFrame = require(Workspace.Shared.ReactComponentStackFrame)
local describeBuiltInComponentFrame = ReactComponentStackFrame.describeBuiltInComponentFrame
local describeFunctionComponentFrame = ReactComponentStackFrame.describeFunctionComponentFrame
local describeClassComponentFrame = ReactComponentStackFrame.describeClassComponentFrame

local function describeFiber(fiber: Fiber): string
	-- deviation: untangling some nested ternaries to use more idiomatic if/else
	local owner: (() -> ())? = nil
	if _G.__DEV__ then
		-- FIXME (roblox): Luau's limited narrowing necessitates this local
		local debugOwner = fiber._debugOwner
		if debugOwner then
			owner = debugOwner.type
		end
	end
	local source = _G.__DEV__ and fiber._debugSource or nil
	if fiber.tag == HostComponent then
		return describeBuiltInComponentFrame(fiber.type, source, owner)
	elseif fiber.tag == LazyComponent then
		return describeBuiltInComponentFrame('Lazy', source, owner)
	elseif fiber.tag == SuspenseComponent then
		return describeBuiltInComponentFrame('Suspense', source, owner)
	elseif fiber.tag == SuspenseListComponent then
		return describeBuiltInComponentFrame('SuspenseList', source, owner)
	elseif
		fiber.tag == FunctionComponent
		or fiber.tag == IndeterminateComponent
		or fiber.tag == SimpleMemoComponent
	then
		return describeFunctionComponentFrame(fiber.type, source, owner)
	elseif fiber.tag == ForwardRef then
		return describeFunctionComponentFrame(fiber.type.render, source, owner)
	elseif fiber.tag == ClassComponent then
		return describeClassComponentFrame(fiber.type, source, owner)
	else
		return ""
	end
end

return {
	getStackByFiberInDevAndProd = function(workInProgress: Fiber): string
		local ok, result = pcall(function()
			local info = ""
			local node = workInProgress
			repeat
				info ..= describeFiber(node)
				node = node.return_
			until node == nil
			return info
		end)
		if not ok then
			-- FIXME: result.stack is probably not present here with the current
			-- shape of our `Error` object
			return "\nError generating stack: " .. result.message .. "\n" .. result.stack
		end
		return result
	end
}
