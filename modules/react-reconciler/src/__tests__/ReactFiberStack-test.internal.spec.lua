return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)

	local ReactFiberStack

	describe("ReactFiberStack", function()
		beforeEach(function()
			RobloxJest.resetModules()
			ReactFiberStack = require(script.Parent.Parent["ReactFiberStack.new"])
		end)

		it("creates a cursor with the given default value", function()
			local expect: any = expect
			local defaultValue = {foo = 3}
			expect(ReactFiberStack.createCursor(defaultValue)).toEqual({current = defaultValue})
		end)

		it("initializes the stack empty", function()
			expect(ReactFiberStack.isEmpty()).to.equal(true)
		end)

		describe("stack manipulations", function()
			local cursor
			local fiber

			beforeEach(function()
				cursor = ReactFiberStack.createCursor(nil)
				fiber = {}
			end)

			it("pushes an element and the stack is not empty", function()
				ReactFiberStack.push(cursor, true, fiber)
				expect(ReactFiberStack.isEmpty()).to.equal(false)
			end)

			it("pushes an element and assigns the value to the cursor", function()
				local expect: any = expect
				local pushedElement = {foo = 3}
				ReactFiberStack.push(cursor, pushedElement, fiber)
				expect(cursor.current).toEqual(pushedElement)
			end)

			it("pushes an element, pops it back and the stack is empty", function()
				ReactFiberStack.push(cursor, true, fiber)
				ReactFiberStack.pop(cursor, fiber)
				expect(ReactFiberStack.isEmpty()).to.equal(true)
			end)

			it("pushes an element, pops it back and the cursor has its initial value", function()
				local initialCursorValue = "foo"
				cursor.current = initialCursorValue

				ReactFiberStack.push(cursor, true, fiber)
				ReactFiberStack.pop(cursor, fiber)
				expect(cursor.current).to.equal(initialCursorValue)
			end)
		end)
	end)
end
