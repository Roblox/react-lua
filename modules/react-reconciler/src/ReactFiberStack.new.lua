--!strict
-- upstream https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberStack.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local Workspace = script.Parent.Parent
local Packages = Workspace.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local console = LuauPolyfill.console

type Array<T> = { [number]: T }
-- deviation: use this table when pushing nil values
type null = {}
local NULL: null = {}

-- deviation: ReactInternalTypes not implemented. Instead of just dropping
-- the type, we are defining one so it'll be a minor refactor to switch to
-- the futur FiberRoot type.
type Fiber = any

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

	index = index - 1
end

-- local function push<T>(cursor: StackCursor<T>, value: T, fiber: Fiber)
local function push(cursor: StackCursor<any>, value: any, fiber: Fiber)
	index = index + 1

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
	-- // DEV only:
	checkThatStackIsEmpty = checkThatStackIsEmpty,
	resetStackAfterFatalErrorInDev = resetStackAfterFatalErrorInDev,
}