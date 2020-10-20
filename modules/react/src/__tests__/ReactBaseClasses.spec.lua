-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
--use custom matchers added via `expect.extend`
--!nocheck

return function()
    local Workspace = script.Parent.Parent.Parent
    local ReactBaseClasses = require(Workspace.React.ReactBaseClasses)
    local Component = ReactBaseClasses.Component
    local PureComponent = ReactBaseClasses.Component
    local component


    describe("Component", function()
        it("should prevent extending a second time", function()
            component = Component:extend("Sheev")

            expect(function()
                component:extend("Frank")
            end).to.throw()
        end)

        it("should use a given name", function()
            component = Component:extend("FooBar")

            local name = tostring(component)

            expect(name).to.be.a("string")
            expect(name:find("FooBar")).to.be.ok()
        end)
    end)

    describe("PureComponent", function()
        it("should prevent extending a second time", function()
            component = PureComponent:extend("Sheev")

            expect(function()
                component:extend("Frank")
            end).to.throw()
        end)

        it("should use a given name", function()
            component = PureComponent:extend("FooBar")

            local name = tostring(component)

            expect(name).to.be.a("string")
            expect(name:find("FooBar")).to.be.ok()
        end)
    end)
end

