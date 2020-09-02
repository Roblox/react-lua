--!nonstrict
return function()
	local Timeout = require(script.Parent.Parent.Timeout)
	local createSpy = require(script.Parent.Parent.createSpy)

	local fakeTime, timeouts

	local function advanceTime(amount)
		fakeTime += amount
		for _, update in pairs(timeouts) do
			update(fakeTime)
		end
	end

	local function fakeDelay(delayTime, callback)
		local targetTime = fakeTime + delayTime
		print("Running callback in", delayTime, "simulated seconds...")
		timeouts[callback] = function(time)
			if time >= targetTime then
				callback()
				timeouts[callback] = nil
			end
		end
	end

	beforeEach(function()
		fakeTime = 0
		timeouts = {}
		getfenv(Timeout.setTimeout).delay = fakeDelay
	end)

	afterEach(function()
		getfenv(Timeout.setTimeout).delay = delay
	end)

	describe("Delay override logic", function()
		it("should not run delayed callbacks immediately", function()
			local callbackSpy = createSpy()
			Timeout.setTimeout(callbackSpy.value, 0.05)

			expect(callbackSpy.callCount).to.equal(0)
		end)

		it("should run callbacks after timers have been advanced sufficiently", function()
			local callbackSpy = createSpy()
			Timeout.setTimeout(callbackSpy.value, 0.1)

			expect(callbackSpy.callCount).to.equal(0)

			advanceTime(0.05)
			expect(callbackSpy.callCount).to.equal(0)
			advanceTime(0.05)
			expect(callbackSpy.callCount).to.equal(1)
		end)
	end)

	describe("Timeout", function()
		it("should run exactly once", function()
			local callbackSpy = createSpy()
			Timeout.setTimeout(callbackSpy.value, 0.1)

			expect(callbackSpy.callCount).to.equal(0)

			advanceTime(0.1)
			expect(callbackSpy.callCount).to.equal(1)

			advanceTime(0.1)
			expect(callbackSpy.callCount).to.equal(1)
			advanceTime(1)
			expect(callbackSpy.callCount).to.equal(1)
		end)

		it("should be called with the given args", function()
			local callbackSpy = createSpy()
			Timeout.setTimeout(callbackSpy.value, 0.1, "hello", "world")

			advanceTime(0.1)
			expect(callbackSpy.callCount).to.equal(1)
			callbackSpy:assertCalledWith("hello", "world")
		end)

		it("should not run if cancelled before it is scheduled to run", function()
			local callbackSpy = createSpy()
			local task = Timeout.setTimeout(callbackSpy.value, 0.1)

			expect(callbackSpy.callCount).to.equal(0)

			Timeout.clearTimeout(task)
			advanceTime(0.1)
			expect(callbackSpy.callCount).to.equal(0)
		end)
	end)
end