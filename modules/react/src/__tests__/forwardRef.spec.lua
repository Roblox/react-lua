--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]
--!strict

return function()
  local Workspace = script.Parent.Parent.Parent
  local Packages = Workspace.Parent
  local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

  local Cryo = require(Packages.Cryo)
  local RobloxJest = require(Workspace.RobloxJest)

  -- local PropTypes
  local React
  local ReactNoop
  local Scheduler

  beforeEach(function()
    RobloxJest.resetModules()
    -- deviation: In react, jest _always_ mocks Scheduler -> unstable_mock;
    -- in our case, we need to do it anywhere we want to use the scheduler,
    -- until we have some form of bundling logic
    RobloxJest.mock(Workspace.Scheduler, function()
      return require(Workspace.Scheduler.unstable_mock)
    end)

    -- PropTypes = require('prop-types')
    React = require(Workspace.React)
    ReactNoop = require(Workspace.ReactNoopRenderer)
    Scheduler = require(Workspace.Scheduler)
  end)

  it("should update refs when switching between children", function()
    local function FunctionComponent(props)
      local forwardedRef = props.forwardedRef
      local setRefOnDiv = props.setRefOnDiv
      -- deviation: clearer to express this way, since we don't have real ternaries
      local firstRef, secondRef
      if setRefOnDiv then
        firstRef = forwardedRef
      else
        secondRef = forwardedRef
      end
      return React.createElement("section", nil,
        React.createElement("div", {ref=firstRef},
          React.createElement("TextLabel", {Text="First"})
        ),
        React.createElement("span", {ref=secondRef},
          React.createElement("TextLabel", {Text="Second"})
        )
      )
    end

    local RefForwardingComponent = React.forwardRef(function(props, ref)
      return React.createElement(FunctionComponent, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    local ref = React.createRef()

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, setRefOnDiv=true}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(ref.current.type).toBe("div")

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, setRefOnDiv=false}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(ref.current.type).toBe("span")
  end)

  it("should support rendering nil", function()
    local RefForwardingComponent = React.forwardRef(function(props, ref) return nil end)

    local ref = React.createRef()

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(ref.current).toBe(nil)
  end)

  it('should support rendering nil for multiple children', function()
    local RefForwardingComponent = React.forwardRef(function(props, ref) return nil end)

    local ref = React.createRef()

    ReactNoop.render(
      React.createElement("div", nil, {
        React.createElement("div"),
        React.createElement(RefForwardingComponent, {ref=ref}),
        React.createElement("div"),
      })
    )
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(ref.current).toBe(nil)
  end)

  -- ROBLOX TODO: PropTypes not yet supported
  xit('should support propTypes and defaultProps', function()
    -- local function FunctionComponent(props)
    --   local forwardedRef = props.forwardedRef
    --   local optional = props.optional
    --   local required = props.required
    --   return React.createElement("div", {ref=forwardedRef}, {
    --     optional,
    --     required,
    --   })
    -- end

    -- local RefForwardingComponent = React.forwardRef(function NamedFunction(
    --   props,
    --   ref,
    -- )
    --   return <FunctionComponent {...props} forwardedRef={ref} />
    -- })
    -- RefForwardingComponent.propTypes = {
    --   optional: PropTypes.string,
    --   required: PropTypes.string.isRequired,
    -- end
    -- RefForwardingComponent.defaultProps = {
    --   optional: 'default',
    -- end

    -- local ref = React.createRef()

    -- ReactNoop.render(
    --   <RefForwardingComponent ref={ref} optional="foo" required="bar" />,
    -- )
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(ref.current.children).toEqual([
    --   {text: 'foo', hidden: false},
    --   {text: 'bar', hidden: false},
    -- ])

    -- ReactNoop.render(<RefForwardingComponent ref={ref} required="foo" />)
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(ref.current.children).toEqual([
    --   {text: 'default', hidden: false},
    --   {text: 'foo', hidden: false},
    -- ])

    -- jestExpect(() =>
    --   ReactNoop.render(<RefForwardingComponent ref={ref} optional="foo" />),
    -- ).toErrorDev(
    --   'Warning: Failed prop type: The prop `required` is marked as required in ' +
    --     '`ForwardRef(NamedFunction)`, but its value is `undefined`.\n' +
    --     '    in NamedFunction (at **)',
    -- )
  end)

  it("should warn if not provided a callback during creation", function()
    -- deviation: no `undefined` in Lua
    -- jestExpect(function()
    --   React.forwardRef(nil)
    -- end).toErrorDev(
    --   "forwardRef requires a render function but was given undefined.",
    --   {withoutStack: true},
    -- )
    jestExpect(function()
      React.forwardRef(nil)
    end).toErrorDev(
      "forwardRef requires a render function but was given nil.",
      {withoutStack = true}
    )
    jestExpect(function()
      React.forwardRef("foo")
    end).toErrorDev(
      "forwardRef requires a render function but was given string.",
      {withoutStack = true}
    )
  end)

  it("should warn if no render function is provided", function()
    jestExpect(
      React.forwardRef
    ).toErrorDev(
      "forwardRef requires a render function but was given nil.",
      {withoutStack = true}
    )
  end)

  -- ROBLOX deviation: Functions can't have attributes; this test isn't needed
  xit("should warn if the render function provided has propTypes or defaultProps attributes", function()
    -- function renderWithPropTypes(props, ref)
    --   return nil
    -- end
    -- renderWithPropTypes.propTypes = {}

    -- function renderWithDefaultProps(props, ref)
    --   return nil
    -- end
    -- renderWithDefaultProps.defaultProps = {}

    -- jestExpect(function()
    --   React.forwardRef(renderWithPropTypes)
    -- ).toErrorDev(
    --   "forwardRef render functions do not support propTypes or defaultProps. " ..
    --     "Did you accidentally pass a React component?",
    --   {withoutStack: true}
    -- )
    -- jestExpect(function()
    --   React.forwardRef(renderWithDefaultProps)
    -- ).toErrorDev(
    --   "forwardRef render functions do not support propTypes or defaultProps. " ..
    --     "Did you accidentally pass a React component?",
    --   {withoutStack: true}
    -- )
  end)

  -- ROBLOX deviation: Can't know function arity in lua
  xit("should not warn if the render function provided does not use any parameter", function()
    -- React.forwardRef(function arityOfZero()
    --   return <div ref={arguments[1]} />
    -- })
  end)

  -- ROBLOX deviation: Can't know function arity in lua
  xit("should warn if the render function provided does not use the forwarded ref parameter", function()
    -- local arityOfOne = props => <div {...props} />

    -- jestExpect(() =>
    --   React.forwardRef(arityOfOne),
    -- ).toErrorDev(
    --   'forwardRef render functions accept exactly two parameters: props and ref. ' +
    --     'Did you forget to use the ref parameter?',
    --   {withoutStack: true},
    -- )
  end)

  -- ROBLOX deviation: Can't know function arity in lua
  xit("should not warn if the render function provided use exactly two parameters", function()
    -- local arityOfTwo = (props, ref) => <div {...props} ref={ref} />
    -- React.forwardRef(arityOfTwo)
  end)

  -- ROBLOX deviation: Can't know function arity in lua
  xit("should warn if the render function provided expects to use more than two parameters", function()
    -- local arityOfThree = (props, ref, x) => <div {...props} ref={ref} x={x} />

    -- jestExpect(() =>
    --   React.forwardRef(arityOfThree),
    -- ).toErrorDev(
    --   "forwardRef render functions accept exactly two parameters: props and ref. " +
    --     "Any additional parameter will be undefined.",
    --   {withoutStack: true},
    -- )
  end)

  -- ROBLOX TODO: Support PropTypes
  xit('should honor a displayName if set on the forwardRef wrapper in warnings', function()
    -- local Component = function(props)
    --   return React.createElement("div", props)
    -- end

    -- local RefForwardingComponent = React.forwardRef(function(props, ref)
    --   return React.createElement(Component, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    -- end)

    -- RefForwardingComponent.displayName = 'Foo'

    -- RefForwardingComponent.propTypes = {
    --   optional: PropTypes.string,
    --   required: PropTypes.string.isRequired,
    -- end

    -- RefForwardingComponent.defaultProps = {
    --   optional: 'default',
    -- end

    -- local ref = React.createRef()

    -- jestExpect(() =>
    --   ReactNoop.render(<RefForwardingComponent ref={ref} optional="foo" />),
    -- ).toErrorDev(
    --   'Warning: Failed prop type: The prop `required` is marked as required in ' +
    --     '`Foo`, but its value is `undefined`.\n' +
    --     '    in Foo (at **)',
    -- )
  end)

  -- ROBLOX deviation: Cannot add displayName attribute to function
  xit('should honor a displayName in stacks if set on the inner function', function()
    -- local Component = props => <div {...props} />

    -- local inner = (props, ref) => <Component {...props} forwardedRef={ref} />
    -- inner.displayName = 'Foo'
    -- local RefForwardingComponent = React.forwardRef(inner)

    -- RefForwardingComponent.propTypes = {
    --   optional: PropTypes.string,
    --   required: PropTypes.string.isRequired,
    -- end

    -- RefForwardingComponent.defaultProps = {
    --   optional: 'default',
    -- end

    -- local ref = React.createRef()

    -- jestExpect(() =>
    --   ReactNoop.render(<RefForwardingComponent ref={ref} optional="foo" />),
    -- ).toErrorDev(
    --   'Warning: Failed prop type: The prop `required` is marked as required in ' +
    --     '`ForwardRef(Foo)`, but its value is `undefined`.\n' +
    --     '    in Foo (at **)',
    -- )
  end)

  -- ROBLOX FIXME: Passes in non-DEV, in DEV fails with 'Expected value "2", got "1"'
  local skipIfDev = (function()
    if _G.__DEV__ then
      return itSKIP
    end
    return it
  end)()
  skipIfDev("should not bailout if forwardRef is not wrapped in memo", function()
    local Component = function(props)
      return React.createElement("div", props)
    end

    local renderCount = 0

    local RefForwardingComponent = React.forwardRef(function(props, ref)
      renderCount += 1
      return React.createElement(Component, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    local ref = React.createRef()

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, optional="foo"}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, optional="foo"}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(renderCount).toBe(_G.__DEV__ and 4 or 2)
  end)

  -- ROBLOX TODO: MemoComponent unimplemented (ReactFiberBeginWork.new:3454)
  xit("should bailout if forwardRef is wrapped in memo", function()
    local Component = function(props)
      return React.createElement("div", {ref=props.forwardedRef})
    end

    local renderCount = 0

    local RefForwardingComponent = React.memo(
      React.forwardRef(function(props, ref)
        renderCount += 1
        return React.createElement(Component, Cryo.Dictionary.join(props, {forwardedRef=ref}))
      end)
    )

    local ref = React.createRef()

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, optional="foo"}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)

    jestExpect(ref.current.type).toBe("div")

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, optional="foo"}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)

    local differentRef = React.createRef()

    ReactNoop.render(
      React.createElement(RefForwardingComponent, {ref=differentRef, optional="foo"})
    )
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(renderCount).toBe(_G.__DEV__ and 4 or 2)

    jestExpect(ref.current).toBe(nil)
    jestExpect(differentRef.current.type).toBe("div")

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, optional="bar"}))
    jestExpect(Scheduler).toFlushWithoutYielding()
    jestExpect(renderCount).toBe(_G.__DEV__ and 6 or 3)
  end)

  -- ROBLOX TODO: MemoComponent unimplemented (ReactFiberBeginWork.new:3454)
  xit('should custom memo comparisons to compose', function()
    -- local Component = function(props)
    --   return React.createElement("div", {ref=props.forwardedRef})
    -- end

    -- local renderCount = 0

    -- local RefForwardingComponent = React.memo(
    --   React.forwardRef(function(props, ref)
    --     renderCount += 1
    --     return React.createElement(Component, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    --   end),
    --   function(o, p)
    --     return o.a == p.a and o.b == p.b
    --   end
    -- )


    -- local ref = React.createRef()

    -- ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, a="0", b="0", c="1"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)

    -- jestExpect(ref.current.type).toBe('div')

    -- -- Changing either a or b rerenders
    -- ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, a="0", b="1", c="1"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 4 or 2)

    -- -- Changing c doesn't rerender
    -- ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, a="0", b="1", c="2"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 4 or 2)

    -- local ComposedMemo = React.memo(
    --   RefForwardingComponent,
    --   function(o, p)
    --     return o.a == p.a and o.c == p.c
    --   end
    -- )

    -- ReactNoop.render(React.createElement(ComposedMemo, {ref=ref, a="0", b="0", c="0"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 6 or 3)

    -- -- Changing just b no longer updates
    -- ReactNoop.render(React.createElement(ComposedMemo, {ref=ref, a="0", b="1", c="0"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 6 or 3)

    -- -- Changing just a and c updates
    -- ReactNoop.render(React.createElement(ComposedMemo, {ref=ref, a="2", b="2", c="2"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 8 or 4)

    -- -- Changing just c does not update
    -- ReactNoop.render(React.createElement(ComposedMemo, {ref=ref, a="2", b="2", c="3"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 8 or 4)

    -- -- Changing ref still rerenders
    -- local differentRef = React.createRef()

    -- ReactNoop.render(React.createElement(ComposedMemo, {ref=differentRef, a="2", b="2", c="3"}))
    -- jestExpect(Scheduler).toFlushWithoutYielding()
    -- jestExpect(renderCount).toBe(_G.__DEV__ and 10 or 5)

    -- jestExpect(ref.current).toBe(nil)
    -- jestExpect(differentRef.current.type).toBe("div")
  end)

  -- ROBLOX TODO: MemoComponent unimplemented (ReactFiberBeginWork.new:3454)
  xit("warns on forwardRef(memo(...))", function()
    jestExpect(function()
      React.forwardRef(
        React.memo(function(props, ref)
          return nil
        end)
      )
    end).toErrorDev(
      {
        "Warning: forwardRef requires a render function but received a `memo` " ..
          "component. Instead of forwardRef(memo(...)), use " ..
          "memo(forwardRef(...)).",
      },
      {withoutStack = true}
    )
  end)
end
