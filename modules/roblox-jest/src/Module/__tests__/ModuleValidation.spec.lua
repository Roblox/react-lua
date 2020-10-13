--!nocheck
return function()
	local Module = require(script.Parent.Parent)

	local warnings = {}
	local function overrideWarn(fn, ...)
		local originalWarn = getfenv(fn).warn
		getfenv(fn).warn = function(...)
			table.insert(warnings, {...})
		end
		fn(...)
		getfenv(fn).warn = originalWarn
	end

	beforeAll(function()
		expect.extend({
			toThrow = require(script.Parent.Parent.Parent.Matchers.toThrow),
		})
	end)

	beforeEach(function()
		warnings = {}
		Module.resetModules()
	end)

	it("should warn when mocking an already-mocked function", function()
		-- mock `add` with math.min
		overrideWarn(Module.mock, script.Parent.TestScripts.add, math.min)

		expect(#warnings).to.equal(0)

		-- mock `add` again, this time with with math.max
		overrideWarn(Module.mock, script.Parent.TestScripts.add, math.max)

		expect(#warnings).to.equal(1)
		local warning = warnings[1][1]
		expect(string.find(warning, "add")).to.be.ok()
	end)

	it("should warn when unmocking a not-currently-mocked function", function()
		-- unmock `add`, which won't be mocked after the `beforeEach` reset
		overrideWarn(Module.unmock, script.Parent.TestScripts.add)

		expect(#warnings).to.equal(1)
		local warning = warnings[1][1]
		expect(string.find(warning, "add")).to.be.ok()
	end)

	it("should throw an error when a module returns none", function()
		expect(function()
			Module.requireOverride(script.Parent.TestScripts.NoReturn)
		end).toThrow("NoReturn")
	end)

	it("should throw an error when a module returns nil", function()
		expect(function()
			Module.requireOverride(script.Parent.TestScripts.ReturnsNil)
		end).toThrow("ReturnsNil")
	end)
end