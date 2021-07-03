-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

local Packages = script.Parent.Parent.Parent
local ReactVersion = require(Packages.Shared).ReactVersion
local jest = require(Packages.Dev.RobloxJest)
local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Promise = require(Packages.Promise)

return function()
	describe("SchedulingProfiler", function()
		local React
		local ReactTestRenderer
		local ReactNoop
		local Scheduler

		local marks

		local function createUserTimingPolyfill()
			-- This is not a true polyfill, but it gives us enough to capture marks.
			-- Reference: https://developer.mozilla.org/en-US/docs/Web/API/User_Timing_API
			return {
				mark = function(markName)
					table.insert(marks, markName)
				end,
			}
		end

		beforeEach(function()
			jest.resetModules()
			_G.performance = createUserTimingPolyfill()
			marks = {}

			local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
			ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
			ReactFeatureFlags.enableSchedulingProfiler = true

			React = require(Packages.React)

			-- ReactNoop must be imported after ReactTestRenderer!
			ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
			ReactNoop = require(Packages.Dev.ReactNoopRenderer)

			Scheduler = require(Packages.Scheduler)
		end)

		afterEach(function()
			_G.performance = nil
		end)

		-- @gate !enableSchedulingProfiler
		xit("should not mark if enableSchedulingProfiler is false", function()
			ReactTestRenderer.create(React.createElement("div"))
			jestExpect(marks).toEqual({})
		end)

		-- @gate enableSchedulingProfiler
		it("should log React version on initialization", function()
			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
			})
		end)

		-- @gate enableSchedulingProfiler
		it("should mark sync render without suspends or state updates", function()
			ReactTestRenderer.create(React.createElement("div"))

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-1",
				"--render-start-1",
				"--render-stop",
				"--commit-start-1",
				"--layout-effects-start-1",
				"--layout-effects-stop",
				"--commit-stop",
			})
		end)

		-- @gate enableSchedulingProfiler
		it("should mark concurrent render without suspends or state updates", function()
			ReactTestRenderer.create(
				React.createElement("div"),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(Scheduler).toFlushUntilNextPaint({})

			jestExpect(marks).toEqual({
				"--render-start-512",
				"--render-stop",
				"--commit-start-512",
				"--layout-effects-start-512",
				"--layout-effects-stop",
				"--commit-stop",
			})
		end)

		-- @gate enableSchedulingProfiler
		it("should mark render yields", function()
			local function Bar()
				Scheduler.unstable_yieldValue("Bar")
				return nil
			end

			local function Foo()
				Scheduler.unstable_yieldValue("Foo")
				return React.createElement(Bar)
			end

			ReactNoop.render(React.createElement(Foo))
			-- Do one step of work.
			jestExpect(ReactNoop.flushNextYield()).toEqual({ "Foo" })

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
				"--render-start-512",
				"--render-yield",
			})
		end)

		-- @gate enableSchedulingProfiler
		-- ROBLOX FIXME: Example suspended while rendering, but no fallback UI was specified
		xit("should mark sync render with suspense that resolves", function()
			local fakeSuspensePromise = Promise.resolve(true)
			local function Example()
				error(fakeSuspensePromise)
			end

			ReactTestRenderer.create(
				React.createElement(
					React.Suspense,
					{ fallback = nil },
					React.createElement(Example)
				)
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-1",
				"--render-start-1",
				"--suspense-suspend-0-Example",
				"--render-stop",
				"--commit-start-1",
				"--layout-effects-start-1",
				"--layout-effects-stop",
				"--commit-stop",
			})

			Array.splice(marks, 1)

			fakeSuspensePromise:await()
			jestExpect(marks).toEqual({ "--suspense-resolved-0-Example" })
		end)

		-- @gate enableSchedulingProfiler
		-- ROBLOX FIXME: Example suspended while rendering, but no fallback UI was specified
		xit("should mark sync render with suspense that rejects", function()
			local fakeSuspensePromise = Promise.reject(Error.new("error"))
			local function Example()
				error(fakeSuspensePromise)
			end

			ReactTestRenderer.create(
				React.createElement(
					React.Suspense,
					{ fallback = nil },
					React.createElement(Example)
				)
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-1",
				"--render-start-1",
				"--suspense-suspend-0-Example",
				"--render-stop",
				"--commit-start-1",
				"--layout-effects-start-1",
				"--layout-effects-stop",
				"--commit-stop",
			})

			Array.splice(marks, 1)

			-- ROBLOX TODO: how do we do this?
			-- await jestExpect(fakeSuspensePromise).rejects.toThrow()
			jestExpect(marks).toEqual({ "--suspense-rejected-0-Example" })
		end)

		-- @gate enableSchedulingProfiler
		-- ROBLOX FIXME: Example suspended while rendering, but no fallback UI was specified
		xit("should mark concurrent render with suspense that resolves", function()
			local fakeSuspensePromise = Promise.resolve(true)
			local function Example()
				error(fakeSuspensePromise)
			end

			ReactTestRenderer.create(
				React.createElement(
					React.Suspense,
					{ fallback = nil },
					React.createElement(Example)
				),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(Scheduler).toFlushUntilNextPaint({})

			jestExpect(marks).toEqual({
				"--render-start-512",
				"--suspense-suspend-0-Example",
				"--render-stop",
				"--commit-start-512",
				"--layout-effects-start-512",
				"--layout-effects-stop",
				"--commit-stop",
			})

			Array.splice(marks, 1)

			fakeSuspensePromise:await()
			jestExpect(marks).toEqual({ "--suspense-resolved-0-Example" })
		end)

		-- @gate enableSchedulingProfiler
		-- ROBLOX FIXME: Example suspended while rendering, but no fallback UI was specified
		xit("should mark concurrent render with suspense that rejects", function()
			local fakeSuspensePromise = Promise.reject(Error.new("error"))
			local function Example()
				error(fakeSuspensePromise)
			end

			ReactTestRenderer.create(
				React.createElement(
					React.Suspense,
					{ fallback = nil },
					React.createElement(Example)
				),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(Scheduler).toFlushUntilNextPaint({})

			jestExpect(marks).toEqual({
				"--render-start-512",
				"--suspense-suspend-0-Example",
				"--render-stop",
				"--commit-start-512",
				"--layout-effects-start-512",
				"--layout-effects-stop",
				"--commit-stop",
			})

			Array.splice(marks, 1)

			-- await jestExpect(fakeSuspensePromise).rejects.toThrow()
			jestExpect(function()
				fakeSuspensePromise:expect()
			end).toThrow()
			jestExpect(marks).toEqual({ "--suspense-rejected-0-Example" })
		end)

		-- @gate enableSchedulingProfiler
		it("should mark cascading class component state updates", function()
			local Example = React.Component:extend("Example")
			function Example:init()
				self.state = { didMount = false }
			end
			function Example:componentDidMount()
				self:setState({ didMount = true })
			end
			function Example:render()
				return nil
			end

			ReactTestRenderer.create(
				React.createElement(Example),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(Scheduler).toFlushUntilNextPaint({})

			jestExpect(marks).toEqual({
				"--render-start-512",
				"--render-stop",
				"--commit-start-512",
				"--layout-effects-start-512",
				"--schedule-state-update-1-Example",
				"--layout-effects-stop",
				"--render-start-1",
				"--render-stop",
				"--commit-start-1",
				"--commit-stop",
				"--commit-stop",
			})
		end)

		-- @gate enableSchedulingProfiler
		it("should mark cascading class component force updates", function()
			local Example = React.Component:extend("Example")
			function Example:componentDidMount()
				self:forceUpdate()
			end
			function Example:render()
				return nil
			end

			ReactTestRenderer.create(
				React.createElement(Example),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(Scheduler).toFlushUntilNextPaint({})

			jestExpect(marks).toEqual({
				"--render-start-512",
				"--render-stop",
				"--commit-start-512",
				"--layout-effects-start-512",
				"--schedule-forced-update-1-Example",
				"--layout-effects-stop",
				"--render-start-1",
				"--render-stop",
				"--commit-start-1",
				"--commit-stop",
				"--commit-stop",
			})
		end)

		-- @gate enableSchedulingProfiler
		it("should mark render phase state updates for class component", function()
			local Example = React.Component:extend("Example")
			function Example:init()
				self.state = { didRender = false }
			end
			function Example:render()
				if self.state.didRender == false then
					self:setState({ didRender = true })
				end
				return nil
			end

			ReactTestRenderer.create(
				React.createElement(Example),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toErrorDev("Cannot update during an existing state transition")

			-- ROBLOX FIXME: no way to gate feature tests like upstream
			-- gate(({old}) =>
			--   old
			--     ? jestExpect(marks).toContain('--schedule-state-update-1024-Example')
			--     : jestExpect(marks).toContain('--schedule-state-update-512-Example'),
			-- )
		end)

		-- @gate enableSchedulingProfiler
		it("should mark render phase force updates for class component", function()
			local Example = React.Component:extend("Example")
			function Example:init()
				self.state = { didRender = false }
			end
			function Example:render()
				if self.state.didRender == false then
					self:forceUpdate(function()
						self:setState({ didRender = true })
					end)
				end
				return nil
			end

			ReactTestRenderer.create(
				React.createElement(Example),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toErrorDev("Cannot update during an existing state transition")

			-- ROBLOX TODO: we have no way to gate tests on features like upstream
			-- gate(({old}) =>
			--   old
			--     ? jestExpect(marks).toContain('--schedule-forced-update-1024-Example')
			--     : jestExpect(marks).toContain('--schedule-forced-update-512-Example'),
			-- )
		end)

		-- @gate enableSchedulingProfiler
		it("should mark cascading layout updates", function()
			local function Example()
				local didMount, setDidMount = React.useState(false)
				React.useLayoutEffect(function()
					setDidMount(true)
				end, {})
				return didMount
			end

			ReactTestRenderer.create(
				React.createElement(Example),
				{ unstable_isConcurrent = true }
			)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
			})

			Array.splice(marks, 1)

			jestExpect(Scheduler).toFlushUntilNextPaint({})

			jestExpect(marks).toEqual({
				"--render-start-512",
				"--render-stop",
				"--commit-start-512",
				"--layout-effects-start-512",
				"--schedule-state-update-1-Example",
				"--layout-effects-stop",
				"--render-start-1",
				"--render-stop",
				"--commit-start-1",
				"--commit-stop",
				"--commit-stop",
			})
		end)

		-- @gate enableSchedulingProfiler
		it("should mark cascading passive updates", function()
			local function Example()
				local didMount, setDidMount = React.useState(false)
				React.useEffect(function()
					setDidMount(true)
				end, {})
				return didMount
			end

			ReactTestRenderer.unstable_concurrentAct(function()
				ReactTestRenderer.create(
					React.createElement(Example),
					{ unstable_isConcurrent = true }
				)
			end)

			jestExpect(marks).toEqual({
				"--react-init-" .. tostring(ReactVersion),
				"--schedule-render-512",
				"--render-start-512",
				"--render-stop",
				"--commit-start-512",
				"--layout-effects-start-512",
				"--layout-effects-stop",
				"--commit-stop",
				"--passive-effects-start-512",
				"--schedule-state-update-1024-Example",
				"--passive-effects-stop",
				"--render-start-1024",
				"--render-stop",
				"--commit-start-1024",
				"--commit-stop",
			})
		end)

		-- @gate enableSchedulingProfiler
		it("should mark render phase updates", function()
			local function Example()
				local didRender, setDidRender = React.useState(false)
				if not didRender then
					setDidRender(true)
				end
				return didRender
			end

			ReactTestRenderer.unstable_concurrentAct(function()
				ReactTestRenderer.create(
					React.createElement(Example),
					{ unstable_isConcurrent = true }
				)
			end)

			-- ROBLOX TODO: we don't have a way to gate tests based on features like upstream does
			-- gate(({old}) =>
			--   old
			--     ? jestExpect(marks).toContain('--schedule-state-update-1024-Example')
			--     : jestExpect(marks).toContain('--schedule-state-update-512-Example'),
			-- )
		end)
	end)
end
