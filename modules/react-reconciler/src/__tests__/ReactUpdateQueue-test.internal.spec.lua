--[[*
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

return function()
	local Workspace = script.Parent.Parent.Parent

	local RobloxJest = require(Workspace.RobloxJest)
	local React = require(Workspace.React)

	local ReactUpdateQueue, Fiber, FiberLane
	local fundamentalFiber, component, update, lane, setStateCallbackWasCalled, workInProgress

	local updateTime = 0
	local nextProps = { userName = 'Dan' }
	local updatePayload = { myVariable = 90210 }

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.mock(script.Parent.Parent.ReactFiberHostConfig, function()
			return require(script.Parent.Parent.forks["ReactFiberHostConfig.test"])
		end)

		ReactUpdateQueue = require(script.Parent.Parent["ReactUpdateQueue.new"])
		Fiber = require(script.Parent.Parent["ReactFiber.new"])
		FiberLane = require(script.Parent.Parent.ReactFiberLane)

		component = React.Component:extend("fundamental")
		fundamentalFiber = Fiber.createFiberFromFundamental(component)

		lane = FiberLane.NoLane
		update = ReactUpdateQueue.createUpdate(updateTime, lane)
		setStateCallbackWasCalled = false
		update.payload = updatePayload
		update.callback = function()
		  setStateCallbackWasCalled = true
		end
		update.lane = lane
	end)

	describe("new ReactUpdateQueue", function()
		it("does not have force update", function()
			local expect: any = expect
			expect(
				ReactUpdateQueue.checkHasForceUpdateAfterProcessing()
			).toEqual(false)
		end)

		it("enqueue before initialize is a no-op", function()
			local expect: any = expect
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, {})
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			expect(workInProgress.updateQueue).toEqual(nil)
		end)
	end)

	describe("initialized ReactUpdateQueue", function()
		beforeEach(function()
			ReactUpdateQueue.initializeUpdateQueue(workInProgress)
		end)

		it("initializes fiber", function()
			local expect: any = expect
			expect(workInProgress.updateQueue).to.be.ok()
		end)

		it("enqueues first update", function()
			local expect: any = expect
			expect(update.tag).toEqual(0)

			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			expect(update.next).to.equal(update)
			expect(workInProgress.updateQueue.shared.pending).to.equal(update)
		end)

		it("enqueues same update twice", function()
			local expect: any = expect

			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)

			expect(update.next).to.equal(update)
			expect(update.next.next).to.equal(update)
			expect(workInProgress.updateQueue.shared.pending).to.equal(update)
		end)
	end)

	describe("processUpdateQueue", function()
		beforeEach(function()
			ReactUpdateQueue.initializeUpdateQueue(fundamentalFiber)
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, nextProps)
		end)

		it("with empty queue", function()
			local expect: any = expect
			ReactUpdateQueue.processUpdateQueue(
				workInProgress,
				nextProps,
				component,
				FiberLane.NoLanes
			  )

			  expect(workInProgress.memoizedState).toEqual(nil)
		end)

		it("with non-empty queue", function()
			local expect: any = expect
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			expect(workInProgress.memoizedState).toEqual(nil)

			ReactUpdateQueue.processUpdateQueue(
			  workInProgress,
			  nextProps,
			  component,
			  FiberLane.NoLanes
			)

			expect(setStateCallbackWasCalled).toEqual(false)
			expect(workInProgress.memoizedState).toEqual(updatePayload)
		end)
	end)

	describe("commitUpdateQueue", function()
		beforeEach(function()
			lane = FiberLane.NoLane
			update = ReactUpdateQueue.createUpdate(updateTime, lane)
			setStateCallbackWasCalled = false
			update.payload = updatePayload
			update.callback = function()
			  setStateCallbackWasCalled = true
			end
			update.lane = lane
			ReactUpdateQueue.initializeUpdateQueue(fundamentalFiber)
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, nextProps)
		end)

		it("with non-empty queue", function()
			local expect: any = expect

			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			expect(workInProgress.memoizedState).toEqual(nil)

			ReactUpdateQueue.processUpdateQueue(
			  workInProgress,
			  nextProps,
			  component,
			  FiberLane.NoLanes
			)

		  ReactUpdateQueue.commitUpdateQueue(
			  workInProgress,
			  fundamentalFiber.updateQueue,
			  component
			)

			expect(setStateCallbackWasCalled).toEqual(true)
		end)
	end)

	describe("enqueueCapturedUpdate", function()
		beforeEach(function()
			lane = FiberLane.NoLane
			update = ReactUpdateQueue.createUpdate(updateTime, lane)
			update.tag = ReactUpdateQueue.CaptureUpdate
			update.lane = lane
			ReactUpdateQueue.initializeUpdateQueue(fundamentalFiber)
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, nextProps)
			local ReactFiberFlags = require(script.Parent.Parent.ReactFiberFlags)
			workInProgress.flags = bit32.bor(0, ReactFiberFlags.ShouldCapture)
		end)

		it("sets lastBaseUpdate", function()
			local expect: any = expect

			ReactUpdateQueue.enqueueCapturedUpdate(workInProgress, update)

			expect(workInProgress.updateQueue.lastBaseUpdate).toEqual(update)
		end)
	end)

end
