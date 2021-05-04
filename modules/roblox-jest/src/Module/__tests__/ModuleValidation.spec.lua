--!nocheck
return function()
	local Module = require(script.Parent.Parent)
	local Workspace = script.Parent.Parent.Parent.Parent
	local Packages = Workspace.Parent
	local jestModule = require(Packages.Dev.JestRoblox)
	local jestExpect = jestModule.Globals.expect

	local warnings = {}
	local function overrideWarn(fn, ...)
		local originalWarn = getfenv(fn).warn
		getfenv(fn).warn = function(...)
			table.insert(warnings, {...})
		end
		fn(...)
		getfenv(fn).warn = originalWarn
	end

	beforeEach(function()
		warnings = {}
		Module.resetModules()
	end)

	it("should warn when mocking an already-mocked function", function()
		-- mock `add` with math.min
		overrideWarn(Module.mock, script.Parent.TestScripts.add, math.min)

		jestExpect(#warnings).toBe(0)

		-- mock `add` again, this time with with math.max
		overrideWarn(Module.mock, script.Parent.TestScripts.add, math.max)

		jestExpect(#warnings).toBe(1)
		local warning = warnings[1][1]
		jestExpect(warning).toContain("add")
	end)

	it("should warn when unmocking a not-currently-mocked function", function()
		-- unmock `add`, which won't be mocked after the `beforeEach` reset
		overrideWarn(Module.unmock, script.Parent.TestScripts.add)

		jestExpect(#warnings).toBe(1)
		local warning = warnings[1][1]
		jestExpect(warning).toContain("add")
	end)

	it("should throw an error when a module returns none", function()
		jestExpect(function()
			Module.requireOverride(script.Parent.TestScripts.NoReturn)
		end).toThrow("NoReturn")
	end)

	it("should throw an error when a module returns nil", function()
		jestExpect(function()
			Module.requireOverride(script.Parent.TestScripts.ReturnsNil)
		end).toThrow("ReturnsNil")
	end)
end