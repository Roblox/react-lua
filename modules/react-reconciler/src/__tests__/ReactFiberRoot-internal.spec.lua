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

	local ReactFiberRoot
	local ReactRootTags

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.mock(script.Parent.Parent.ReactFiberHostConfig, function()
			return require(script.Parent.Parent.forks["ReactFiberHostConfig.test"])
		end)

		ReactFiberRoot = require(script.Parent.Parent["ReactFiberRoot.new"])
		ReactRootTags = require(script.Parent.Parent.ReactRootTags)
	end)

	it("should properly initialize a fiber created with createFiberRoot", function()
		local fiberRoot = ReactFiberRoot.createFiberRoot({}, ReactRootTags.BlockingRoot, false, nil)

		expect(fiberRoot.current).to.be.ok()
		expect(fiberRoot.current.updateQueue).to.be.ok()
	end)
end
