-- Test file for old Roact compatibility layer

local Packages = script.Parent.Parent.Parent

return function()
    local React = require(Packages.React)
    local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

    describe("warns about deprecated Roact API features", function()
        beforeEach(function()
            React = require(Packages.React)
        end)

        it("warns once about createFragment", function()
            jestExpect(function()
                -- Warns first time
                React.createElement("div", nil, React.createFragment({React.createElement("div")}))
            end).toWarnDev("Warning: The legacy Roact createFragment API is deprecated, and will be removed in a future version.\n"..
                " Please use the supported createElement(React.Fragment, ...) API instead.", {withoutStack = true})

            if _G.__DEV__ then
                jestExpect(function()
                    -- Doesn't warn again 
                    React.createElement("div", nil, React.createFragment({React.createElement("div")}))
                end).never.toWarnDev("Warning: The legacy Roact createFragment API is deprecated, and will be removed in a future version.\n"..
                    " Please use the supported createElement(React.Fragment, ...) API instead.", {withoutStack = true})
            end
        end)
    end)

end