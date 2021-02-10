--[[*
 * Upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/ReactIncrementalScheduling-test.js
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
 --]]
 --!strict
local Workspace = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler
return function()
    describe('ReactIncrementalScheduling', function()
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

        local function span(prop)
            return{
                type = 'span',
                children = {},
                prop = prop,
                hidden = false,
            }
        end

        it('schedules and flushes deferred work', function()
            local expect: any = expect
            ReactNoop.render(React.createElement('span', {
                prop = "1"
            }))
            expect(ReactNoop.getChildren()).toEqual({})
            expect(Scheduler).toFlushWithoutYielding()

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(<span prop="1" />)
            local renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal('1')
        end)
        it('searches for work on other roots once the current root completes', function()
            local expect: any = expect
            ReactNoop.renderToRootWithID(React.createElement('span', {
                prop = 'a:1',
            }), 'a')
            ReactNoop.renderToRootWithID(React.createElement('span', {
                prop = 'b:1',
            }), 'b')
            ReactNoop.renderToRootWithID(React.createElement('span', {
                prop = 'c:1',
            }), 'c')
            expect(Scheduler).toFlushWithoutYielding()
            expect(ReactNoop.getChildren('a')).toEqual({
                span('a:1'),
            })
            expect(ReactNoop.getChildren('b')).toEqual({
                span('b:1'),
            })
            expect(ReactNoop.getChildren('c')).toEqual({
                span('c:1'),
            })
        end)
        -- Test fails due to flushSync/update priority bug
        xit('schedules top-level updates in order of priority', function()
            local expect: any = expect
            ReactNoop.render(React.createElement('span', {prop = 1}))
            expect(Scheduler).toFlushWithoutYielding()

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 1}))
            local renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(1)
            
            ReactNoop.batchedUpdates(function()
                ReactNoop.render(React.createElement('span', {prop = 5}))
                ReactNoop.flushSync(function()
                    ReactNoop.render(React.createElement('span', {prop = 2}))
                    ReactNoop.render(React.createElement('span', {prop = 3}))
                    ReactNoop.render(React.createElement('span', {prop = 4}))
                    end)
            end)

            -- The sync updates flush first.
            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toEqual(React.createElement('span', {prop = 4}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(4)

            -- The terminal value should be the last update that was scheduled,
            -- regardless of priority. In this case, that's the last sync update.
            expect(Scheduler).toFlushWithoutYielding()

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 4}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(4)
        end)
        it('schedules top-level updates with same priority in order of insertion', function()
            local expect: any = expect
            -- Initial render.
            ReactNoop.render(React.createElement('span', {prop = 1}))
            expect(Scheduler).toFlushWithoutYielding()

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 1}))
            local renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(1)

            ReactNoop.render(React.createElement('span', {prop = 2}))
            ReactNoop.render(React.createElement('span', {prop = 3}))
            ReactNoop.render(React.createElement('span', {prop = 4}))
            ReactNoop.render(React.createElement('span', {prop = 5}))
            expect(Scheduler).toFlushWithoutYielding()

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 5}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(5)
        end)
        it('works on deferred roots in the order they were scheduled', function()
            local expect: any = expect
            local useEffect = React.useEffect

            local function Text(props)
                local text = props.text

                useEffect(function()
                    Scheduler.unstable_yieldValue(text)
                end, {text})

                return text
            end

            ReactNoop.act(function()
                ReactNoop.renderToRootWithID(React.createElement(Text, {
                    text = 'a:1',
                }), 'a')
                ReactNoop.renderToRootWithID(React.createElement(Text, {
                    text = 'b:1',
                }), 'b')
                ReactNoop.renderToRootWithID(React.createElement(Text, {
                    text = 'c:1',
                }), 'c')
            end)
            expect(Scheduler).toHaveYielded({
                'a:1',
                'b:1',
                'c:1',
            })

            -- deviation: getChildrenAsJSX() method which is used in upstream replaced with
            -- equivalent getChildren() evaluations because Roact doesn't support JSX.

            expect(ReactNoop.getChildren('a')[1].text).toEqual('a:1')
            expect(ReactNoop.getChildren('b')[1].text).toEqual('b:1')
            expect(ReactNoop.getChildren('c')[1].text).toEqual('c:1')
            expect(#ReactNoop.getChildren('a')).toEqual(1)
            expect(#ReactNoop.getChildren('b')).toEqual(1)
            expect(#ReactNoop.getChildren('c')).toEqual(1)

            -- Schedule deferred work in the reverse order
            ReactNoop.act(function()
                ReactNoop.renderToRootWithID(React.createElement(Text, {
                    text = 'c:2',
                }), 'c')
                ReactNoop.renderToRootWithID(React.createElement(Text, {
                    text = 'b:2',
                }), 'b')
                expect(Scheduler).toFlushAndYieldThrough({
                    'c:2',
                })
                expect(ReactNoop.getChildren('a')[1].text).toEqual('a:1')
                expect(ReactNoop.getChildren('b')[1].text).toEqual('b:1')
                expect(ReactNoop.getChildren('c')[1].text).toEqual('c:2')
                expect(#ReactNoop.getChildren('a')).toEqual(1)
                expect(#ReactNoop.getChildren('b')).toEqual(1)
                expect(#ReactNoop.getChildren('c')).toEqual(1)
                -- Schedule last bit of work, it will get processed the last

                ReactNoop.renderToRootWithID(React.createElement(Text, {
                    text = 'a:2',
                }), 'a')

                -- Keep performing work in the order it was scheduled
                expect(Scheduler).toFlushAndYieldThrough({
                    'b:2',
                })
                expect(ReactNoop.getChildren('a')[1].text).toEqual('a:1')
                expect(ReactNoop.getChildren('b')[1].text).toEqual('b:2')
                expect(ReactNoop.getChildren('c')[1].text).toEqual('c:2')
                expect(#ReactNoop.getChildren('a')).toEqual(1)
                expect(#ReactNoop.getChildren('b')).toEqual(1)
                expect(#ReactNoop.getChildren('c')).toEqual(1)
                expect(Scheduler).toFlushAndYieldThrough({
                    'a:2',
                })
                expect(ReactNoop.getChildren('a')[1].text).toEqual('a:2')
                expect(ReactNoop.getChildren('b')[1].text).toEqual('b:2')
                expect(ReactNoop.getChildren('c')[1].text).toEqual('c:2')
                expect(#ReactNoop.getChildren('a')).toEqual(1)
                expect(#ReactNoop.getChildren('b')).toEqual(1)
                expect(#ReactNoop.getChildren('c')).toEqual(1)
            end)
        end)
        it('schedules sync updates when inside componentDidMount/Update', function()
            local expect: any = expect
            local instance

            local Foo = React.Component:extend("Foo")
            function Foo:init()
                self.state = {tick = 0}
            end

            function Foo:componentDidMount()
                Scheduler.unstable_yieldValue('componentDidMount (before setState): ' .. self.state.tick)
                self:setState({
                    tick = 1
                }) 
                -- We're in a batch. Update hasn't flushed yet.

                Scheduler.unstable_yieldValue('componentDidMount (after setState): ' .. self.state.tick)
            end

            function Foo:componentDidUpdate()
                Scheduler.unstable_yieldValue('componentDidUpdate: ' .. self.state.tick);

                if self.state.tick == 2 then
                    Scheduler.unstable_yieldValue('componentDidUpdate (before setState): ' .. self.state.tick);
                    self:setState({
                        tick= 3
                    });
                    Scheduler.unstable_yieldValue('componentDidUpdate (after setState): ' .. self.state.tick); -- We're in a batch. Update hasn't flushed yet.
                    -- We're in a batch. Update hasn't flushed yet.
                end
            end

            function Foo:render()
                Scheduler.unstable_yieldValue('render: ' .. self.state.tick);
                instance = self;
                return React.createElement("span", {
                    prop= self.state.tick
                })
            end


            ReactNoop.render(React.createElement(Foo))
            -- Render without committing
            expect(Scheduler).toFlushAndYieldThrough({
                'render: 0',
            })

            -- Do one more unit of work to commit
            expect(ReactNoop.flushNextYield()).toEqual({
                'componentDidMount (before setState): 0',
                'componentDidMount (after setState): 0',
                -- If the setState inside componentDidMount were deferred, there would be
                -- no more ops. Because it has Task priority, we get these ops, too:
                'render: 1',
                'componentDidUpdate: 1',
            })
            instance:setState({tick = 2})
            expect(Scheduler).toFlushAndYieldThrough({
                'render: 2',
            })
            expect(ReactNoop.flushNextYield()).toEqual({
                'componentDidUpdate: 2',
                'componentDidUpdate (before setState): 2',
                'componentDidUpdate (after setState): 2',
                -- If the setState inside componentDidUpdate were deferred, there would be
                -- no more ops. Because it has Task priority, we get these ops, too:
                'render: 3',
                'componentDidUpdate: 3',
            })
        end)
        it('can opt-in to async scheduling inside componentDidMount/Update', function()
            local expect: any = expect
            local instance

            local Foo = React.Component:extend("Foo")
            function Foo:init()
                self.state = {tick=0}
            end
            function Foo:componentDidMount()
                local _this = self
                ReactNoop.deferredUpdates(function()
                    Scheduler.unstable_yieldValue('componentDidMount (before setState): ' .. _this.state.tick)
                    
                    _this:setState({
                        tick = 1
                    })

                    Scheduler.unstable_yieldValue('componentDidMount (after setState): ' .. _this.state.tick)
                end
                )
            end

            function Foo:componentDidUpdate()
                local _this2 = self

                ReactNoop.deferredUpdates(function()
                    Scheduler.unstable_yieldValue('componentDidUpdate: ' .. _this2.state.tick)

                    if _this2.state.tick == 2 then
                      Scheduler.unstable_yieldValue('componentDidUpdate (before setState): ' .. _this2.state.tick)

                      _this2:setState({
                        tick = 3
                      })

                      Scheduler.unstable_yieldValue('componentDidUpdate (after setState): ' .. _this2.state.tick)
                    end
                end);
            end

            function Foo:render()
                Scheduler.unstable_yieldValue('render: ' .. self.state.tick)
                instance = self
                return React.createElement("span", {
                  prop = self.state.tick
                });
            end
            ReactNoop.flushSync(function()
                ReactNoop.render(React.createElement(Foo, nil))
            end)
            -- The cDM update should not have flushed yet because it has async priority.
            expect(Scheduler).toHaveYielded({
                'render: 0',
                'componentDidMount (before setState): 0',
                'componentDidMount (after setState): 0',
            })

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 0}))
            local renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(0)

            -- Now flush the cDM update.
            expect(Scheduler).toFlushAndYield({
                'render: 1',
                'componentDidUpdate: 1',
            })

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 1}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(1)

            -- Increment the tick to 2. This will trigger an update inside cDU. Flush
            -- the first update without flushing the second one.
            instance:setState({tick = 2})
            expect(Scheduler).toFlushAndYieldThrough({
                'render: 2',
                'componentDidUpdate: 2',
                'componentDidUpdate (before setState): 2',
                'componentDidUpdate (after setState): 2',
            })

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 2}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(2)

            -- Now flush the cDU update.
            expect(Scheduler).toFlushAndYield({
                'render: 3',
                'componentDidUpdate: 3',
            })
            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 3}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(3)
        end)
        it('performs Task work even after time runs out', function()
            local expect: any = expect
            local Foo = React.Component:extend("Foo")
            function Foo:init()
                self.state = {step = 1}
            end

            function Foo:componentDidMount()
                local _this3 = self
                self:setState({
                    step = 2
                    }, function() 
                        _this3:setState({
                        step = 3
                        }, function() 
                            _this3:setState({
                            step = 4
                            }, function() 
                                _this3:setState({
                                step = 5
                                })
                                end)
                            end)
                        end)
            end

            function Foo:render()
                Scheduler.unstable_yieldValue('Foo')
                return React.createElement("span", {
                    prop = self.state.step
                  })
            end
            ReactNoop.render(React.createElement(Foo, nil))
            -- This should be just enough to complete all the work, but not enough to
            -- commit it.
            expect(Scheduler).toFlushAndYieldThrough({
                'Foo',
            })
            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(nil)
            local renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).toEqual(0)

            -- Do one more unit of work.
            ReactNoop.flushNextYield()

            -- The updates should all be flushed with Task priority
            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 5}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(5)
        end)
        it('can opt-out of batching using unbatchedUpdates', function()
            local expect: any = expect
            local renderedOutput
            ReactNoop.flushSync(function()
                ReactNoop.render(React.createElement('span', {prop = 0}))
                expect(ReactNoop.getChildren()).toEqual({})
                -- Should not have flushed yet because we're still batching

                -- unbatchedUpdates reverses the effect of batchedUpdates, so sync
                -- updates are not batched
                ReactNoop.unbatchedUpdates(function()
                    ReactNoop.render(React.createElement('span', {prop = 1}))
                    -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
                    -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 1}))
                    renderedOutput = ReactNoop.getChildren()
                    expect(#renderedOutput).to.equal(1)
                    expect(renderedOutput[1].prop).to.equal(1)

                    ReactNoop.render(React.createElement('span', {prop = 2}))
                    -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
                    -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 2}))
                    renderedOutput = ReactNoop.getChildren()
                    expect(#renderedOutput).to.equal(1)
                    expect(renderedOutput[1].prop).to.equal(2)
                end)
                ReactNoop.render(React.createElement('span', {prop = 3}))
                -- Remaining update is now flushed
                -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
                -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 2}))
                renderedOutput = ReactNoop.getChildren()
                expect(#renderedOutput).to.equal(1)
                expect(renderedOutput[1].prop).to.equal(2)
            end)
            -- Remaining update is now flushed
            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 3}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(3)
        end)
        it('nested updates are always deferred, even inside unbatchedUpdates', function()
            local expect: any = expect
            local instance
            local Foo = React.Component:extend("Foo")
            function Foo:init()
                self.state = {
                    step=0
                }
            end
            function Foo:componentDidUpdate()
                local _this4 = self
                    Scheduler.unstable_yieldValue('componentDidUpdate: ' .. self.state.step)
                    
                    if self.state.step == 1 then
                        ReactNoop.unbatchedUpdates(function()
                            -- This is a nested state update, so it should not be
                            -- flushed synchronously, even though we wrapped it
                            -- in unbatchedUpdates.
                            _this4:setState({
                                step = 2
                            })
                        end)
                        expect(Scheduler).toHaveYielded({'render: 1', 'componentDidUpdate: 1'})
                        -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
                        -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 1}))
                        local renderedOutput = ReactNoop.getChildren()
                        expect(#renderedOutput).to.equal(1)
                        expect(renderedOutput[1].prop).to.equal(1)
                    end
            end

            function Foo:render()
                Scheduler.unstable_yieldValue('render: ' .. self.state.step)
                instance = self
                return React.createElement("span", {
                    prop = self.state.step
                })
            end

            ReactNoop.render(React.createElement(Foo, nil))
            expect(Scheduler).toFlushAndYield({
                'render: 0',
            })
            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 0}))
            local renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(0)
            ReactNoop.flushSync(function()
                instance:setState({step = 1})
            end)
            expect(Scheduler).toHaveYielded({
                'render: 2',
                'componentDidUpdate: 2',
            })

            -- ROBLOX TODO: replace the below expects with toMatchRenderedOutput
            -- expect(ReactNoop).toMatchRenderedOutput(React.createElement('span', {prop = 2}))
            renderedOutput = ReactNoop.getChildren()
            expect(#renderedOutput).to.equal(1)
            expect(renderedOutput[1].prop).to.equal(2)
        end)
    end)
end