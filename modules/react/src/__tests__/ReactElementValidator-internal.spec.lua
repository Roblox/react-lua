--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]
return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)

	local React
	local ReactFeatureFlags
	-- ROBLOX deviation: the tests using these are currently SKIPped
	local PropTypes = nil
	local ReactTestUtils = nil

	describe("ReactElementValidator", function()
		local ComponentClass

		beforeEach(function()
			RobloxJest.resetModules()

			-- PropTypes = require("prop-types")
			ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
			ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
			React = require(Workspace.React)
			-- ReactDOM = require("react-dom")
			-- ReactTestUtils = require("react-dom/test-utils")
			ComponentClass = React.Component:extend("ComponentClass")
			function ComponentClass:render()
				return React.createElement("Frame")
			end
		end)

		it("warns for keys for arrays of elements in rest args", function()
			local expect: any = expect
			expect(function()
				React.createElement(ComponentClass, nil, {
					React.createElement(ComponentClass),
					React.createElement(ComponentClass),
				})
			end).toErrorDev('Each child in a list should have a unique "key" prop.')
		end)

		itSKIP("warns for keys for arrays of elements with owner info", function()
			local expect: any = expect
			local InnerClass = React.Component:extend("InnerClass")
			function InnerClass:render()
				return React.createElement(ComponentClass, nil, self.props.childSet)
			end

			local ComponentWrapper = React.Component:extend("ComponentWrapper")
			function ComponentWrapper:render()
				return React.createElement(InnerClass, {
					childSet = {
						React.createElement(ComponentClass),
						React.createElement(ComponentClass),
					},
				})
			end

			expect(function()
				ReactTestUtils.renderIntoDocument(React.createElement(ComponentWrapper))
			end).toErrorDev(
				'Each child in a list should have a unique "key" prop.' ..
					"\n\nCheck the render method of `InnerClass`. " ..
					"It was passed a child from ComponentWrapper. "
			)
		end)

		itSKIP("warns for keys for arrays with no owner or parent info", function()
			local expect: any = expect
			local function Anonymous()
				return React.createElement("Frame")
			end
			-- Object.defineProperty(Anonymous, "name", {value = nil})

			local divs = {
				React.createElement("Frame"),
				React.createElement("Frame"),
			}

			expect(function()
				ReactTestUtils.renderIntoDocument(React.createElement(Anonymous, nil, divs))
			end).toErrorDev(
				"Warning: Each child in a list should have a unique " ..
					'"key" prop. See https://reactjs.org/link/warning-keys for more information.\n' ..
					"    in div (at **)"
			)
		end)

		itSKIP("warns for keys for arrays of elements with no owner info", function()
			local expect: any = expect
			local divs = {
				React.createElement("Frame"),
				React.createElement("Frame"),
			}

			expect(function()
				ReactTestUtils.renderIntoDocument(React.createElement("Frame", nil, divs))
			end).toErrorDev(
				"Warning: Each child in a list should have a unique " ..
					'"key" prop.\n\nCheck the top-level render call using <div>. See ' ..
					"https://reactjs.org/link/warning-keys for more information.\n" ..
					"    in div (at **)"
			)
		end)

		itSKIP("warns for keys with component stack info", function()
			local expect: any = expect
			local function Component()
				return React.createElement("Frame", nil, {
					React.createElement("Frame"),
					React.createElement("Frame"),
				})
			end
			local function Parent(props)
				return React.cloneElement(props.child)
			end
			local function GrandParent()
				return React.createElement(Parent, {
					child = React.createElement(Component, nil),
				})
			end

			expect(function()
				return ReactTestUtils.renderIntoDocument(React.createElement(GrandParent, nil))
			end).toErrorDev(
				"Warning: Each child in a list should have a unique " ..
					'"key" prop.\n\nCheck the render method of `Component`. See ' ..
					"https://reactjs.org/link/warning-keys for more information.\n" ..
					"    in div (at **)\n" ..
					"    in Component (at **)\n" ..
					"    in Parent (at **)\n" ..
					"    in GrandParent (at **)"
			)
		end)

		itSKIP("does not warn for keys when passing children down", function()
			local function Wrapper(props)
				return React.createElement(
					"Frame",
					nil,
					props.children,
					React.createElement('footer')
				)
			end

			ReactTestUtils.renderIntoDocument(
				React.createElement(
					Wrapper,
					nil,
					React.createElement('span'),
					React.createElement('span', nil)
				)
			)
		end)

		itSKIP("warns for keys for iterables of elements in rest args", function()
			local expect: any = expect
			local iterable = {
				["@@iterator"] = function()
					local i = 0
					return {
						next = function()
							i = i + 1
							local done = i > 2
							return {
								value = (not done) and React.createElement(ComponentClass) or nil,
								done = done,
							}
						end,
					}
				end,
			}

			expect(function()
				return React.createElement(ComponentClass, nil, iterable)
			end).toErrorDev('Each child in a list should have a unique "key" prop.')
		end)

		it("does not warns for arrays of elements with keys", function()
			React.createElement(ComponentClass, nil, {
				React.createElement(ComponentClass, {key = "#1"}),
				React.createElement(ComponentClass, {key = "#2"}),
			})
		end)

		itSKIP("does not warns for iterable elements with keys", function()
			local iterable = {
				["@@iterator"] = function()
					local i = 0
					return {
						next = function()
							i = i + 1
							local done = i > 2
							return {
								value = (not done) and
									React.createElement(ComponentClass, {key = '#' .. i}) or
									nil,
								done = done,
							}
						end,
					}
				end,
			}

			React.createElement(ComponentClass, nil, iterable)
		end)

		it("does not warn when the element is directly in rest args", function()
			React.createElement(
				ComponentClass,
				nil,
				React.createElement(ComponentClass),
				React.createElement(ComponentClass)
			)
		end)

		it("does not warn when the array contains a non-element", function()
			React.createElement(ComponentClass, nil, {{}, {}})
		end)

		itSKIP("should give context for PropType errors in nested components.", function()
			local expect: any = expect
			-- // In this test, we're making sure that if a proptype error is found in a
			-- // component, we give a small hint as to which parent instantiated that
			-- // component as per warnings about key usage in ReactElementValidator.
			local MyComp = React.Component:extend("MyComp")
			function MyComp:render()
				return React.createElement("Frame", nil, "My color is " .. self.props.color)
			end
			MyComp.propTypes = {
				color = PropTypes.string,
			}
			local function ParentComp()
				return React.createElement(MyComp, {color = 123})
			end

			expect(function()
				ReactTestUtils.renderIntoDocument(React.createElement(ParentComp))
			end).toErrorDev(
				"Warning: Failed prop type: " ..
					"Invalid prop `color` of type `number` supplied to `MyComp`, " ..
					"expected `string`.\n" ..
					"    in MyComp (at **)\n" ..
					"    in ParentComp (at **)"
			)
		end)

		it("gives a helpful error when passing invalid types", function()
			local expect: any = expect
			local function Foo() end

			expect(function()
				React.createElement(nil)
				React.createElement(true)
				React.createElement({x = 17})
				React.createElement({})
				React.createElement(React.createElement("Frame"))
				React.createElement(React.createElement(Foo))
				React.createElement(React.createElement(React.createContext().Consumer))
				React.createElement({["$$typeof"] = "non-react-thing"})
			end).toErrorDev(
				{
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						"components) but got: nil.",
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						"components) but got: boolean.",
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						"components) but got: table.",
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						"components) but got: array. You likely forgot to export your " ..
						"component from the file it's defined in, or you might have mixed up " ..
						"default and named imports.",
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						"components) but got: <Frame />. Did you accidentally export a JSX literal " ..
						"instead of a component?",
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						-- "components) but got: <Foo />. Did you accidentally export a JSX literal " ..
						"components) but got: <Unknown />. Did you accidentally export a JSX literal " ..
						"instead of a component?",
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						"components) but got: <Context.Consumer />. Did you accidentally " ..
						"export a JSX literal instead of a component?",
					"Warning: React.createElement: type is invalid -- expected a string " ..
						"(for built-in components) or a class/function (for composite " ..
						"components) but got: table.",
				},
				{withoutStack = true}
			)

			-- // Should not log any additional warnings
			React.createElement("Frame")
		end)

		itSKIP("includes the owner name when passing null, undefined, boolean, or number", function()
			local expect: any = expect
			local function ParentComp()
				return React.createElement(nil)
			end

			expect(function()
				expect(function()
					ReactTestUtils.renderIntoDocument(React.createElement(ParentComp))
				end).toThrowError(
					"Element type is invalid: expected a string (for built-in components) " ..
						"or a class/function (for composite components) but got: null." ..
						(_G.__DEV__ and "\n\nCheck the render method of `ParentComp`." or "")
				)
			end).toErrorDev(
				"Warning: React.createElement: type is invalid -- expected a string " ..
					"(for built-in components) or a class/function (for composite " ..
					"components) but got: null." ..
					"\n\nCheck the render method of `ParentComp`.\n    in ParentComp"
			)
		end)

		itSKIP("should check default prop values", function()
			local expect: any = expect
			local Component = React.Component:extend("Component")
			function Component:render()
				return React.createElement("Frame", nil, self.props.prop)
			end
			Component.propTypes = {
				prop = PropTypes.string.isRequired,
			}
			Component.defaultProps = {prop = nil}

			expect(function()
				return ReactTestUtils.renderIntoDocument(React.createElement(Component))
			end).toErrorDev(
				"Warning: Failed prop type: The prop `prop` is marked as required in " ..
					"`Component`, but its value is `null`.\n" ..
					"    in Component"
			)
		end)

		itSKIP("should not check the default for explicit null", function()
			local expect: any = expect
			local Component = React.Component:extend("Component")
			function Component:render()
				return React.createElement("Frame", nil, self.props.prop)
			end
			Component.propTypes = {
				prop = PropTypes.string.isRequired,
			}
			Component.defaultProps = {
				prop = "text",
			}

			expect(function()
				ReactTestUtils.renderIntoDocument(React.createElement(Component, {prop = nil}))
			end).toErrorDev(
				"Warning: Failed prop type: The prop `prop` is marked as required in " ..
					"`Component`, but its value is `null`.\n" ..
					"    in Component"
			)
		end)

		itSKIP("should check declared prop types", function()
			local expect: any = expect
			local Component = React.Component:extend("Component")
			function Component:render()
				return React.createElement("Frame", nil, self.props.prop)
			end
			Component.propTypes = {
				prop = PropTypes.string.isRequired,
			}

			expect(function()
				ReactTestUtils.renderIntoDocument(React.createElement(Component))
				ReactTestUtils.renderIntoDocument(
					React.createElement(Component, {prop = 42})
				)
			end).toErrorDev({
				"Warning: Failed prop type: " ..
					"The prop `prop` is marked as required in `Component`, but its value " ..
					"is `undefined`.\n" ..
					"    in Component",
				"Warning: Failed prop type: " ..
					"Invalid prop `prop` of type `number` supplied to " ..
					"`Component`, expected `string`.\n" ..
					"    in Component",
			})

			-- // Should not error for strings
			ReactTestUtils.renderIntoDocument(React.createElement(Component, {
				prop = "string",
			}))
		end)

		itSKIP("should warn if a PropType creator is used as a PropType", function()
			local expect: any = expect
			local Component = React.Component:extend("Component")
			function Component:render()
				return React.createElement("Frame", nil, self.props.myProp.value)
			end
			Component.propTypes = {
				myProp = PropTypes.shape,
			}

			expect(function()
				ReactTestUtils.renderIntoDocument(
					React.createElement(Component, {myProp = {value = "hi"}})
				)
			end).toErrorDev(
				"Warning: Component: type specification of prop `myProp` is invalid; " ..
					"the type checker function must return `null` or an `Error` but " ..
					"returned a function. You may have forgotten to pass an argument to " ..
					"the type checker creator (arrayOf, instanceOf, objectOf, oneOf, " ..
					"oneOfType, and shape all require an argument)."
			)
		end)

		itSKIP("should warn if component declares PropTypes instead of propTypes", function()
			local expect: any = expect
			local MisspelledPropTypesComponent = React.Component:extend("MisspelledPropTypesComponent")
			function MisspelledPropTypesComponent:render()
				return React.createElement("Frame", nil, self.props.prop)
			end
			MisspelledPropTypesComponent.PropTypes = {
				prop = PropTypes.string,
			}

			expect(function()
				ReactTestUtils.renderIntoDocument(
					React.createElement(MisspelledPropTypesComponent, {prop = "Hi"})
				)
			end).toErrorDev(
				"Warning: Component MisspelledPropTypesComponent declared `PropTypes` " ..
					"instead of `propTypes`. Did you misspell the property assignment?",
				{withoutStack = true}
			)
		end)

		itSKIP("warns for fragments with illegal attributes", function()
			local expect: any = expect
			local Foo = React.Component:extend("Foo")
			function Foo:render()
				return React.createElement(React.Fragment, {a = 1}, "123")
			end
			expect(function()
				ReactTestUtils.renderIntoDocument(React.createElement(Foo))
			end).toErrorDev(
				"Invalid prop `a` supplied to `React.Fragment`. React.Fragment " ..
					"can only have `key` and `children` props."
			)
		end)

		if not _G.__EXPERIMENTAL__ then
			-- deviation: createFactory is deprecated in React so it is removed in
			-- the Lua version
			itSKIP("should warn when accessing .type on an element factory", function()
				local expect: any = expect
				local function TestComponent()
					return React.createElement("Frame")
				end

				local TestFactory

				expect(function()
					TestFactory = React.createFactory(TestComponent)
				end).toWarnDev(
					"Warning: React.createFactory() is deprecated and will be removed in a " ..
						"future major release. Consider using JSX or use React.createElement() " ..
						"directly instead.",
					{withoutStack = true}
				)
				expect(function()
					return TestFactory.type
				end).toWarnDev(
					"Warning: Factory.type is deprecated. Access the class directly before " ..
						"passing it to createFactory.",
					{withoutStack = true}
				)

				-- // Warn once, not again
				expect(TestFactory.type).toBe(TestComponent)
			end)
		end

		-- deviation: usage of web browser document global
		itSKIP("does not warn when using DOM node as children", function()
			-- local DOMContainer = React.Component:extend("DOMContainer")
			-- function DOMContainer:render()
			-- 	return React.createElement("Frame")
			-- end
			-- function DOMContainer:componentDidMount()
			-- 	ReactDOM.findDOMNode(self).appendChild(self.props.children);
			-- end

			-- local node = document.createElement("Frame")
			-- -- // This shouldn't cause a stack overflow or any other problems (#3883)
			-- ReactTestUtils.renderIntoDocument(
			-- 	React.createElement(DOMContainer, nil, node)
			-- )
		end)

		-- deviation: not applicable in Lua
		itSKIP('should not enumerate enumerable numbers (#4776)', function()
			-- Number.prototype['@@iterator'] = function()
			-- 	error("number iterator called")
			-- end
		end)

		it("does not blow up with inlined children", function()
			-- // We don't suggest this since it silences all sorts of warnings, but we
			-- // shouldn't blow up either.

			local child = {
				["$$typeof"] = React.createElement("Frame")["$$typeof"],
				type = "Frame",
				key = nil,
				ref = nil,
				props = {},
				_owner = nil,
			}

			React.createElement("Frame", nil, {child})
		end)

		it("does not blow up on key warning with undefined type", function()
			local expect: any = expect
			local Foo = nil

			expect(function()
				React.createElement(Foo, {
					__source = {
						fileName = "fileName.lua",
						lineNumber = 100,
					},
				}, {React.createElement("Frame")})
			end).toErrorDev(
				"Warning: React.createElement: type is invalid -- expected a string " ..
					"(for built-in components) or a class/function (for composite " ..
					"components) but got: nil. You likely forgot to export your " ..
					"component from the file it's defined in, or you might have mixed up " ..
					"default and named imports.\n\nCheck your code at **.",
				{withoutStack = true}
			)
		end)

		itSKIP("does not call lazy initializers eagerly", function()
			local didCall = false
			local Lazy = React.lazy(function()
				didCall = true
				return { ["then"] = function() end }
			end)
			React.createElement(Lazy)
			expect(didCall).to.equal(false)
		end)
	end)
end
