-- upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberStack.new.js
-- upstream https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberStack.new.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local Workspace = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Workspace.Shared.console)

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;

type Array<T> = { [number]: T }
-- deviation: use this table when pushing nil values
type null = {}
local NULL: null = {}

export type StackCursor<T> = { current: T }

local valueStack: Array<any> = {}

local fiberStack: Array<Fiber | null>

if _G.__DEV__ then
	fiberStack = {}
end

local index = 0

-- local function createCursor<T>(defaultValue: T): StackCursor<T>
local function createCursor(defaultValue): StackCursor<any>
	return {
		current = defaultValue,
	}
end

local function isEmpty(): boolean
	return index == 0
end

-- local function pop<T>(cursor: StackCursor<T>, fiber: Fiber)
local function pop(cursor: StackCursor<any>, fiber: Fiber)
	if index < 1 then
		if _G.__DEV__ then
			console.error('Unexpected pop.')
		end
		return
	end

	if _G.__DEV__ then
		if fiber ~= fiberStack[index] then
			console.error('Unexpected Fiber popped.')
		end
	end

	local value = valueStack[index]
	if value == NULL then
		cursor.current = nil
	else
		cursor.current = value
	end

	valueStack[index] = nil

	if _G.__DEV__ then
		fiberStack[index] = nil
	end

	index -= 1
end

-- local function push<T>(cursor: StackCursor<T>, value: T, fiber: Fiber)
local function push(cursor: StackCursor<any>, value: any, fiber: Fiber)
	index += 1

	local stackValue = cursor.current
	if stackValue == nil then
		valueStack[index] = NULL
	else
		valueStack[index] = stackValue
	end

	if _G.__DEV__ then
		if fiber == nil then
			fiberStack[index] = NULL
		else
			fiberStack[index] = fiber
		end
	end

	cursor.current = value
end

local function checkThatStackIsEmpty()
	if _G.__DEV__ then
		if index ~= 0 then
			console.error(
				'Expected an empty stack. Something was not reset properly.'
			)
		end
	end
end

local function resetStackAfterFatalErrorInDev()
	if _G.__DEV__ then
		index = 0
		-- deviation: FIXME: Original js simply sets `length`, we clear this
		-- manually; would it be reasonable to just set them to new empty
		-- tables? Does identity matter here?
		for i = 1, #valueStack do
			valueStack[i] = nil
		end
		for i = 1, #fiberStack do
			fiberStack[i] = nil
		end
	end
end

return {
	createCursor = createCursor,
	isEmpty = isEmpty,
	pop = pop,
	push = push,
	-- DEV only:
	checkThatStackIsEmpty = checkThatStackIsEmpty,
	resetStackAfterFatalErrorInDev = resetStackAfterFatalErrorInDev,
}
