-- upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react/src/__tests__/ReactElement-test.js
-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
--use custom matchers added via `expect.extend`
--!nocheck

return function()
	local Workspace = script.Parent.Parent.Parent
	local ReactElement = require(Workspace.React.ReactElement)
	local isValidElementType = require(Workspace.Shared.isValidElementType)
	local ReactSymbols = require(Workspace.Shared.ReactSymbols)
	local element


	describe("creates valid React elements", function()
		it("from strings", function()
			element = ReactElement.createElement('TextLabel')
			expect(element).to.be.ok()
			expect(ReactElement.isValidElement(element)).toEqual(true)
			expect(element['$$typeof']).toEqual(ReactSymbols.REACT_ELEMENT_TYPE)
			-- isValidElement considers basic ELEMENT_TYPE to be false
			expect(isValidElementType(element)).toEqual(false)
		end)

		it("from functions", function()
			element = ReactElement.createElement(function() end)
			expect(element).to.be.ok()
			expect(ReactElement.isValidElement(element)).toEqual(true)
			-- isValidElement considers basic ELEMENT_TYPE to be false
			expect(isValidElementType(element)).toEqual(false)
		end)
	end)

	describe("should accept", function()
		it("props", function()
			element = ReactElement.createElement("StringValue", { Value = "Foo" })

			expect(element).to.be.ok()
			expect(element.props.Value).toEqual("Foo")
			expect(element.props.children).never.to.be.ok()

		end)

		it("a child and props", function()
			local child = ReactElement.createElement("IntValue")

			element = ReactElement.createElement("StringValue", { Value = "Foo" }, child)

			expect(element).to.be.ok()
			expect(element.props.Value).toEqual("Foo")
			expect(element.props.children).to.be.ok()
			expect(element.props.children).toEqual(child)
		end)

		it("a child and no props", function()
			local child = ReactElement.createElement("IntValue")

			element = ReactElement.createElement("StringValue", nil, child)

			expect(element).to.be.ok()
			expect(element.props.Value).toEqual(nil)
			expect(element.props.children).to.be.ok()
			expect(element.props.children).toEqual(child)
		end)

		it("multiple children and no props", function()
			local child1 = ReactElement.createElement("IntValue")
			local child2 = ReactElement.createElement("StringValue")

			element = ReactElement.createElement("StringValue", nil, child1, child2)

			expect(element).to.be.ok()
			expect(element.props.Value).toEqual(nil)
			expect(element.props.children).to.be.ok()
			expect(element.props.children).toEqual({child1, child2})
		end)

		it("a table of children and no props", function()
			local child1 = ReactElement.createElement("IntValue")
			local child2 = ReactElement.createElement("StringValue")

			element = ReactElement.createElement("StringValue", nil, {
				Child1 = child1,
				Child2 = child2,
			})

			expect(element).to.be.ok()
			expect(element.props.Value).toEqual(nil)
			expect(element.props.children).to.be.ok()
			expect(element.props.children).toEqual({
				Child1 = child1,
				Child2 = child2,
			})
		end)
	end)
end
