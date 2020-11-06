return function()
    local clz32 = require(script.Parent.Parent.clz32)

    it("gives the number of leading zero of powers of 2", function()
        for i = 1, 32 do
            local value = 2^(i - 1)
            local expected = 32 - i
            expect(clz32(value)).to.equal(expected)
        end
    end)

    it("gives the number of leading zeros of random values", function()
        for _ = 1, 100 do
            local power = math.random(1, 31)
            local powerValue = 2^power
            local value = powerValue + math.random(1, powerValue - 1)

            expect(clz32(value)).to.equal(31 - power)
        end
    end)
end
