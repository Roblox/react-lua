-- upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react/src/__tests__/ReactElement-test.js

return function()
	local Packages = script.Parent.Parent.Parent
	local ReactElement = require(script.Parent.Parent.ReactElement)
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local isValidElementType = require(Packages.Shared).isValidElementType
	local ReactSymbols = require(Packages.Shared).ReactSymbols
	local element


	describe("creates valid React elements", function()
		it("from strings", function()
			element = ReactElement.createElement('TextLabel')
			jestExpect(element).toBeDefined()
			jestExpect(ReactElement.isValidElement(element)).toEqual(true)
			jestExpect(element['$$typeof']).toEqual(ReactSymbols.REACT_ELEMENT_TYPE)
			-- isValidElement considers basic ELEMENT_TYPE to be false
			jestExpect(isValidElementType(element)).toBe(false)
		end)

		it("from functions", function()
			element = ReactElement.createElement(function() end)
			jestExpect(element).toBeDefined()
			jestExpect(ReactElement.isValidElement(element)).toEqual(true)
			-- isValidElement considers basic ELEMENT_TYPE to be false
			jestExpect(isValidElementType(element)).toBe(false)
		end)
	end)

	describe("should accept", function()
		it("props", function()
			element = ReactElement.createElement("StringValue", { Value = "Foo" })

			jestExpect(element).toBeDefined()
			jestExpect(element.props.Value).toEqual("Foo")
			jestExpect(element.props.children).never.toBeDefined()

		end)

		it("a child and props", function()
			local child = ReactElement.createElement("IntValue")

			element = ReactElement.createElement("StringValue", { Value = "Foo" }, child)

			jestExpect(element).toBeDefined()
			jestExpect(element.props.Value).toEqual("Foo")
			jestExpect(element.props.children).toBeDefined()
			jestExpect(element.props.children).toEqual(child)
		end)

		it("a child and no props", function()
			local child = ReactElement.createElement("IntValue")

			element = ReactElement.createElement("StringValue", nil, child)

			jestExpect(element).toBeDefined()
			jestExpect(element.props.Value).toEqual(nil)
			jestExpect(element.props.children).toBeDefined()
			jestExpect(element.props.children).toEqual(child)
		end)

		it("multiple children and no props", function()
			local child1 = ReactElement.createElement("IntValue")
			local child2 = ReactElement.createElement("StringValue")

			element = ReactElement.createElement("StringValue", nil, child1, child2)

			jestExpect(element).toBeDefined()
			jestExpect(element.props.Value).toEqual(nil)
			jestExpect(element.props.children).toBeDefined()
			jestExpect(element.props.children).toEqual({child1, child2})
		end)

		it("a table of children and no props", function()
			local child1 = ReactElement.createElement("IntValue")
			local child2 = ReactElement.createElement("StringValue")

			element = ReactElement.createElement("StringValue", nil, {
				Child1 = child1,
				Child2 = child2,
			})

			jestExpect(element).toBeDefined()
			jestExpect(element.props.Value).toEqual(nil)
			jestExpect(element.props.children).toBeDefined()
			jestExpect(element.props.children).toEqual({
				Child1 = child1,
				Child2 = child2,
			})
		end)

		it("a false value for a boolean prop", function()
			element = ReactElement.createElement("BoolValue", { Value = false })

			jestExpect(element).toBeDefined()
			jestExpect(element.props.Value).toEqual(false)
		end)
	end)
end
