--!nonstrict
return function()
	local makeConsoleImpl = require(script.Parent.Parent.makeConsoleImpl)

	local console, capturedPrints, capturedWarns

	local function capturePrint(...)
		-- mimic `print`'s concatenation of var-args
		table.insert(capturedPrints, table.concat({...}, " "))
	end

	local function overridePrint(fn, ...)
		local originalPrint = getfenv(fn).print
		getfenv(fn).print = capturePrint
		fn(...)
		getfenv(fn).print = originalPrint
	end

	local function captureWarn(...)
		-- mimic `print`'s concatenation of var-args
		table.insert(capturedWarns, table.concat({...}, " "))
	end

	local function overrideWarn(fn, ...)
		local originalWarn = getfenv(fn).warn
		getfenv(fn).warn = captureWarn
		fn(...)
		getfenv(fn).warn = originalWarn
	end

	beforeEach(function()
		capturedPrints = {}
		capturedWarns = {}
		console = makeConsoleImpl()
	end)

	describe("log", function()
		it("should print a given message", function()
			overridePrint(console.log, "This is a message")

			expect(#capturedPrints).to.equal(1)
			expect(capturedPrints[1]).to.equal("This is a message")
		end)

		it("should print a message with formatting", function()
			overridePrint(console.log, "%d bottles", 99)
			overridePrint(console.log, "of %s on the wall", "soda")

			expect(#capturedPrints).to.equal(2)
			expect(capturedPrints[1]).to.equal("99 bottles")
			expect(capturedPrints[2]).to.equal("of soda on the wall")
		end)
	end)

	-- `info` works exactly like `log` for now
	describe("info", function()
		it("should print a given message", function()
			overridePrint(console.info, "This is a message")

			expect(#capturedPrints).to.equal(1)
			expect(capturedPrints[1]).to.equal("This is a message")
		end)

		it("should print a message with formatting", function()
			overridePrint(console.info, "%d bottles", 99)
			overridePrint(console.info, "of %s on the wall", "soda")

			expect(#capturedPrints).to.equal(2)
			expect(capturedPrints[1]).to.equal("99 bottles")
			expect(capturedPrints[2]).to.equal("of soda on the wall")
		end)
	end)

	describe("warn", function()
		it("should use the 'warn' builtin", function()
			overrideWarn(console.warn, "This is a warning")

			expect(#capturedWarns).to.equal(1)
			expect(capturedWarns[1]).to.equal("This is a warning")
		end)

		it("should print a warning with formatting", function()
			overrideWarn(console.warn, "%d bottles", 99)
			overrideWarn(console.warn, "of %s on the wall", "soda")

			expect(#capturedWarns).to.equal(2)
			expect(capturedWarns[1]).to.equal("99 bottles")
			expect(capturedWarns[2]).to.equal("of soda on the wall")
		end)
	end)

	-- `error` works exactly like `warn` for now
	describe("error", function()
		it("should use the 'warn' builtin", function()
			overrideWarn(console.error, "This is an error")

			expect(#capturedWarns).to.equal(1)
			expect(capturedWarns[1]).to.equal("This is an error")
		end)

		it("should print an error with formatting", function()
			overrideWarn(console.error, "%d bottles", 99)
			overrideWarn(console.error, "of %s on the wall", "soda")

			expect(#capturedWarns).to.equal(2)
			expect(capturedWarns[1]).to.equal("99 bottles")
			expect(capturedWarns[2]).to.equal("of soda on the wall")
		end)
	end)

	describe("groups", function()
		it("adds indentation to subsequent logs", function()
			overridePrint(console.group, "begin group")
			overridePrint(console.log, "some log")
			console.groupEnd()
			overridePrint(console.log, "no more group")

			expect(#capturedPrints).to.equal(3)
			expect(capturedPrints[1]).to.equal("begin group")
			expect(capturedPrints[2]).to.equal("  some log")
			expect(capturedPrints[3]).to.equal("no more group")
		end)

		it("nests several layers deep", function()
			overridePrint(console.group, "begin group 1")
			overridePrint(console.log, "once indented")
			overridePrint(console.group, "begin group 2")
			overridePrint(console.log, "twice indented")
			console.groupEnd()
			overridePrint(console.log, "once indented")
			console.groupEnd()
			overridePrint(console.log, "not indented")

			expect(#capturedPrints).to.equal(6)
			expect(capturedPrints[1]).to.equal("begin group 1")
			expect(capturedPrints[2]).to.equal("  once indented")
			expect(capturedPrints[3]).to.equal("  begin group 2")
			expect(capturedPrints[4]).to.equal("    twice indented")
			expect(capturedPrints[5]).to.equal("  once indented")
			expect(capturedPrints[6]).to.equal("not indented")
		end)

		it("does not print anything when ending a group", function()
			overridePrint(console.group, "begin group")
			overridePrint(console.groupEnd)

			expect(#capturedPrints).to.equal(1)
			expect(capturedPrints[1]).to.equal("begin group")
		end)

		it("does nothing when 'ending' a non-existent group", function()
			expect(function()
				console.groupEnd()
			end).never.to.throw()
		end)

		it("works correctly after 'ending' a non-existent group", function()
			console.groupEnd()
			overridePrint(console.log, "top-level message")
			overridePrint(console.group, "begin group")
			overridePrint(console.log, "group 1 message")
			console.groupEnd()
			overridePrint(console.log, "top-level message")

			expect(#capturedPrints).to.equal(4)
			expect(capturedPrints[1]).to.equal("top-level message")
			expect(capturedPrints[2]).to.equal("begin group")
			expect(capturedPrints[3]).to.equal("  group 1 message")
			expect(capturedPrints[4]).to.equal("top-level message")
		end)
	end)
end