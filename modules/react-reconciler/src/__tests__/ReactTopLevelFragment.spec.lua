-- upstream: https://github.com/facebook/react/blob/69060e1da6061af845162dcf6854a5d9af28350a/packages/react-reconciler/src/__tests__/ReactTopLevelFragment-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]
local Workspace = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler

-- This is a new feature in Fiber so I put it in its own test file. It could
-- probably move to one of the other test files once it is official.
return function()
  local RobloxJest = require(Workspace.RobloxJest)
	local Packages = Workspace.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

  beforeEach(function()
    RobloxJest.resetModules()
    -- deviation: In react, jest _always_ mocks Scheduler -> unstable_mock;
    -- in our case, we need to do it anywhere we want to use the scheduler,
    -- directly or indirectly, until we have some form of bundling logic
    RobloxJest.mock(Workspace.Scheduler, function()
      return require(Workspace.Scheduler.unstable_mock)
    end)

    React = require(Workspace.React)
    ReactNoop = require(Workspace.ReactNoopRenderer)
    Scheduler = require(Workspace.Scheduler)
  end)

  it("should render a simple fragment at the top of a component", function()
    local function Fragment()
      return {
        a = React.createElement("TextLabel", {
          Text = "Hello",
        }),
        b = React.createElement("TextLabel", {
          Text = "World"
        }),
      }
    end
    ReactNoop.render(React.createElement(Fragment))
    jestExpect(Scheduler).toFlushWithoutYielding()
  end)

  it("should preserve state when switching from a single child", function()
    local instance = nil

    local Stateful = React.Component:extend("Stateful")
    function Stateful:render()
        instance = self
        return React.createElement("TextLabel", {Text="Hello"})
    end

    local function Fragment(props)
      if props.condition then
        return React.createElement(Stateful, {key="a"})
      else
        return {
          React.createElement(Stateful, {key="a"}),
          React.createElement("Frame", {key="b"},
            React.createElement("TextLabel", {Text="World"})
          )
        }
      end
    end

    ReactNoop.render(React.createElement(Fragment))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance

    jestExpect(instanceA).never.toBe(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    jestExpect(instanceB).toBe(instanceA)
  end)

  it("should not preserve state when switching to a nested array", function()
    local instance = nil

    local Stateful = React.Component:extend("Stateful")
    function Stateful:render()
        instance = self
        return React.createElement("TextLabel", {Text="Hello"})
    end

    local function Fragment(props)
      if props.condition then
        return React.createElement(Stateful, {key="a"})
      else
        return {{
          React.createElement(Stateful, {key="a"}),
          React.createElement("Frame", {key="b"},
            React.createElement("TextLabel", {Text="World"})
          )},
          React.createElement("Frame", {key="c"})
        }
      end
    end

    ReactNoop.render(React.createElement(Fragment))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance
    jestExpect(instanceA).never.toBe(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    jestExpect(instanceB).never.toBe(instanceA)
  end)

  it("preserves state if an implicit key slot switches from/to nil", function()
    local instance = nil

    local Stateful = React.Component:extend("Stateful")
    function Stateful:render()
        instance = self
        return React.createElement("TextLabel", {Text="World"})
    end

    local function Fragment(props)
      if props.condition then
        return {
          nil,
          React.createElement(Stateful, {key="a"})
        }
      else
        return {
          React.createElement("Frame", {key="b"},
            React.createElement("TextLabel", {Text="Hello"})
          ),
          React.createElement(Stateful, {key="a"})
        }
      end
    end

    ReactNoop.render(React.createElement(Fragment))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance

    jestExpect(instanceA).never.toBe(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    jestExpect(instanceB).toBe(instanceA)

    ReactNoop.render(React.createElement(Fragment, {condition = false}))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceC = instance

    jestExpect(instanceC).toBe(instanceA)
  end)

  it("should preserve state in a reorder", function()
    local instance = nil

    local Stateful = React.Component:extend("Stateful")
    function Stateful:render()
        instance = self
        return React.createElement("TextLabel", {Text="Hello"})
    end

    local function Fragment(props)
      if props.condition then
        return {{
          React.createElement("Frame", {key="b"},
            React.createElement("TextLabel", {Text="World"})
          ),
          React.createElement(Stateful, {key="a"})
        }}
      else
        return {{
          React.createElement(Stateful, {key="a"}),
          React.createElement("Frame", {key="b"},
            React.createElement("TextLabel", {Text="World"})
          )},
          React.createElement("Frame", {key="c"})
        }
      end
    end

    ReactNoop.render(React.createElement(Fragment))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance
    jestExpect(instanceA).never.toBe(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    jestExpect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    jestExpect(instanceB).toBe(instanceA)
  end)
end
