return function()
    local Workspace = script.Parent.Parent.Parent
    local Packages = Workspace.Parent
    local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
    local ReactBaseClasses = require(Workspace.React.ReactBaseClasses)
    local Component = ReactBaseClasses.Component
    local PureComponent = ReactBaseClasses.Component
    local component


    describe("Component", function()
        it("should prevent extending a second time", function()
            component = Component:extend("Sheev")

            jestExpect(function()
                component:extend("Frank")
            end).toThrow()
        end)

        it("should use a given name", function()
            component = Component:extend("FooBar")

            local name = tostring(component)

            jestExpect(name).toEqual(jestExpect.any("string"))
            jestExpect(name).toContain("FooBar")
        end)
    end)

    describe("PureComponent", function()
        it("should prevent extending a second time", function()
            component = PureComponent:extend("Sheev")

            jestExpect(function()
                component:extend("Frank")
            end).toThrow()
        end)

        it("should use a given name", function()
            component = PureComponent:extend("FooBar")

            local name = tostring(component)

            jestExpect(name).toEqual(jestExpect.any("string"))
            jestExpect(name).toContain("FooBar")
        end)
    end)
end
