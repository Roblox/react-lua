-- Upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-test-renderer/src/__tests__/ReactTestRendererTraversal-test.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

-- !strict

local Workspace = script.Parent.Parent.Parent
local RobloxJest = require(Workspace.RobloxJest)
local Packages = Workspace.Parent

local React = require(Workspace.React)
local ReactTestRenderer
local Context
local RCTView = 'RCTView'
local View = function(props)
    return React.createElement(RCTView, props)
end

return function()
    local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
    describe('ReactTestRendererTraversal', function()
        beforeEach(function()
            RobloxJest.resetModules()
            -- deviation: In react, jest _always_ mocks Scheduler -> unstable_mock;
            -- in our case, we need to do it anywhere we want to use the scheduler,
            -- directly or indirectly, until we have some form of bundling logic
            RobloxJest.mock(Workspace.Scheduler, function()
            return require(Workspace.Scheduler.unstable_mock)
            end)
            -- deviation: upstream has jest.mock return a function via
            -- scripts/setupHostConfigs.js, but it's easier for us to do it here
            RobloxJest.mock(Workspace.ReactReconciler.ReactFiberHostConfig, function()
                return require(Workspace.ReactTestRenderer.ReactTestHostConfig)
            end)

            React = require(Workspace.React)
            ReactTestRenderer = require(Workspace.ReactTestRenderer)
            Context = React.createContext(nil)
        end)

        -- ROBLOX deviation: predeclare to avoid changing upstream declaration order
        local ExampleFn
        local ExampleNull
        local ExampleSpread
        local ExampleForwardRef

        local Example = React.Component:extend("Example")
        function Example:render()
            return React.createElement(View, nil, React.createElement(View, {
                foo = 'foo',
            }, React.createElement(View, {
                bar = 'bar',
            }), React.createElement(View, {
                bar = 'bar',
                baz = 'baz',
                itself = 'itself',
            }), React.createElement(View, nil), React.createElement(ExampleSpread, {
                bar = 'bar',
            }), React.createElement(ExampleFn, {
                bar = 'bar',
                bing = 'bing',
            }), React.createElement(ExampleNull, {
                bar = 'bar',
            }), React.createElement(ExampleNull, {
                null = 'null',
            }, React.createElement(View, {
                void = 'void',
            }), React.createElement(View, {
                void = 'void',
            })),
            -- ROBLOX FIXME: React.Profiler unimplemented
            --  React.createElement(React.Profiler, {
            --     id = 'test',
            --     onRender = function()
            --         return
            --     end,
            -- },
            -- React.createElement(ExampleForwardRef, {
            --     qux = 'qux',
            -- })),
                React.createElement(React.Fragment, nil,
                    React.createElement(React.Fragment, nil,
                        React.createElement(Context.Provider, {value = nil},
                            React.createElement(Context.Consumer, nil,
                                function()
                                    return React.createElement(View, {nested = true})
                                end)
                        )
                    ),
                    React.createElement(View, {nested = true}), React.createElement(View, {nested = true})
                ))
            )
        end

        ExampleSpread = React.Component:extend("ExampleSpread")

        function ExampleSpread:render()
            return React.createElement(View, self.props)
        end

        ExampleFn = function(props)
            return React.createElement(View, {
                baz = 'baz',
            })
        end
        ExampleNull = function(props)
            return nil
        end
        ExampleForwardRef = React.forwardRef(function(props, ref)
            return React.createElement(View, {unpack(props), ref = ref})
        end)

        it('initializes', function()
            local render = ReactTestRenderer.create(React.createElement(Example, nil))
            local hasFooProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'foo') ~= nil
            end

            -- assert .props, .type and .parent attributes
            local foo = render.root:find(hasFooProp)

            -- ROBLOX FIXME: once Profiler implemented and above fixme is resolved, this should become 9
            jestExpect(#foo.props.children).toEqual(8)
            jestExpect(foo.type).toEqual(View)
            jestExpect(render.root.parent).toEqual(nil)

            -- ROBLOX FIXME: prevents infinite recursion with current toEqual, once we adopt Jest remove ._fiber._debugID.
            jestExpect(foo.children[1].parent._fiber._debugID).toEqual(foo._fiber._debugID)
        end)
        it('searches via .find() / .findAll()', function()
            local render = ReactTestRenderer.create(React.createElement(Example, nil))
            local hasFooProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'foo') ~= nil
            end
            local hasBarProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'bar') ~= nil
            end
            local hasBazProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'baz') ~= nil
            end
            local hasBingProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'bing') ~= nil
            end
            local hasNullProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'null') ~= nil
            end
            local hasVoidProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'void') ~= nil
            end
            local hasItselfProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'itself') ~= nil
            end
            local hasNestedProp = function(node)
                -- ROBLOX deviation: workaround for hasOwnProperty
                return rawget(node.props, 'nested') ~= nil
            end

            jestExpect(function()
                return render.root:find(hasFooProp)
            end).never.toThrow() -- 1 match
            jestExpect(function()
                return render.root:find(hasBarProp)
            end).toThrow() -- >1 matches
            jestExpect(function()
                return render.root:find(hasBazProp)
            end).toThrow() -- >1 matches
            jestExpect(function()
                return render.root:find(hasBingProp)
            end).never.toThrow() -- 1 match
            jestExpect(function()
                return render.root:find(hasNullProp)
            end).never.toThrow() -- 1 match
            jestExpect(function()
                return render.root:find(hasVoidProp)
            end).toThrow() -- 0 matches
            jestExpect(function()
                return render.root:find(hasNestedProp)
            end).toThrow() -- >1 matches

            -- same assertion as :find(), but confirm length
            jestExpect(#render.root:findAll(hasFooProp, {deep = false})).toEqual(1)
            jestExpect(#render.root:findAll(hasBarProp, {deep = false})).toEqual(5)
            jestExpect(#render.root:findAll(hasBazProp, {deep = false})).toEqual(2)
            jestExpect(#render.root:findAll(hasBingProp, {deep = false})).toEqual(1)
            jestExpect(#render.root:findAll(hasNullProp, {deep = false})).toEqual(1)
            jestExpect(#render.root:findAll(hasVoidProp, {deep = false})).toEqual(0)
            jestExpect(#render.root:findAll(hasNestedProp, {deep = false})).toEqual(3)

            -- note: with {deep: true}, :findAll() will continue to
            --       search children, even after finding a match
            jestExpect(#render.root:findAll(hasFooProp)).toEqual(2)
            jestExpect(#render.root:findAll(hasBarProp)).toEqual(9)
            jestExpect(#render.root:findAll(hasBazProp)).toEqual(4)
            jestExpect(#render.root:findAll(hasBingProp)).toEqual(1) -- no spread
            jestExpect(#render.root:findAll(hasNullProp)).toEqual(1) -- no spread
            jestExpect(#render.root:findAll(hasVoidProp)).toEqual(0)
            jestExpect(#render.root:findAll(hasNestedProp, {deep = false})).toEqual(3)

            local bing = render.root:find(hasBingProp)

            -- ROBLOX FIXME: prevents infinite recursion with current toEqual, once we adopt Jest remove ._fiber._debugID.
            jestExpect(bing:find(hasBarProp)._fiber._debugID).toEqual(bing._fiber._debugID)
            jestExpect(bing:find(hasBingProp)._fiber._debugID).toEqual(bing._fiber._debugID)
            jestExpect(#bing:findAll(hasBazProp, {deep = false})).toEqual(1)
            jestExpect(#bing:findAll(hasBazProp)).toEqual(2)

            local foo = render.root:find(hasFooProp)

            jestExpect(#foo:findAll(hasFooProp, {deep = false})).toEqual(1)
            jestExpect(#foo:findAll(hasFooProp)).toEqual(2)

            local itself = foo:find(hasItselfProp)

            -- ROBLOX FIXME: prevents infinite recursion with current toEqual, once we adopt Jest remove ._fiber._debugID.
            jestExpect(itself:find(hasBarProp)._fiber._debugID).toEqual(itself._fiber._debugID)
            jestExpect(itself:find(hasBazProp)._fiber._debugID).toEqual(itself._fiber._debugID)
            jestExpect(#itself:findAll(hasBazProp, {deep = false})).toEqual(1)
            jestExpect(#itself:findAll(hasBazProp)).toEqual(2)
        end)
        it('searches via .findByType() / .findAllByType()', function()
            local render = ReactTestRenderer.create(React.createElement(Example, nil))
            jestExpect(function()
                return render.root:findByType(ExampleFn)
            end).never.toThrow() -- 1 match
            jestExpect(function()
                return render.root:findByType(View)
            end).never.toThrow() -- 1 match

            -- ROBLOX FIXME: once React.Profiler is implemented and above FIXMEs are resolved, uncomment the following expect
            -- jestExpect(function()
            --     return render.root:findByType(ExampleForwardRef)
            -- end).never.toThrow() -- 1 match

            -- note: there are clearly multiple <View /> in general, but there
            --       is only one being rendered at root node level
            jestExpect(function()
                return render.root:findByType(ExampleNull)
            end).toThrow() -- 2 matches
            jestExpect(#render.root:findAllByType(ExampleFn)).toEqual(1)
            jestExpect(#render.root:findAllByType(View, {deep = false})).toEqual(1)

            -- ROBLOX FIXME: once React.Profiler is implemented and above FIXMEs are resolved set below toEqual(11)
            jestExpect(#render.root:findAllByType(View)).toEqual(10)

            jestExpect(#render.root:findAllByType(ExampleNull)).toEqual(2)

            -- ROBLOX FIXME: once React.Profiler is implemented and above FIXMEs are resolved set below toEqual(1)
            jestExpect(#render.root:findAllByType(ExampleForwardRef)).toEqual(0)

            local nulls = render.root:findAllByType(ExampleNull)

            jestExpect(#nulls[1]:findAllByType(View)).toEqual(0)
            jestExpect(#nulls[2]:findAllByType(View)).toEqual(0)

            local fn = render.root:findAllByType(ExampleFn)

            jestExpect(#fn[1]:findAllByType(View)).toEqual(1)
        end)
        it('searches via .findByProps() / .findAllByProps()', function()
            local render = ReactTestRenderer.create(React.createElement(Example, nil))
            local foo = 'foo'
            local bar = 'bar'
            local baz = 'baz'
            local qux = 'qux'

            render.root:findByProps({foo = foo})
            jestExpect(function()
                return render.root:findByProps({foo = foo})
            end).never.toThrow() -- 1 match
            jestExpect(function()
                return render.root:findByProps({bar = bar})
            end).toThrow() -- >1 matches
            jestExpect(function()
                return render.root:findByProps({baz = baz})
            end).toThrow() -- >1 matches

            -- ROBLOX FIXME: once React.Profiler is implemented and above FIXMEs are resolved, uncomment the following expect
            -- jestExpect(function()
            --     return render.root:findByProps({qux = qux})
            -- end).never.toThrow() -- 1 match

            jestExpect(#render.root:findAllByProps({foo = foo}, {deep = false})).toEqual(1)
            jestExpect(#render.root:findAllByProps({bar = bar}, {deep = false})).toEqual(5)
            jestExpect(#render.root:findAllByProps({baz = baz}, {deep = false})).toEqual(2)

            -- ROBLOX FIXME: once React.Profiler is implemented and above FIXMEs are resolved set below toEqual(1)
            jestExpect(#render.root:findAllByProps({qux = qux}, {deep = false})).toEqual(0)

            jestExpect(#render.root:findAllByProps({foo = foo})).toEqual(2)
            jestExpect(#render.root:findAllByProps({bar = bar})).toEqual(9)
            jestExpect(#render.root:findAllByProps({baz = baz})).toEqual(4)

            -- ROBLOX FIXME: once React.Profiler is implemented and above FIXMEs are resolved set below toEqual(3)
            jestExpect(#render.root:findAllByProps({qux = qux})).toEqual(0)
        end)
        it('skips special nodes', function()
            local render = ReactTestRenderer.create(React.createElement(Example, nil))

            jestExpect(#render.root:findAllByType(React.Fragment)).toEqual(0)
            jestExpect(#render.root:findAllByType(Context.Consumer)).toEqual(0)
            jestExpect(#render.root:findAllByType(Context.Provider)).toEqual(0)

            local expectedParent = render.root:findByProps({
                foo = 'foo',
            }, {deep = false}).children[1]
            local nestedViews = render.root:findAllByProps({nested = true}, {deep = false})

            jestExpect(#nestedViews).toEqual(3)

            -- ROBLOX FIXME: prevents infinite recursion with current toEqual, once we adopt Jest remove ._fiber._debugID
            jestExpect(nestedViews[1].parent._fiber._debugID).toEqual(expectedParent._fiber._debugID)
            jestExpect(nestedViews[2].parent._fiber._debugID).toEqual(expectedParent._fiber._debugID)
            jestExpect(nestedViews[3].parent._fiber._debugID).toEqual(expectedParent._fiber._debugID)
        end)
        it('can have special nodes as roots', function()
            local FR = React.forwardRef(function(props, ref)
                return React.createElement('section', props)
            end)

            jestExpect(#ReactTestRenderer.create(React.createElement(FR, nil, React.createElement('div', nil), React.createElement('div', nil))).root:findAllByType('div')).toEqual(2)
            jestExpect(#ReactTestRenderer.create(React.createElement(React.Fragment, nil, React.createElement('div', nil), React.createElement('div', nil))).root:findAllByType('div')).toEqual(2)
            jestExpect(#ReactTestRenderer.create(React.createElement(React.Fragment, {
                key = 'foo',
            }, React.createElement('div', nil), React.createElement('div', nil))).root:findAllByType('div')).toEqual(2)
            jestExpect(#ReactTestRenderer.create(React.createElement(React.StrictMode, nil, React.createElement('div', nil), React.createElement('div', nil))).root:findAllByType('div')).toEqual(2)
            jestExpect(#ReactTestRenderer.create(React.createElement(Context.Provider, {value = nil}, React.createElement('div', nil), React.createElement('div', nil))).root:findAllByType('div')).toEqual(2)
        end)
    end)
end