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
	local Packages = Workspace.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

	local ReactFiberDevToolsHook

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.mock(script.Parent.Parent.ReactFiberHostConfig, function()
			return require(script.Parent.Parent.forks["ReactFiberHostConfig.test"])
		end)

		ReactFiberDevToolsHook = require(script.Parent.Parent["ReactFiberDevToolsHook.new"])
	end)

	describe("DevTools hook detection", function()
		local originalDevtoolsState
		beforeAll(function()
			originalDevtoolsState = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__
		end)

		afterAll(function()
			_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = originalDevtoolsState
		end)

		-- ROBLOX TODO: devtools
		if _G.__DEV__ then
			itSKIP("should log an error when fibers aren't supported", function()
				_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = {
					isDisabled = false,
					supportsHooks = false,
				}
				local result = ReactFiberDevToolsHook.injectInternals({})
				-- expect logs to include error
				jestExpect(result).toBe(true)
			end)
		end
	end)
end
