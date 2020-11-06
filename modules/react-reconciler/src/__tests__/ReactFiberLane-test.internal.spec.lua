-- awaiting pull request: https://github.com/facebook/react/pull/20155
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)
	local Object = require(Workspace.RobloxJSPolyfill.Object)

	local SchedulerWithReactIntegration = require(script.Parent.Parent["SchedulerWithReactIntegration.new"])
	local ImmediatePriority = SchedulerWithReactIntegration.ImmediatePriority
	local NormalPriority = SchedulerWithReactIntegration.NormalPriority
	local NoPriority = SchedulerWithReactIntegration.NoPriority
	local UserBlockingPriority = SchedulerWithReactIntegration.UserBlockingPriority

	local ReactFiberLane

	beforeEach(function()
		RobloxJest.resetModules()
		ReactFiberLane = require(script.Parent.Parent.ReactFiberLane)
	end)

	describe("lanePriorityToSchedulerPriority", function()
		local INVALID_PRIORITY_LANE = 999

		local expectedPriorities = {
			SyncLanePriority = ImmediatePriority,
			SyncBatchedLanePriority = ImmediatePriority,
			InputDiscreteLanePriority = UserBlockingPriority,
			InputContinuousLanePriority = UserBlockingPriority,
			DefaultLanePriority = NormalPriority,
			TransitionPriority = NormalPriority,
			NoLanePriority = NoPriority,
		}

		for priorityName, priority in pairs(expectedPriorities) do
			it(("returns the expected priority (%d) for lane %s"):format(priority, priorityName), function()
				local lane = ReactFiberLane[priorityName]
				expect(lane).to.be.ok()
				expect(ReactFiberLane.lanePriorityToSchedulerPriority(lane)).to.equal(
					priority
				)
			end)
		end

		it("throws when giving an invalid lane priority", function()
			local expect: any = expect
			expect(function()
				ReactFiberLane.lanePriorityToSchedulerPriority(INVALID_PRIORITY_LANE)
			end).toThrow(
				("Invalid update priority: %s. This is a bug in React"):format(tostring(INVALID_PRIORITY_LANE))
			)
		end)
	end)

	describe("getHighestPriorityPendingLanes", function()
		it("returns the Sync lane and sets the sync lane priority", function()
			local root = { pendingLanes = ReactFiberLane.SyncLane }
			local lane = ReactFiberLane.getHighestPriorityPendingLanes(root)

			expect(lane).to.equal(ReactFiberLane.SyncLane)
			local nextLanesPriority = ReactFiberLane.returnNextLanesPriority()
			expect(nextLanesPriority).to.equal(ReactFiberLane.SyncLanePriority)
		end)
	end)

	describe('getNextLanes', function()
		describe('given no pending lanes', function()
			local root

			beforeEach(function()
				root = {pendingLanes = ReactFiberLane.NoLanes}
			end)

			it('returns no lanes', function()
				expect(
					ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
				).to.equal(ReactFiberLane.NoLanes)
			end)

			it('sets the highest lane priority to no lane', function()
				ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
				expect(ReactFiberLane.returnNextLanesPriority()).to.equal(
					ReactFiberLane.NoLanePriority
				)
			end)
		end)
		describe('given expired lanes', function()
			local root

			beforeEach(function()
				root = {
					pendingLanes = ReactFiberLane.SyncLane,
					expiredLanes = ReactFiberLane.SyncLane,
					suspendedLanes = ReactFiberLane.NoLanes,
					pingedLanes = ReactFiberLane.NoLanes,
					entangledLanes = ReactFiberLane.NoLanes,
				}
			end)

			describe('no entangled lanes', function()
				describe('pending lanes with higher priority than expired lanes', function()
					beforeEach(function()
						root = Object.assign(root, {
							pendingLanes = ReactFiberLane.mergeLanes(
								ReactFiberLane.SomeRetryLane,
								ReactFiberLane.DefaultHydrationLane
							),
							expiredLanes = ReactFiberLane.DefaultLanes,
						})
					end)

					it('returns the lanes above or equal to the priority of the expired lanes', function()
						local result = ReactFiberLane.getNextLanes(
							root,
							ReactFiberLane.NoLanes
						)
						expect(result).to.equal(ReactFiberLane.DefaultHydrationLane)
					end)

					it('sets the highest lane priority to sync lane', function()
						ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
						expect(ReactFiberLane.returnNextLanesPriority()).to.equal(ReactFiberLane.SyncLanePriority)
					end)
				end)

				describe('pending lanes with lower priority than expired lanes', function()
					beforeEach(function()
						root = Object.assign(root, {
							pendingLanes = ReactFiberLane.SyncBatchedLane,
							expiredLanes = ReactFiberLane.SyncLane,
						})
					end)

					it('returns no lanes', function()
						local result = ReactFiberLane.getNextLanes(
							root,
							ReactFiberLane.NoLanes
						)
						expect(result).to.equal(ReactFiberLane.NoLanes)
					end)

					it('sets the highest lane priority to sync lane', function()
						ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
						expect(ReactFiberLane.returnNextLanesPriority()).to.equal(
							ReactFiberLane.SyncLanePriority
						)
					end)
				end)
			end)

			it('sets the highest lane priority to sync lane', function()
				local result = ReactFiberLane.getNextLanes(
					root,
					ReactFiberLane.NoLanes
				)
				expect(result).to.equal(ReactFiberLane.SyncLane)
				expect(ReactFiberLane.returnNextLanesPriority()).to.equal(
					ReactFiberLane.SyncLanePriority
				)
			end)

			it('sets the highest lane priority to sync lane 2', function()
				root = Object.assign(root, {
					expiredLanes = ReactFiberLane.SyncBatchedLane,
				})
				local result = ReactFiberLane.getNextLanes(
					root,
					ReactFiberLane.NoLanes
				)

				expect(result).to.equal(ReactFiberLane.SyncLane)
				expect(ReactFiberLane.returnNextLanesPriority()).to.equal(
					ReactFiberLane.SyncLanePriority
				)
			end)
		end)
	end)

	describe("includesNonIdleWork", function()
		local nonIdleLaneNames = {
			"SyncLane",
			"SyncBatchedLane",
			"InputDiscreteHydrationLane",
			"DefaultHydrationLane",
			"SomeRetryLane",
			"SelectiveHydrationLane",
		}

		for _, laneName in ipairs(nonIdleLaneNames) do
			it(("is true for %s"):format(laneName), function()
				local lane = ReactFiberLane[laneName]

				expect(lane).to.be.ok()
				expect(ReactFiberLane.includesNonIdleWork(lane)).to.equal(true)
			end)
		end

		local idleLaneNames = {
			"NoLane",
			"OffscreenLane",
			"IdleHydrationLane",
		}

		for _, laneName in ipairs(idleLaneNames) do
			it(("is false for %s"):format(laneName), function()
				local lane = ReactFiberLane[laneName]

				expect(lane).to.be.ok()
				expect(ReactFiberLane.includesNonIdleWork(lane)).to.equal(false)
			end)
		end
	end)

	describe("includesOnlyRetries", function()
		it("is true for a retry lane", function()
			expect(
				ReactFiberLane.includesOnlyRetries(ReactFiberLane.SomeRetryLane
			)).to.equal(true)
		end)

		it("is false for the sync lane", function()
			expect(
				ReactFiberLane.includesOnlyRetries(ReactFiberLane.SyncLane
			)).to.equal(false)
		end)

		it("is false for a retry lane merged with another lane", function()
			local mergedLanes = ReactFiberLane.mergeLanes(
				ReactFiberLane.SyncLane,
				ReactFiberLane.SomeRetryLane
			)
			expect(ReactFiberLane.includesOnlyRetries(mergedLanes)).to.equal(false)
		end)
	end)

	describe("includesSomeLane", function()
		it("is true given the same lane", function()
			local lane = ReactFiberLane.SyncLane
			expect(ReactFiberLane.includesSomeLane(lane, lane)).to.equal(true)
		end)

		it("is true given lanes that includes the other", function()
			local lane = ReactFiberLane.SyncLane
			local mergedLanes = ReactFiberLane.mergeLanes(
				lane,
				ReactFiberLane.DefaultHydrationLane
			)

			expect(ReactFiberLane.includesSomeLane(mergedLanes, lane)).to.equal(true)
		end)

		it("is false for two seperate lanes", function()
			expect(
				ReactFiberLane.includesSomeLane(
					ReactFiberLane.SyncLane,
					ReactFiberLane.DefaultHydrationLane
				)
			).to.equal(false)
		end)
	end)

	describe("isSubsetOfLanes", function()
		it("is true given the same lane", function()
			local lane = ReactFiberLane.SyncLane

			expect(ReactFiberLane.isSubsetOfLanes(lane, lane)).to.equal(true)
		end)

		it("is true given lanes that includes the other", function()
			local subset = ReactFiberLane.mergeLanes(
				ReactFiberLane.SyncLane,
				ReactFiberLane.DefaultHydrationLane
			)
			local mergedLanes = ReactFiberLane.mergeLanes(
				subset,
				ReactFiberLane.SyncBatchedLane
			)

			expect(ReactFiberLane.includesSomeLane(mergedLanes, subset)).to.equal(true)
		end)

		it("is false for two seperate lanes", function()
			expect(
				ReactFiberLane.includesSomeLane(
					ReactFiberLane.SyncLane,
					ReactFiberLane.DefaultHydrationLane
				)
			).to.equal(false)
		end)
	end)

	describe("mergeLanes", function()
		it("returns a lane that includes both inputs", function()
			local laneA = ReactFiberLane.SyncLane
			local laneB = ReactFiberLane.DefaultHydrationLane
			local mergedLanes = ReactFiberLane.mergeLanes(laneA, laneB)

			expect(ReactFiberLane.includesSomeLane(mergedLanes, laneA)).to.equal(true)
			expect(ReactFiberLane.includesSomeLane(mergedLanes, laneB)).to.equal(true)
		end)

		it("returns the same lane given two identical lanes", function()
			local lane = ReactFiberLane.SyncLane
			expect(ReactFiberLane.mergeLanes(lane, lane)).to.equal(lane)
		end)
	end)

	describe("removeLanes", function()
		it("returns the lanes without the given lane", function()
			local laneA = ReactFiberLane.SyncLane
			local laneB = ReactFiberLane.DefaultHydrationLane
			local mergedLanes = ReactFiberLane.mergeLanes(laneA, laneB)

			expect(ReactFiberLane.removeLanes(mergedLanes, laneA)).to.equal(laneB)
			expect(ReactFiberLane.removeLanes(mergedLanes, laneB)).to.equal(laneA)
		end)

		it("returns the same lane when removing a lane not included", function()
			local lanes = ReactFiberLane.mergeLanes(
				ReactFiberLane.SyncLane,
				ReactFiberLane.DefaultHydrationLane
			)
			expect(ReactFiberLane.removeLanes(lanes, ReactFiberLane.SyncBatchedLane)).to.equal(lanes)
		end)
	end)

	describe("higherPriorityLane", function()
		it("returns the other lane if one is NoLane", function()
			local lane = ReactFiberLane.SyncLane

			expect(
				ReactFiberLane.higherPriorityLane(ReactFiberLane.NoLane, lane)
			).to.equal(lane)
			expect(
				ReactFiberLane.higherPriorityLane(lane, ReactFiberLane.NoLane)
			).to.equal(lane)
		end)

		it("returns the higher priority lane", function()
			local higherLane = ReactFiberLane.SyncLane
			local otherLane = ReactFiberLane.OffscreenLane
			expect(
				ReactFiberLane.higherPriorityLane(higherLane, otherLane)
			).to.equal(higherLane)
			expect(
				ReactFiberLane.higherPriorityLane(otherLane, higherLane)
			).to.equal(higherLane)
		end)
	end)

	describe("higherLanePriority", function()
		it("returns the other priority if one is NoLanePriority", function()
			local priority = ReactFiberLane.DefaultLanePriority
			expect(
				ReactFiberLane.higherLanePriority(ReactFiberLane.NoLanePriority, priority)
			).to.equal(priority)
			expect(
				ReactFiberLane.higherLanePriority(priority, ReactFiberLane.NoLanePriority)
			).to.equal(priority)
		end)

		it("returns the higher lane priority", function()
			local higherPriority = ReactFiberLane.SyncLanePriority
			local otherPriority = ReactFiberLane.TransitionPriority
			expect(
				ReactFiberLane.higherLanePriority(higherPriority, otherPriority)
			).to.equal(higherPriority)
			expect(
				ReactFiberLane.higherLanePriority(otherPriority, higherPriority)
			).to.equal(higherPriority)
		end)
	end)
end
