-- upstream: https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/__tests__/ReactNoopRendererAct-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @jest-environment node
 ]]

-- sanity tests for ReactNoop.act()

local Workspace = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler

return function()
	local RobloxJest = require(Workspace.RobloxJest)
	local Packages = Workspace.Parent
	local Promise = require(Packages.Promise)
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

	beforeEach(function()
		RobloxJest.resetModules()
		-- deviation: In react, jest _always_ mocks Scheduler -> unstable_mock;
		-- in our case, we need to do it anywhere we want to use the scheduler,
		-- until we have some form of bundling logic
		RobloxJest.mock(Workspace.Scheduler, function()
			return require(Workspace.Scheduler.unstable_mock)
		end)

		React = require(Workspace.React)
		ReactNoop = require(Workspace.ReactNoopRenderer)
		Scheduler = require(Workspace.Scheduler)
	end)


	it('can use act to flush effects', function()
		local function App(props)
			React.useEffect(props.callback)
			return nil
		end

		local calledLog = {}
		ReactNoop.act(function()
			ReactNoop.render(
				React.createElement(App, {
					callback = function()
						table.insert(calledLog, #calledLog)
					end,
				})
			)
		end)
		jestExpect(Scheduler).toFlushWithoutYielding()
		jestExpect(calledLog).toEqual({0})
	end)
	it('should work with async/await', function()
		local function App()
			local ctr, setCtr = React.useState(0)
			local function someAsyncFunction()
				Scheduler.unstable_yieldValue('stage 1')
				Scheduler.unstable_yieldValue('stage 2')
				setCtr(1)
			end
			React.useEffect(function ()
				someAsyncFunction()
			end, {})
			return ctr
		end
		Promise.try(function()
			ReactNoop.act(function()
				ReactNoop.render(React.createElement(App))
			end)
		end):await()
		jestExpect(Scheduler).toHaveYielded({'stage 1', 'stage 2'})
		jestExpect(Scheduler).toFlushWithoutYielding()
		jestExpect(ReactNoop.getChildren()).toEqual({{text = '1', hidden = false}})
	end)
end
