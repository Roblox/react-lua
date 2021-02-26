-- * Upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/ReactIncrementalReflection-test.js
-- * Copyright (c) Facebook, Inc. and its affiliates.
-- *
-- * This source code is licensed under the MIT license found in the
-- * LICENSE file in the root directory of this source tree.
-- *
-- * @emails react-core
-- * @jest-environment node
--

local Workspace = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler
local console = require(Workspace.Shared.console)

return function()
    describe('ReactIncrementalReflection', function()
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

        local function div(...)
            local _, _, children = ...
            -- deviation: commented out unused children processing logic
            -- children = children.map(function(c)
            --     return(function()
            --         if typeof(c) == 'string' then
            --             return{
            --                 text = c,
            --                 hidden = false,
            --             }
            --         end

            --         return c
            --     end)()
            -- end)

            return{
                type = 'div',
                children = children,
                prop = nil,
                hidden = false,
            }
        end
        local function span(prop)
            return{
                type = 'span',
                children = {},
                prop = prop,
                hidden = false,
            }
        end

        it('handles isMounted even when the initial render is deferred', function()
            local expect: any = expect
            local instances = {}
            local Component = React.Component:extend("Component")

            function Component:_isMounted()
                -- No longer a public API, but we can test that it works internally by
                -- reaching into the updater.
                return self.updater.isMounted(self)
            end
            function Component:UNSAFE_componentWillMount()
                table.insert(instances, self)
                Scheduler.unstable_yieldValue('componentWillMount: ' .. tostring(self:_isMounted()))
            end
            function Component:componentDidMount()
                Scheduler.unstable_yieldValue('componentDidMount: ' .. tostring(self:_isMounted()))
            end
            function Component:render()
                return React.createElement("span")
            end

            local function Foo()
                return React.createElement(Component, nil)
            end

            ReactNoop.render(React.createElement(Foo)) 
            
            -- Render part way through but don't yet commit the updates.
            expect(Scheduler).toFlushAndYieldThrough({
                'componentWillMount: false',
            })
            expect(instances[1]:_isMounted()).toEqual(false) 
            
            -- Render the rest and commit the updates.
            expect(function()
                return expect(Scheduler).toFlushAndYield({
                    'componentDidMount: true',
                })
            end).toErrorDev('Using UNSAFE_componentWillMount in strict mode is not recommended', {withoutStack = true})
            expect(instances[1]:_isMounted()).toEqual(true)
        end)
        -- ROBLOX TODO: componentWillUnmount not getting called
        xit('handles isMounted when an unmount is deferred', function()
            local expect: any = expect
            local instances = {}
            local Component = React.Component:extend('Component')

            function Component:init()
                self.state = {}
            end

            function Component:_isMounted()
                return self.updater.isMounted(self)
            end
            function Component:UNSAFE_componentWillMount()
                table.insert(instances, self)
            end
            function Component:componentWillUnmount()
                Scheduler.unstable_yieldValue('componentWillUnmount: ' .. tostring(self:_isMounted()))
            end
            function Component:render()
                Scheduler.unstable_yieldValue('Component')
                return React.createElement("span", nil)
            end

            local function Other()
                Scheduler.unstable_yieldValue('Other')
                return React.createElement("span", nil)
            end

            local function Foo(props)
                if props.mount then
                    return React.createElement(Component)
                end
                return React.createElement(Other)
            end

            ReactNoop.render(React.createElement(Foo, {mount = true}))
            expect(function()
                return expect(Scheduler).toFlushAndYield({
                    'Component',
                })
            end).toErrorDev('Using UNSAFE_componentWillMount in strict mode is not recommended', {withoutStack = true})

            expect(instances[1]:_isMounted()).toEqual(true)

            ReactNoop.render(React.createElement(Foo, {mount = false}))
            -- Render part way through but don't yet commit the updates so it is not
            -- fully unmounted yet.
            expect(Scheduler).toFlushAndYieldThrough({
                'Other',
            })

            expect(instances[1]:_isMounted()).toEqual(true)

            -- Finish flushing the unmount.
            expect(Scheduler).toFlushAndYield({
                'componentWillUnmount: true',
            })
            expect(instances[1]:_isMounted()).toEqual(false)
        end)
        -- ROBLOX TODO: 292: received[1][2]: value of type 'nil' expected[1][2]: value of type 'table'
        xit('finds no node before insertion and correct node before deletion', function()
            local expect: any = expect
            local classInstance = nil
            local function findInstance(inst)
                -- We ignore warnings fired by findInstance because we are testing
                -- that the actual behavior still works as expected even though it
                -- is deprecated.
                local oldConsoleError = console.error
                console.error = nil
                local ok, result = pcall(function()
                    return ReactNoop.findInstance(inst)
                end)
                console.error = oldConsoleError
                if ok then
                    return result
                else
                    error(result)
                end
            end

            local Component = React.Component:extend("Component")

            function Component:UNSAFE_componentWillMount()
                classInstance = self
                Scheduler.unstable_yieldValue({
                    'componentWillMount',
                    findInstance(self),
                })
            end
            function Component:componentDidMount()
                Scheduler.unstable_yieldValue({
                    'componentDidMount',
                    findInstance(self),
                })
            end
            function Component:UNSAFE_componentWillUpdate()
                Scheduler.unstable_yieldValue({
                    'componentWillUpdate',
                    findInstance(self),
                })
            end
            function Component:componentDidUpdate()
                Scheduler.unstable_yieldValue({
                    'componentDidUpdate',
                    findInstance(self),
                })
            end
            function Component:componentWillUnmount()
                Scheduler.unstable_yieldValue({
                    'componentWillUnmount',
                    findInstance(self),
                })
            end
            function Component:render()
                Scheduler.unstable_yieldValue('render')
                return (
                    function ()
                        if self.props.step < 2 then
                            return React.createElement(span, {
                                ref = function(ref)
                                    self.span = ref
                                    return ref
                                end,
                            })
                        elseif self.props.step == 2 then
                            return React.createElement(div, {
                                ref = function(ref)
                                    self.div = ref
                                    return ref
                                end
                            })
                        elseif self.props.step == 3 then
                            return nil
                        elseif self.props.step == 4 then
                            return React.createElement(div, {
                                ref = function(ref)
                                    self.span = ref
                                    return ref
                                end,
                            })
                        else
                            return nil
                        end
                    end)
            end

            local function Sibling()
                -- Sibling is used to assert that we've rendered past the first component.
                Scheduler.unstable_yieldValue('render sibling')
                return React.createElement(span)
            end

            local function Foo(props)
                return{
                    React.createElement(Component, {
                        key = 'a',
                        step = props.step,
                    }),
                    React.createElement(Sibling, {
                        key = 'b',
                    }),
                }
            end

            ReactNoop.render(React.createElement(Foo, {step = 0}))
             -- Flush past Component but don't complete rendering everything yet.
            expect(Scheduler).toFlushAndYieldThrough({
                {
                    'componentWillMount',
                    nil,
                },
                'render',
                'render sibling',
            })

            -- ROBLOX TODO: toBeDefined not implmented
            --expect(classInstance).toBeDefined()

            -- The instance has been complete but is still not committed so it should
            -- not find any host nodes in it.
            expect(findInstance(classInstance)).toEqual(nil)
            expect(function()
                return expect(Scheduler).toFlushAndYield({
                    {
                        'componentDidMount',
                        span(),
                    },
                })
            end).toErrorDev({
                'Using UNSAFE_componentWillMount in strict mode is not recommended',
                'Using UNSAFE_componentWillUpdate in strict mode is not recommended',
            }, {withoutStack = true})

            local hostSpan = classInstance.span
            expect(hostSpan).tobeDefined()

            expect(findInstance(classInstance)).toEqual(hostSpan)

            -- Flush next step which will cause an update but not yet render a new host
            -- node.
            ReactNoop.render(React.createElement(Foo, {step = 1}))
            expect(Scheduler).toFlushAndYield({
                {
                    'componentWillUpdate',
                    hostSpan,
                },
                'render',
                'render sibling',
                {
                    'componentDidUpdate',
                    hostSpan,
                },
            })

            expect(ReactNoop.findInstance(classInstance)).toEqual(hostSpan)

            -- The next step will render a new host node but won't get committed yet.
            -- We expect this to mutate the original Fiber.
            ReactNoop.render(React.createElement(Foo, {step = 2}))
            expect(Scheduler).toFlushAndYieldThrough({
                {
                    'componentWillUpdate',
                    hostSpan,
                },
                'render',
                'render sibling',
            })

            -- This should still be the host span.
            expect(ReactNoop.findInstance(classInstance)).toEqual(hostSpan)

            -- When we finally flush the tree it will get committed.
            expect(Scheduler).toFlushAndYield({
                {
                    'componentDidUpdate',
                    div(),
                },
            })

            local hostDiv = classInstance.div
            expect(hostDiv).toBeDefined()

            -- ROBLOX TODO: to not equal
            expect(hostSpan).toEqual(hostDiv)

            -- We should now find the new host node.
            expect(ReactNoop.findInstance(classInstance)).toEqual(hostDiv)

            -- Render to null but don't commit it yet.
            ReactNoop.render(React.createElement(Foo, {step = 3}))
            expect(Scheduler).toFlushAndYieldThrough({
                {
                    'componentWillUpdate',
                    hostDiv,
                },
                'render',
                'render sibling',
            })

            -- This should still be the host div since the deletion is not committed.
            expect(ReactNoop.findInstance(classInstance)).toEqual(hostDiv)

            expect(Scheduler).toFlushAndYield({
                {
                    'componentDidUpdate',
                    nil,
                },
            })

            -- This should still be the host div since the deletion is not committed.
            expect(ReactNoop.findInstance(classInstance)).toEqual(nil)

            -- Render a div again
            ReactNoop.render(React.createElement(Foo, {step = 4}))
            expect(Scheduler).toFlushAndYield({
                {
                    'componentWillUpdate',
                    nil,
                },
                'render',
                'render sibling',
                {
                    'componentDidUpdate',
                    div(),
                },
            })

            -- Unmount the component.
            ReactNoop.render({})
            expect(Scheduler).toFlushAndYield({
                {
                    'componentWillUnmount',
                    hostDiv,
                },
            })
        end)
    end)
end