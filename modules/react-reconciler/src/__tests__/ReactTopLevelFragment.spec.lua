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
--!strict

local Workspace = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler

-- This is a new feature in Fiber so I put it in its own test file. It could
-- probably move to one of the other test files once it is official.
return function()
  local RobloxJest = require(Workspace.RobloxJest)

  beforeEach(function()
    RobloxJest.resetModules()

    React = require(Workspace.React)
    ReactNoop = require(Workspace.ReactNoopRenderer)
    -- deviation: In react, jest mocks Scheduler -> unstable_mock; since
    -- unstable_mock depends on the real Scheduler, and our mock
    -- functionality isn't smart enough to prevent self-requires, we simply
    -- require the mock entry point directly for use in tests
    Scheduler = require(Workspace.Scheduler.unstable_mock)
  end)

  it("should render a simple fragment at the top of a component", function()
    -- FIXME: expect coercion
    local expect: any = expect
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
    expect(Scheduler).toFlushWithoutYielding()
  end)

  it("should preserve state when switching from a single child", function()
    -- FIXME: expect coercion
    local expect: any = expect
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
    expect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance

    expect(instanceA).never.to.equal(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    expect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    expect(instanceB).to.equal(instanceA)
  end)

  it("should not preserve state when switching to a nested array", function()
    -- FIXME: expect coercion
    local expect: any = expect
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
    expect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance
    expect(instanceA).never.to.equal(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    expect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    expect(instanceB).never.to.equal(instanceA)
  end)

  it("preserves state if an implicit key slot switches from/to nil", function()
    -- FIXME: expect coercion
    local expect: any = expect
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
    expect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance

    expect(instanceA).never.to.equal(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    expect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    expect(instanceB).to.equal(instanceA)

    ReactNoop.render(React.createElement(Fragment, {condition = false}))
    expect(Scheduler).toFlushWithoutYielding()

    local instanceC = instance

    expect(instanceC).to.equal(instanceA)
  end)

  it("should preserve state in a reorder", function()
    -- FIXME: expect coercion
    local expect: any = expect
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
    expect(Scheduler).toFlushWithoutYielding()

    local instanceA = instance
    expect(instanceA).never.to.equal(nil)

    ReactNoop.render(React.createElement(Fragment, {condition = true}))
    expect(Scheduler).toFlushWithoutYielding()

    local instanceB = instance

    expect(instanceB).to.equal(instanceA)
  end)
end
