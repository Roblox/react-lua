-- upstream: https://github.com/facebook/react/blob/69060e1da6061af845162dcf6854a5d9af28350a/packages/react-reconciler/src/__tests__/ReactTopLevelText-test.js
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

  it("should render a component returning strings directly from render", function()
    -- FIXME: expect coercion
    local expect: any = expect
    local Text = function(props) return props.value end
    ReactNoop.render(
      React.createElement(Text, {value="foo"})
    )
    expect(Scheduler).toFlushWithoutYielding()
    -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
    -- expect(ReactNoop).toMatchRenderedOutput('foo')
    local renderedOutput = ReactNoop.getChildren()
    expect(#renderedOutput).to.equal(1)
    expect(renderedOutput[1].text).to.equal('foo')
  end)

  it("should render a component returning numbers directly from renderß", function()
    -- FIXME: expect coercion
    local expect: any = expect
    local Text = function(props) return props.value end
    ReactNoop.render(
      React.createElement(Text, {value=10})
    )
    expect(Scheduler).toFlushWithoutYielding()
    -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
    -- expect(ReactNoop).toMatchRenderedOutput('10')
    local renderedOutput = ReactNoop.getChildren()
    expect(#renderedOutput).to.equal(1)
    expect(renderedOutput[1].text).to.equal('10')
  end)
end
