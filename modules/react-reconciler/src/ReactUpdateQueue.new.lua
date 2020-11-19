--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- UpdateQueue is a linked list of prioritized updates.
--
-- Like fibers, update queues come in pairs: a current queue, which represents
-- the visible state of the screen, and a work-in-progress queue, which can be
-- mutated and processed asynchronously before it is committed — a form of
-- double buffering. If a work-in-progress render is discarded before finishing,
-- we create a new work-in-progress by cloning the current queue.
--
-- Both queues share a persistent, singly-linked list structure. To schedule an
-- update, we append it to the end of both queues. Each queue maintains a
-- pointer to first update in the persistent list that hasn't been processed.
-- The work-in-progress pointer always has a position equal to or greater than
-- the current queue, since we always work on that one. The current queue's
-- pointer is only updated during the commit phase, when we swap in the
-- work-in-progress.
--
-- For example:
--
--   Current pointer:           A - B - C - D - E - F
--   Work-in-progress pointer:              D - E - F
--                                          ^
--                                          The work-in-progress queue has
--                                          processed more updates than current.
--
-- The reason we append to both queues is because otherwise we might drop
-- updates without ever processing them. For example, if we only add updates to
-- the work-in-progress queue, some updates could be lost whenever a work-in
-- -progress render restarts by cloning from current. Similarly, if we only add
-- updates to the current queue, the updates will be lost whenever an already
-- in-progress queue commits and swaps with the current queue. However, by
-- adding to both queues, we guarantee that the update will be part of the next
-- work-in-progress. (And because the work-in-progress queue becomes the
-- current queue once it commits, there's no danger of applying the same
-- update twice.)
--
-- Prioritization
-- --------------
--
-- Updates are not sorted by priority, but by insertion; new updates are always
-- appended to the end of the list.
--
-- The priority is still important, though. When processing the update queue
-- during the render phase, only the updates with sufficient priority are
-- included in the result. If we skip an update because it has insufficient
-- priority, it remains in the queue to be processed later, during a lower
-- priority render. Crucially, all updates subsequent to a skipped update also
-- remain in the queue *regardless of their priority*. That means high priority
-- updates are sometimes processed twice, at two separate priorities. We also
-- keep track of a base state, that represents the state before the first
-- update in the queue is applied.
--
-- For example:
--
--   Given a base state of '', and the following queue of updates
--
--     A1 - B2 - C1 - D2
--
--   where the number indicates the priority, and the update is applied to the
--   previous state by appending a letter, React will process these updates as
--   two separate renders, one per distinct priority level:
--
--   First render, at priority 1:
--     Base state: ''
--     Updates: [A1, C1]
--     Result state: 'AC'
--
--   Second render, at priority 2:
--     Base state: 'A'            <-  The base state does not include C1,
--                                    because B2 was skipped.
--     Updates: [B2, C1, D2]      <-  C1 was rebased on top of B2
--     Result state: 'ABCD'
--
-- Because we process updates in insertion order, and rebase high priority
-- updates when preceding updates are skipped, the final result is deterministic
-- regardless of priority. Intermediate state may vary according to system
-- resources, but the final state is always the same.

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
type Lane = ReactInternalTypes.Lane;
type Lanes = ReactInternalTypes.Lanes;

-- deviation: Common types
type Array<T> = { [number]: T };

-- local {NoLane, NoLanes, isSubsetOfLanes, mergeLanes} = require(Workspace../ReactFiberLane'
-- local {
-- 	enterDisallowedContextReadInDEV,
-- 	exitDisallowedContextReadInDEV,
-- } = require(Workspace../ReactFiberNewContext.new'
-- local {Callback, ShouldCapture, DidCapture} = require(Workspace../ReactFiberFlags'

-- local {debugRenderPhaseSideEffectsForStrictMode} = require(Workspace.shared/ReactFeatureFlags'

-- local {StrictMode} = require(Workspace../ReactTypeOfMode'
-- local {markSkippedUpdateLanes} = require(Workspace../ReactFiberWorkLoop.new'

-- local invariant = require(Workspace.shared/invariant'

-- local {disableLogs, reenableLogs} = require(Workspace.shared/ConsolePatchingDev'

export type Update<State> = {
	-- TODO: Temporary field. Will remove this by storing a map of
	-- transition -> event time on the root.
	eventTime: number,
	lane: Lane,

	-- deviation: FIXME revert when 
	-- tag: 0 | 1 | 2 | 3,
	tag: number,
	payload: any,
	callback: (() -> any)?,

	next: Update?,
};

type SharedQueue<State> = {
	pending: Update<State>?,
};

export type UpdateQueue<State> = {
	baseState: State,
	firstBaseUpdate: Update<State>?,
	lastBaseUpdate: Update<State>?,
	shared: SharedQueue<State>,
	effects: Array<Update<State>>?,
};

local exports = {}

-- export local UpdateState = 0
-- export local ReplaceState = 1
-- export local ForceUpdate = 2
-- export local CaptureUpdate = 3

-- -- Global state that is reset at the beginning of calling `processUpdateQueue`.
-- -- It should only be read right after calling `processUpdateQueue`, via
-- -- `checkHasForceUpdateAfterProcessing`.
-- local hasForceUpdate = false

-- local didWarnUpdateInsideUpdate
-- local currentlyProcessingQueue
-- export local resetCurrentlyProcessingQueue
-- if _G.__DEV__)
-- 	didWarnUpdateInsideUpdate = false
-- 	currentlyProcessingQueue = nil
-- 	resetCurrentlyProcessingQueue = () => {
-- 		currentlyProcessingQueue = nil
-- 	end
-- end

-- deviation: FIXME generics in function signatures
-- 'initializeUpdateQueue<State>(fiber: Fiber)'
local function initializeUpdateQueue(fiber: Fiber)
	local queue: UpdateQueue<any> = {
		baseState = fiber.memoizedState,
		firstBaseUpdate = nil,
		lastBaseUpdate = nil,
		shared = {
			pending = nil,
		},
		effects = nil,
	}
	fiber.updateQueue = queue
end
exports.initializeUpdateQueue = initializeUpdateQueue

-- exports.cloneUpdateQueue<State>(
-- 	current: Fiber,
-- 	workInProgress: Fiber,
-- ): void {
-- 	-- Clone the update queue from current. Unless it's already a clone.
-- 	local queue: UpdateQueue<State> = (workInProgress.updateQueue: any)
-- 	local currentQueue: UpdateQueue<State> = (current.updateQueue: any)
-- 	if queue == currentQueue)
-- 		local clone: UpdateQueue<State> = {
-- 			baseState: currentQueue.baseState,
-- 			firstBaseUpdate: currentQueue.firstBaseUpdate,
-- 			lastBaseUpdate: currentQueue.lastBaseUpdate,
-- 			shared: currentQueue.shared,
-- 			effects: currentQueue.effects,
-- 		end
-- 		workInProgress.updateQueue = clone
-- 	end
-- end

-- exports.createUpdate(eventTime: number, lane: Lane): Update<*> {
-- 	local update: Update<*> = {
-- 		eventTime,
-- 		lane,

-- 		tag: UpdateState,
-- 		payload: nil,
-- 		callback: nil,

-- 		next: nil,
-- 	end
-- 	return update
-- end

-- exports.enqueueUpdate<State>(fiber: Fiber, update: Update<State>)
-- 	local updateQueue = fiber.updateQueue
-- 	if updateQueue == nil)
-- 		-- Only occurs if the fiber has been unmounted.
-- 		return
-- 	end

-- 	local sharedQueue: SharedQueue<State> = (updateQueue: any).shared
-- 	local pending = sharedQueue.pending
-- 	if pending == nil)
-- 		-- This is the first update. Create a circular list.
-- 		update.next = update
-- 	} else {
-- 		update.next = pending.next
-- 		pending.next = update
-- 	end
-- 	sharedQueue.pending = update

-- 	if _G.__DEV__)
-- 		if 
-- 			currentlyProcessingQueue == sharedQueue and
-- 			!didWarnUpdateInsideUpdate
-- 		)
-- 			console.error(
-- 				'An update (setState, replaceState, or forceUpdate) was scheduled ' +
-- 					'from inside an update function. Update functions should be pure, ' +
-- 					'with zero side-effects. Consider using componentDidUpdate or a ' +
-- 					'callback.',
-- 			)
-- 			didWarnUpdateInsideUpdate = true
-- 		end
-- 	end
-- end

-- exports.enqueueCapturedUpdate<State>(
-- 	workInProgress: Fiber,
-- 	capturedUpdate: Update<State>,
-- )
-- 	-- Captured updates are updates that are thrown by a child during the render
-- 	-- phase. They should be discarded if the render is aborted. Therefore,
-- 	-- we should only put them on the work-in-progress queue, not the current one.
-- 	local queue: UpdateQueue<State> = (workInProgress.updateQueue: any)

-- 	-- Check if the work-in-progress queue is a clone.
-- 	local current = workInProgress.alternate
-- 	if current ~= nil)
-- 		local currentQueue: UpdateQueue<State> = (current.updateQueue: any)
-- 		if queue == currentQueue)
-- 			-- The work-in-progress queue is the same as current. This happens when
-- 			-- we bail out on a parent fiber that then captures an error thrown by
-- 			-- a child. Since we want to append the update only to the work-in
-- 			-- -progress queue, we need to clone the updates. We usually clone during
-- 			-- processUpdateQueue, but that didn't happen in this case because we
-- 			-- skipped over the parent when we bailed out.
-- 			local newFirst = nil
-- 			local newLast = nil
-- 			local firstBaseUpdate = queue.firstBaseUpdate
-- 			if firstBaseUpdate ~= nil)
-- 				-- Loop through the updates and clone them.
-- 				local update = firstBaseUpdate
-- 				do {
-- 					local clone: Update<State> = {
-- 						eventTime: update.eventTime,
-- 						lane: update.lane,

-- 						tag: update.tag,
-- 						payload: update.payload,
-- 						callback: update.callback,

-- 						next: nil,
-- 					end
-- 					if newLast == nil)
-- 						newFirst = newLast = clone
-- 					} else {
-- 						newLast.next = clone
-- 						newLast = clone
-- 					end
-- 					update = update.next
-- 				} while (update ~= nil)

-- 				-- Append the captured update the end of the cloned list.
-- 				if newLast == nil)
-- 					newFirst = newLast = capturedUpdate
-- 				} else {
-- 					newLast.next = capturedUpdate
-- 					newLast = capturedUpdate
-- 				end
-- 			} else {
-- 				-- There are no base updates.
-- 				newFirst = newLast = capturedUpdate
-- 			end
-- 			queue = {
-- 				baseState: currentQueue.baseState,
-- 				firstBaseUpdate: newFirst,
-- 				lastBaseUpdate: newLast,
-- 				shared: currentQueue.shared,
-- 				effects: currentQueue.effects,
-- 			end
-- 			workInProgress.updateQueue = queue
-- 			return
-- 		end
-- 	end

-- 	-- Append the update to the end of the list.
-- 	local lastBaseUpdate = queue.lastBaseUpdate
-- 	if lastBaseUpdate == nil)
-- 		queue.firstBaseUpdate = capturedUpdate
-- 	} else {
-- 		lastBaseUpdate.next = capturedUpdate
-- 	end
-- 	queue.lastBaseUpdate = capturedUpdate
-- end

-- function getStateFromUpdate<State>(
-- 	workInProgress: Fiber,
-- 	queue: UpdateQueue<State>,
-- 	update: Update<State>,
-- 	prevState: State,
-- 	nextProps: any,
-- 	instance: any,
-- ): any {
-- 	switch (update.tag)
-- 		case ReplaceState: {
-- 			local payload = update.payload
-- 			if typeof payload == 'function')
-- 				-- Updater function
-- 				if _G.__DEV__)
-- 					enterDisallowedContextReadInDEV()
-- 				end
-- 				local nextState = payload.call(instance, prevState, nextProps)
-- 				if _G.__DEV__)
-- 					if 
-- 						debugRenderPhaseSideEffectsForStrictMode and
-- 						workInProgress.mode & StrictMode
-- 					)
-- 						disableLogs()
-- 						try {
-- 							payload.call(instance, prevState, nextProps)
-- 						} finally {
-- 							reenableLogs()
-- 						end
-- 					end
-- 					exitDisallowedContextReadInDEV()
-- 				end
-- 				return nextState
-- 			end
-- 			-- State object
-- 			return payload
-- 		end
-- 		case CaptureUpdate: {
-- 			workInProgress.flags =
-- 				(workInProgress.flags & ~ShouldCapture) | DidCapture
-- 		end
-- 		-- Intentional fallthrough
-- 		case UpdateState: {
-- 			local payload = update.payload
-- 			local partialState
-- 			if typeof payload == 'function')
-- 				-- Updater function
-- 				if _G.__DEV__)
-- 					enterDisallowedContextReadInDEV()
-- 				end
-- 				partialState = payload.call(instance, prevState, nextProps)
-- 				if _G.__DEV__)
-- 					if 
-- 						debugRenderPhaseSideEffectsForStrictMode and
-- 						workInProgress.mode & StrictMode
-- 					)
-- 						disableLogs()
-- 						try {
-- 							payload.call(instance, prevState, nextProps)
-- 						} finally {
-- 							reenableLogs()
-- 						end
-- 					end
-- 					exitDisallowedContextReadInDEV()
-- 				end
-- 			} else {
-- 				-- Partial state object
-- 				partialState = payload
-- 			end
-- 			if partialState == nil or partialState == undefined)
-- 				-- Null and undefined are treated as no-ops.
-- 				return prevState
-- 			end
-- 			-- Merge the partial state and the previous state.
-- 			return Object.assign({}, prevState, partialState)
-- 		end
-- 		case ForceUpdate: {
-- 			hasForceUpdate = true
-- 			return prevState
-- 		end
-- 	end
-- 	return prevState
-- end

-- exports.processUpdateQueue<State>(
-- 	workInProgress: Fiber,
-- 	props: any,
-- 	instance: any,
-- 	renderLanes: Lanes,
-- ): void {
-- 	-- This is always non-null on a ClassComponent or HostRoot
-- 	local queue: UpdateQueue<State> = (workInProgress.updateQueue: any)

-- 	hasForceUpdate = false

-- 	if _G.__DEV__)
-- 		currentlyProcessingQueue = queue.shared
-- 	end

-- 	local firstBaseUpdate = queue.firstBaseUpdate
-- 	local lastBaseUpdate = queue.lastBaseUpdate

-- 	-- Check if there are pending updates. If so, transfer them to the base queue.
-- 	local pendingQueue = queue.shared.pending
-- 	if pendingQueue ~= nil)
-- 		queue.shared.pending = nil

-- 		-- The pending queue is circular. Disconnect the pointer between first
-- 		-- and last so that it's non-circular.
-- 		local lastPendingUpdate = pendingQueue
-- 		local firstPendingUpdate = lastPendingUpdate.next
-- 		lastPendingUpdate.next = nil
-- 		-- Append pending updates to base queue
-- 		if lastBaseUpdate == nil)
-- 			firstBaseUpdate = firstPendingUpdate
-- 		} else {
-- 			lastBaseUpdate.next = firstPendingUpdate
-- 		end
-- 		lastBaseUpdate = lastPendingUpdate

-- 		-- If there's a current queue, and it's different from the base queue, then
-- 		-- we need to transfer the updates to that queue, too. Because the base
-- 		-- queue is a singly-linked list with no cycles, we can append to both
-- 		-- lists and take advantage of structural sharing.
-- 		-- TODO: Pass `current` as argument
-- 		local current = workInProgress.alternate
-- 		if current ~= nil)
-- 			-- This is always non-null on a ClassComponent or HostRoot
-- 			local currentQueue: UpdateQueue<State> = (current.updateQueue: any)
-- 			local currentLastBaseUpdate = currentQueue.lastBaseUpdate
-- 			if currentLastBaseUpdate ~= lastBaseUpdate)
-- 				if currentLastBaseUpdate == nil)
-- 					currentQueue.firstBaseUpdate = firstPendingUpdate
-- 				} else {
-- 					currentLastBaseUpdate.next = firstPendingUpdate
-- 				end
-- 				currentQueue.lastBaseUpdate = lastPendingUpdate
-- 			end
-- 		end
-- 	end

-- 	-- These values may change as we process the queue.
-- 	if firstBaseUpdate ~= nil)
-- 		-- Iterate through the list of updates to compute the result.
-- 		local newState = queue.baseState
-- 		-- TODO: Don't need to accumulate this. Instead, we can remove renderLanes
-- 		-- from the original lanes.
-- 		local newLanes = NoLanes

-- 		local newBaseState = nil
-- 		local newFirstBaseUpdate = nil
-- 		local newLastBaseUpdate = nil

-- 		local update = firstBaseUpdate
-- 		do {
-- 			local updateLane = update.lane
-- 			local updateEventTime = update.eventTime
-- 			if !isSubsetOfLanes(renderLanes, updateLane))
-- 				-- Priority is insufficient. Skip this update. If this is the first
-- 				-- skipped update, the previous update/state is the new base
-- 				-- update/state.
-- 				local clone: Update<State> = {
-- 					eventTime: updateEventTime,
-- 					lane: updateLane,

-- 					tag: update.tag,
-- 					payload: update.payload,
-- 					callback: update.callback,

-- 					next: nil,
-- 				end
-- 				if newLastBaseUpdate == nil)
-- 					newFirstBaseUpdate = newLastBaseUpdate = clone
-- 					newBaseState = newState
-- 				} else {
-- 					newLastBaseUpdate = newLastBaseUpdate.next = clone
-- 				end
-- 				-- Update the remaining priority in the queue.
-- 				newLanes = mergeLanes(newLanes, updateLane)
-- 			} else {
-- 				-- This update does have sufficient priority.

-- 				if newLastBaseUpdate ~= nil)
-- 					local clone: Update<State> = {
-- 						eventTime: updateEventTime,
-- 						-- This update is going to be committed so we never want uncommit
-- 						-- it. Using NoLane works because 0 is a subset of all bitmasks, so
-- 						-- this will never be skipped by the check above.
-- 						lane: NoLane,

-- 						tag: update.tag,
-- 						payload: update.payload,
-- 						callback: update.callback,

-- 						next: nil,
-- 					end
-- 					newLastBaseUpdate = newLastBaseUpdate.next = clone
-- 				end

-- 				-- Process this update.
-- 				newState = getStateFromUpdate(
-- 					workInProgress,
-- 					queue,
-- 					update,
-- 					newState,
-- 					props,
-- 					instance,
-- 				)
-- 				local callback = update.callback
-- 				if callback ~= nil)
-- 					workInProgress.flags |= Callback
-- 					local effects = queue.effects
-- 					if effects == nil)
-- 						queue.effects = [update]
-- 					} else {
-- 						effects.push(update)
-- 					end
-- 				end
-- 			end
-- 			update = update.next
-- 			if update == nil)
-- 				pendingQueue = queue.shared.pending
-- 				if pendingQueue == nil)
-- 					break
-- 				} else {
-- 					-- An update was scheduled from inside a reducer. Add the new
-- 					-- pending updates to the end of the list and keep processing.
-- 					local lastPendingUpdate = pendingQueue
-- 					-- Intentionally unsound. Pending updates form a circular list, but we
-- 					-- unravel them when transferring them to the base queue.
-- 					local firstPendingUpdate = ((lastPendingUpdate.next: any): Update<State>)
-- 					lastPendingUpdate.next = nil
-- 					update = firstPendingUpdate
-- 					queue.lastBaseUpdate = lastPendingUpdate
-- 					queue.shared.pending = nil
-- 				end
-- 			end
-- 		} while (true)

-- 		if newLastBaseUpdate == nil)
-- 			newBaseState = newState
-- 		end

-- 		queue.baseState = ((newBaseState: any): State)
-- 		queue.firstBaseUpdate = newFirstBaseUpdate
-- 		queue.lastBaseUpdate = newLastBaseUpdate

-- 		-- Set the remaining expiration time to be whatever is remaining in the queue.
-- 		-- This should be fine because the only two other things that contribute to
-- 		-- expiration time are props and context. We're already in the middle of the
-- 		-- begin phase by the time we start processing the queue, so we've already
-- 		-- dealt with the props. Context in components that specify
-- 		-- shouldComponentUpdate is tricky; but we'll have to account for
-- 		-- that regardless.
-- 		markSkippedUpdateLanes(newLanes)
-- 		workInProgress.lanes = newLanes
-- 		workInProgress.memoizedState = newState
-- 	end

-- 	if _G.__DEV__)
-- 		currentlyProcessingQueue = nil
-- 	end
-- end

-- function callCallback(callback, context)
-- 	invariant(
-- 		typeof callback == 'function',
-- 		'Invalid argument passed as callback. Expected a function. Instead ' +
-- 			'received: %s',
-- 		callback,
-- 	)
-- 	callback.call(context)
-- end

-- exports.resetHasForceUpdateBeforeProcessing()
-- 	hasForceUpdate = false
-- end

-- exports.checkHasForceUpdateAfterProcessing(): boolean {
-- 	return hasForceUpdate
-- end

-- exports.commitUpdateQueue<State>(
-- 	finishedWork: Fiber,
-- 	finishedQueue: UpdateQueue<State>,
-- 	instance: any,
-- ): void {
-- 	-- Commit the effects
-- 	local effects = finishedQueue.effects
-- 	finishedQueue.effects = nil
-- 	if effects ~= nil)
-- 		for (local i = 0; i < effects.length; i++)
-- 			local effect = effects[i]
-- 			local callback = effect.callback
-- 			if callback ~= nil)
-- 				effect.callback = nil
-- 				callCallback(callback, instance)
-- 			end
-- 		end
-- 	end
-- end

return exports
