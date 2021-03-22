-- upstream: 
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]
--!strict

-- ROBLOX deviation: This test file was adapted from `react-dom` and generalized
-- to `react-reconciler` using `react-noop` instead of the dom renderer
local React
local ReactNoop

return function()
  local Workspace = script.Parent.Parent.Parent
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
  end)

  -- ROBLOX deviation: This test can hit succeed erroneously in luau, since
  -- table iteration order is unpredictable; with only two elements and no
  -- guaranteed order, react might happen to assign the right values even if key
  -- behavior isn't working.
  -- it("should allow key property to express identity", function()
  --   local ref = React.createRef(nil)
  --   local function Component(props)
  --     return React.createElement("div", {ref=ref},
  --       React.createElement("div", {key=props.swap and "banana" or "apple", prop="Hello"}),
  --       React.createElement("div", {key=props.swap and "apple" or "banana", prop="World"})
  --     )
  --   end

  --   local function childrenByProp(children)
  --     local byProp = {}
  --     for _, instance in ipairs(children) do
  --       byProp[instance.prop] = instance
  --     end
  --     return byProp
  --   end

  --   -- ROBLOX deviation: Use react-noop + act instead of rendering into document
  --   ReactNoop.act(function()
  --     ReactNoop.render(React.createElement(Component))
  --   end)
  --   local origChildren = childrenByProp(ref.current.children)
  --   ReactNoop.act(function()
  --     ReactNoop.render(React.createElement(Component, {swap=true}))
  --   end)
  --   local newChildren = childrenByProp(ref.current.children)

  --   -- After rendering with `swap=true`, the keys will have switched and the
  --   -- prop values will correspond to the opposite children
  --   expect(origChildren["Hello"]).to.equal(newChildren["World"])
  --   expect(origChildren["World"]).to.equal(newChildren["Hello"])
  -- end)

  -- ROBLOX deviation: Replaces the above test. This new test verifies the
  -- behavior expected above, but uses enough table keys to greatly reduce the
  -- likelihood of coincidental success.
  it("should allow key property to express identity", function()
    local ref = React.createRef(nil)
    local function Component(props)
      local children = {}
      for i = 1, 50 do
        local key = props.invert and tostring(51 - i) or tostring(i)
        children[i] = React.createElement("div", {key=key, prop=i})
      end

      return React.createElement("div", {ref=ref}, unpack(children))
    end

    local function childrenByProp(children)
      local byProp = {}
      for _, instance in ipairs(children) do
        byProp[instance.prop] = instance
      end
      return byProp
    end

    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component))
    end)
    local origChildren = childrenByProp(ref.current.children)
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component, {invert=true}))
    end)
    local newChildren = childrenByProp(ref.current.children)

    -- After rendering with `invert=true`, the keys will have switched and the
    -- prop values will correspond to the opposite children
    for i = 1, 50 do
      expect(origChildren[i]).to.equal(newChildren[51-i])
      expect(origChildren[51-i]).to.equal(newChildren[i])
    end
  end)

  -- ROBLOX deviation: Verify equivalent behavior with table keys, an adaptation
  -- to be compatible with currently-released Roact
  it("should allow table key to express identity", function()
    local ref = React.createRef(nil)
    local function Component(props)
      local children = {}
      for i = 1, 50 do
        local key = props.invert and tostring(51 - i) or tostring(i)
        children[key] = React.createElement("div", {prop=i})
      end

      return React.createElement("div", {ref=ref}, children)
    end

    local function childrenByProp(children)
      local byProp = {}
      for _, instance in ipairs(children) do
        byProp[instance.prop] = instance
      end
      return byProp
    end

    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component))
    end)
    local origChildren = childrenByProp(ref.current.children)
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component, {invert=true}))
    end)
    local newChildren = childrenByProp(ref.current.children)

    -- After rendering with `invert=true`, the keys will have switched and the
    -- prop values will correspond to the opposite children
    for i = 1, 50 do
      expect(origChildren[i]).to.equal(newChildren[51-i])
      expect(origChildren[51-i]).to.equal(newChildren[i])
    end
  end)

  it("should defer to provided key if both are present", function()
    local ref = React.createRef(nil)
    local function Component(props)
      local children = {}
      for i = 1, 50 do
        local key = props.invert and tostring(51 - i) or tostring(i)
        -- provide both explicit key and table key, where table-key does not
        -- obey the `invert` prop and should not be the one that's used.
        children[tostring(i)] = React.createElement("div", {key=key, prop=i})
      end

      return React.createElement("div", {ref=ref}, children)
    end

    local function childrenByProp(children)
      local byProp = {}
      for _, instance in ipairs(children) do
        byProp[instance.prop] = instance
      end
      return byProp
    end

    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component))
    end)
    local origChildren = childrenByProp(ref.current.children)
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component, {invert=true}))
    end)
    local newChildren = childrenByProp(ref.current.children)

    -- After rendering with `invert=true`, the keys will have switched and the
    -- prop values will correspond to the opposite children
    for i = 1, 50 do
      expect(origChildren[i]).to.equal(newChildren[51-i])
      expect(origChildren[51-i]).to.equal(newChildren[i])
    end
  end)

  it('should use composite identity', function()
    local Wrapper = React.Component:extend("Wrapper")
    function Wrapper:render()
      return React.createElement("a", nil, self.props.children)
    end

    local ref1 = React.createRef(nil)
    local ref2 = React.createRef(nil)
    -- ROBLOX deviation: Use react-noop + act instead of rendering into document
    ReactNoop.act(function()
      ReactNoop.render(
        React.createElement(Wrapper, {key="wrap1"},
          React.createElement("span", {ref=ref1})
        )
      )
    end)
    ReactNoop.act(function()
      ReactNoop.render(
        React.createElement(Wrapper, {key="wrap2"},
          React.createElement("span", {ref=ref2})
        )
      )
    end)

    expect(ref1.current).never.to.equal(ref2.current)
  end)

  -- local function renderAComponentWithKeyIntoContainer(key, container)
  --   local ref = React.createRef()

  --   local Wrapper = React.Component:extend("Wrapper")
  --   function Wrapper:render()
  --     return React.createElement("div", nil,
  --       React.createElement("span", {ref=ref, key=key})
  --     )
  --   end

  --   ReactNoop.act(function()
  --     ReactNoop.render(React.createElement(Wrapper), container)
  --   end)
  --   local span = ref.current
  --   expect(span).never.to.equal(nil)
  -- end

  -- ROBLOX FIXME: test does not apply to ReactNoop; we should port it to rely
  -- on the Roblox renderer instead
  -- it('should allow any character as a key, in a detached parent', function()
  --   local detachedContainer = document.createElement('div')
  --   renderAComponentWithKeyIntoContainer("<'WEIRD/&\\key'>", detachedContainer)
  -- end)

  -- ROBLOX FIXME: test does not apply to ReactNoop; we should port it to rely
  -- on the Roblox renderer instead
  -- it('should allow any character as a key, in an attached parent', function()
  --   -- This test exists to protect against implementation details that
  --   -- incorrectly query escaped IDs using DOM tools like getElementById.
  --   local attachedContainer = document.createElement('div')
  --   document.body.appendChild(attachedContainer)

  --   renderAComponentWithKeyIntoContainer("<'WEIRD/&\\key'>", attachedContainer)

  --   document.body.removeChild(attachedContainer)
  -- end)

  -- ROBLOX deviation: this test not relevant to Roblox or reconciler, since
  -- script execution doesn't work this way to begin with
  -- it('should not allow scripts in keys to execute', function()
  --   local h4x0rKey =
  --     '"><script>window[\'YOUVEBEENH4X0RED\']=true;</script><div id="'

  --   local attachedContainer = document.createElement('div')
  --   document.body.appendChild(attachedContainer)

  --   renderAComponentWithKeyIntoContainer(h4x0rKey, attachedContainer)

  --   document.body.removeChild(attachedContainer)

  --   -- If we get this far, make sure we haven't executed the code
  --   expect(window.YOUVEBEENH4X0RED).toBe(undefined)
  -- end)

  it('should let restructured components retain their uniqueness', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local instance0 = React.createElement("span")
    local instance1 = React.createElement("span")
    local instance2 = React.createElement("span")

    local TestComponent = React.Component:extend("TestComponent")
    function TestComponent:render()
      return React.createElement("div", nil,
        instance2,
        self.props.children[1],
        self.props.children[2]
      )
    end

    local TestContainer = React.Component:extend("TestContainer")
    function TestContainer:render()
      return React.createElement(TestComponent, nil,
        instance0,
        instance1
      )
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(TestContainer))
      end)
    end).never.toThrow()
  end)

  it('should let nested restructures retain their uniqueness', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local instance0 = React.createElement("span")
    local instance1 = React.createElement("span")
    local instance2 = React.createElement("span")

    local TestComponent = React.Component:extend("TestComponent")
    function TestComponent:render()
      return React.createElement("div", nil,
        instance2,
        self.props.children[1],
        self.props.children[2]
      )
    end

    local TestContainer = React.Component:extend("TestContainer")
    function TestContainer:render()
      return React.createElement("div", nil,
        React.createElement(TestComponent, nil,
          instance0,
          instance1
        )
      )
    end 

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(TestContainer))
      end)
    end).never.toThrow()
  end)

  it('should let text nodes retain their uniqueness', function()
    local TestComponent = React.Component:extend("TestComponent")
    function TestComponent:render()
      return React.createElement("div", nil,
        self.props.children,
        React.createElement("span")
      )
    end

    local TestContainer = React.Component:extend("TestContainer")
    function TestContainer:render()
      return React.createElement(TestComponent, nil,
        React.createElement("div"),
        {'second'}
      )
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(TestContainer))
      end)
    end).never.to.throw()
  end)

  it('should retain key during updates in composite components', function()
    local ref = React.createRef(nil)
    local swap

    local TestComponent = React.Component:extend("TestComponent")
    function TestComponent:render()
      return React.createElement("div", {ref=ref}, self.props.children)
    end

    local TestContainer = React.Component:extend("TestContainer")
    function TestContainer:init()
      self.state = {swapped=false}

      swap = function()
        self:setState({swapped=true})
      end
    end

    function TestContainer:render()
      return React.createElement(TestComponent, nil,
        self.state.swapped and self.props.second or self.props.first,
        self.state.swapped and self.props.first or self.props.second
      )
    end

    local instance0 = React.createElement("span", {key="A", prop="Hello"})
    local instance1 = React.createElement("span", {key="B", prop="World"})

    local function childrenByProp(children)
      local byProp = {}
      for _, instance in ipairs(children) do
        byProp[instance.prop] = instance
      end
      return byProp
    end

    ReactNoop.act(function()
      ReactNoop.render(
        React.createElement(TestContainer, {first=instance0, second=instance1})
      )
    end)

    local originalChildren = childrenByProp(ref.current.children)
    swap()
    local newChildren = childrenByProp(ref.current.children)

    expect(originalChildren["Hello"]).to.equal(newChildren["Hello"])
    expect(originalChildren["World"]).to.equal(newChildren["World"])
  end)

  it('should not allow implicit and explicit keys to collide', function()
    local component = function(_props)
      return React.createElement("div", nil,
        React.createElement("span"),
        React.createElement("span", {key = "1"})
      )
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(
          React.createElement(component)
        )
      end)
    end).never.to.throw()
  end)
end
