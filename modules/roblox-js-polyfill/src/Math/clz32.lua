local rshift = bit32.rshift
local log = math.log
local floor = math.floor
local LN2 = math.log(2)

return function(x: number): number
    -- convert to 32 bit integer
    local as32bit = rshift(x, 0)
    if as32bit == 0 then
        return 32
    end
    return 31 - floor(log(as32bit) / LN2)
end
