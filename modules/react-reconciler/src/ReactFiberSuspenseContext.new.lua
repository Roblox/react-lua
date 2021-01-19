-- upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberSuspenseContext.new.js
--!strict
-- upstream https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberSuspenseContext.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- deviation: ReactInternalTypes not implemented. Instead of just dropping
-- the type, we are defining one so it'll be a minor refactor to switch to
-- the futur FiberRoot type.
type Fiber = any

local ReactFiberStack = require(script.Parent['ReactFiberStack.new'])
-- deviation: until roblox-cli is able to trace requires with index
-- expressions (CLI-31888), we can't import the type so we just copy it
-- type StackCursor<T> = ReactFiberStack.StackCursor<T>
type StackCursor<T> = { current: T }

local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop

export type SuspenseContext = number
export type SubtreeSuspenseContext = SuspenseContext
export type ShallowSuspenseContext = SuspenseContext

local exports = {}

local DefaultSuspenseContext: SuspenseContext = 0b00

-- // The Suspense Context is split into two parts. The lower bits is
-- // inherited deeply down the subtree. The upper bits only affect
-- // this immediate suspense boundary and gets reset each new
-- // boundary or suspense list.
local SubtreeSuspenseContextMask: SuspenseContext = 0b01

-- // Subtree Flags:

-- // InvisibleParentSuspenseContext indicates that one of our parent Suspense
-- // boundaries is not currently showing visible main content.
-- // Either because it is already showing a fallback or is not mounted at all.
-- // We can use this to determine if it is desirable to trigger a fallback at
-- // the parent. If not, then we might need to trigger undesirable boundaries
-- // and/or suspend the commit to avoid hiding the parent content.
local InvisibleParentSuspenseContext: SubtreeSuspenseContext = 0b01
exports.InvisibleParentSuspenseContext = InvisibleParentSuspenseContext

-- // Shallow Flags:

-- // ForceSuspenseFallback can be used by SuspenseList to force newly added
-- // items into their fallback state during one of the render passes.
local ForceSuspenseFallback: ShallowSuspenseContext = 0b10
exports.ForceSuspenseFallback = ForceSuspenseFallback

local suspenseStackCursor: StackCursor<SuspenseContext> = createCursor(
	DefaultSuspenseContext
)
exports.suspenseStackCursor = suspenseStackCursor

function exports.hasSuspenseContext(
	parentContext: SuspenseContext,
	flag: SuspenseContext
): boolean
	return bit32.band(parentContext, flag) ~= 0
end

function exports.setDefaultShallowSuspenseContext(
	parentContext: SuspenseContext
): SuspenseContext
	return bit32.band(parentContext, SubtreeSuspenseContextMask)
end

function exports.setShallowSuspenseContext(
	parentContext: SuspenseContext,
	shallowContext: ShallowSuspenseContext
): SuspenseContext
	return bit32.bor(bit32.band(parentContext, SubtreeSuspenseContextMask), shallowContext)
end

function exports.addSubtreeSuspenseContext(
	parentContext: SuspenseContext,
	subtreeContext: SubtreeSuspenseContext
): SuspenseContext
	return bit32.bor(parentContext, subtreeContext)
end

function exports.pushSuspenseContext(
	fiber: Fiber,
	newContext: SuspenseContext
)
	push(suspenseStackCursor, newContext, fiber)
end

function exports.popSuspenseContext(fiber: Fiber)
	pop(suspenseStackCursor, fiber)
end

return exports
