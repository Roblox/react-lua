return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)

	local ReactFiberSuspenseContext

	describe("ReactFiberSuspenseContext", function()
		beforeEach(function()
			RobloxJest.resetModules()
			ReactFiberSuspenseContext = require(script.Parent.Parent["ReactFiberSuspenseContext.new"])
		end)

		describe("suspense context stack", function()
			local someContext
			local fiber
			local suspenseStackCursor

			beforeEach(function()
				someContext = 0b1000
				fiber = {}
				suspenseStackCursor = ReactFiberSuspenseContext.suspenseStackCursor
			end)

			it("pushes the context and assigns the value to the cursor", function()
				local expect: any = expect
				ReactFiberSuspenseContext.pushSuspenseContext(fiber, someContext)
				expect(suspenseStackCursor).toEqual({current = someContext})
			end)

			it("pushes and pops and sets the cursor to its initial value", function()
				local expect: any = expect
				local initialValue = suspenseStackCursor.current

				ReactFiberSuspenseContext.pushSuspenseContext(fiber, someContext)
				ReactFiberSuspenseContext.popSuspenseContext(fiber)
				expect(suspenseStackCursor).toEqual({current = initialValue})
			end)
		end)

		describe("hasSuspenseContext", function()
			it("is true for parent context and its subtree context", function()
				local subtree = 0b1000
				local parent = ReactFiberSuspenseContext.addSubtreeSuspenseContext(10000, subtree)

				expect(
					ReactFiberSuspenseContext.hasSuspenseContext(parent, subtree)
				).to.equal(true)
			end)

			it("is false for two different context", function()
				expect(
					ReactFiberSuspenseContext.hasSuspenseContext(0b1000, 0b10000)
				).to.equal(false)
			end)
		end)
	end)
end
