return function()
    local Workspace = script.Parent.Parent.Parent
    local isValidElementType = require(Workspace.Shared.isValidElementType)
    local ReactSymbols = require(Workspace.Shared.ReactSymbols)
    local element

    describe("accept element primitives", function()
        it("from strings", function()
            element = 'TextLabel'
            expect(isValidElementType(element)).to.equal(true)
        end)

        it("from functions", function()
            element = function() end
            expect(isValidElementType(element)).to.equal(true)
        end)

        it("from tables", function()
            element = {}
            element['$$typeof'] = ReactSymbols.REACT_CONTEXT_TYPE
            expect(isValidElementType(element)).to.equal(true)
        end)
    end)

    describe("does not accept", function()
        it("REACT_ELEMENT_TYPE", function()
            element = {}
            element['$$typeof'] = ReactSymbols.REACT_ELEMENT_TYPE
            expect(isValidElementType(element)).to.equal(false)
        end)
    end)
end
