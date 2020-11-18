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

	local ReactFiberContext
	local ReactFiber
	local ReactRootTags
	local ReactFeatureFlags

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.mock(script.Parent.Parent.ReactFiberHostConfig, function()
			return require(script.Parent.Parent.forks["ReactFiberHostConfig.test"])
		end)

		ReactFiberContext = require(script.Parent.Parent["ReactFiberContext.new"])
		ReactFiber = require(script.Parent.Parent["ReactFiber.new"])
		ReactRootTags = require(script.Parent.Parent.ReactRootTags)
		ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
		ReactFeatureFlags.disableLegacyContext = false
	end)

	describe("Context stack", function()
		it("should throw when pushing to top level of non-empty stack", function()
			-- FIXME: expect coercion
			local expect: any = expect
			local fiber = ReactFiber.createHostRootFiber(ReactRootTags.BlockingRoot)
			local context = {
				foo = 1,
			}
			-- The first call here is a valid use of pushTopLevelContextObject
			ReactFiberContext.pushTopLevelContextObject(fiber, context, true)
			expect(function()
				local moreContext = {
					bar = 2,
				}
				ReactFiberContext.pushTopLevelContextObject(fiber, moreContext, true)
			end).toThrow("Unexpected context found on stack.")
		end)

		it("should throw if when invalidating a provider that isn't initialized", function()
			-- FIXME: expect coercion
			local expect: any = expect
			local fiber = ReactFiber.createHostRootFiber(ReactRootTags.BlockingRoot)
			expect(function()
				ReactFiberContext.invalidateContextProvider(fiber, nil, true)
			end).toThrow("Expected to have an instance by this point.")
		end)
	end)
end
