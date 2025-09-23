local expectNumber = require("./expectNumber")

local LN2 = math.log(2)
local log = math.log
local floor = math.floor

local band
local rshift
local lshift
local bnot
local bor
local bxor
if bit32 and _G.DALBIT_test == false then
	band = bit32.band
	rshift = bit32.rshift
	lshift = bit32.lshift
	bnot = bit32.bnot
	bor = bit32.bor
	bxor = bit32.bxor
else
	-- credits to https://github.com/orpos/dal-polyfill/blob/main/src/bit32.luau
	band = function(...: number): number
		local args = {...}
		local a = args[1]

		if _G.DALBIT_emulate_type_error then
			expectNumber(a, 1, "band")
		end

		for i = 2, #args do
			local b = args[i]
			a %= 0x100000000
			b %= 0x100000000

			if _G.DALBIT_emulate_type_error then
				expectNumber(b, i, "band")
			end

			local result = 0
			local bit = 1
			while a > 0 and b > 0 do
				if a % 2 == 1 and b % 2 == 1 then
					result = result + bit
				end
				a = floor(a / 2)
				b = floor(b / 2)
				bit = bit * 2
			end

			a = result
		end

		return a
	end

	rshift = function(a: number, b: number): number
		if _G.DALBIT_emulate_type_error then
			local funcName = "rshift"
			expectNumber(a, 1, funcName)
			expectNumber(b, 2, funcName)
		end

		if b < 0 then
			return lshift(a, -b)
		end
		if a < 0 then
			a %= 0x100000000
		end
		return floor(a / (2 ^ b)) % 0x100000000
	end

	lshift = function(a: number, b: number): number
		if _G.DALBIT_emulate_type_error then
			local funcName = "lshift"
			expectNumber(a, 1, funcName)
			expectNumber(b, 2, funcName)
		end

		if b < 0 then
			return rshift(a, -b)
		end
		return floor(band(a * (2 ^ b), 0xFFFFFFFF))
	end

	bnot = function(a: number): number
		if _G.DALBIT_emulate_type_error then
			expectNumber(a, 1, "bnot")
		end

		a = floor(a % 0x100000000)
		return (-1 - a) % (2 ^ 32)
	end

	bor = function(...: number)
		local args = {...}
		local a = args[1]

		if _G.DALBIT_emulate_type_error then
			expectNumber(a, 1, "bor")
		end

		for i = 2, #args do
			local b = args[i]
			a = floor(a % 0x100000000)
			b = floor(b % 0x100000000)

			if _G.DALBIT_emulate_type_error then
				expectNumber(b, i, "bor")
			end

			local r: number, m: number, s: number = 0, 2 ^ 31, a + b + 2 ^ 31
			repeat
				s, a, b = a + b + m, a % m, b % m
				r, m = r + m * 1 % (s - a - b), m / 2
			until m < 1

			a = r
		end

		return a
	end

	bxor = function(...: number)
		local args = {...}
		local a = args[1]

		if _G.DALBIT_emulate_type_error then
			expectNumber(a, 1, "bor")
		end

		for i = 2, #args do
			local b = args[i]
			a = floor(a % 0x100000000)
			b = floor(b % 0x100000000)

			if _G.DALBIT_emulate_type_error then
				expectNumber(b, i, "bor")
			end

			local result = 0
			local bit = 1
			while a > 0 or b > 0 do
				local a_bit = a % 2
				local b_bit = b % 2
				if a_bit ~= b_bit then
					result = result + bit
				end
				a = floor(a / 2)
				b = floor(b / 2)
				bit = bit * 2
			end

			a = result
		end

		return a
	end
end

local function arshift(x: number, disp: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "arshift"
		expectNumber(x, 1, funcName)
		expectNumber(disp, 2, funcName)
	end

	x = band(x, 0xFFFFFFFF)

	local z = rshift(x, disp)

	if band(x, 0x80000000) ~= 0 then
		z = bor(z, lshift(0xFFFFFFFF, 32 - disp))
	end

	return z
end

local function btest(x: number, y: number): boolean -- can be converted directly into `((x&y)&0xFFFFFFFF~=0)`
	return band(x, y) ~= 0
end

local function extract(n: number, field: number, width: number?): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "extract"
		expectNumber(n, 1, funcName)
		expectNumber(field, 2, funcName)
	end

	width = width or 1
	return band(rshift(n, field), 2 ^ width :: number - 1)
end

local function rrotate(x: number, disp: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "rrotate"
		expectNumber(x, 1, funcName)
		expectNumber(disp, 2, funcName)
	end

	disp = disp % 32
	local low = band(x, 2 ^ disp - 1)
	return rshift(x, disp) + lshift(low, 32 - disp)
end

local function lrotate(x: number, disp: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "rrotate"
		expectNumber(x, 1, funcName)
		expectNumber(disp, 2, funcName)
	end

	return rrotate(x, -disp)
end

local function replace(n: number, v: number, field: number, width: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "replace"
		expectNumber(n, 1, funcName)
		expectNumber(v, 2, funcName)
		expectNumber(field, 3, funcName)
		expectNumber(width, 4, funcName)
	end

	width = width or 1
	local mask1 = 2 ^ width - 1
	v = band(v, mask1) -- required by spec?
	local mask = bnot(lshift(mask1, field))
	return band(n, mask) + lshift(v, field)
end

local function countrz(x: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(x, 1, "countrz")
	end

	local as32bit = rshift(x, 0)
	if as32bit == 0 then
		return 32
	end

	local count = 0
	while band(as32bit, 1) == 0 do
		as32bit = rshift(as32bit, 1)
		count += 1
	end
	return count
end

local function countlz(x: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(x, 1, "countlz")
	end

	local as32bit = rshift(x, 0)
	if as32bit == 0 then
		return 32
	end
	return 31 - floor(log(as32bit) / LN2)
end

local function byteswap(n: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(n, 1, "byteswap")
	end

	return bor(bor(bor(lshift(n, 24), band(lshift(n, 8), 0xff0000)), band(rshift(n, 8), 0xff00)), rshift(n, 24))
end

return {
	arshift = arshift :: typeof(bit32.arshift),
	btest = btest :: typeof(bit32.btest),
	extract = extract :: typeof(bit32.extract),
	rrotate = rrotate :: typeof(bit32.rrotate),
	lrotate = lrotate :: typeof(bit32.lrotate),
	replace = replace :: typeof(bit32.replace),
	countrz = countrz :: typeof(bit32.countrz),
	countlz = countlz :: typeof(bit32.countlz),
	byteswap = byteswap :: typeof(bit32.byteswap),
	band = band,
	rshift = rshift,
	lshift = lshift,
	bnot = bnot,
	bor = bor,
	bxor = bxor
}
