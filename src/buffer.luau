-- Some implementations are inspired by https://github.com/dekkonot/bitbuffer/

local privateKey = require("./privateKey")
local math = require("./math")
local string = require("./string")
local nativeTypes = require("./nativeTypes")
local typeof = require("./typeof")
local isNumber = require("./isNumber")
local expectNumber = require("./expectNumber")
local expectTable = require("./expectTable")
local expectString = require("./expectString")
local bit32 = require("./bit32")

local band = bit32.band
local rshift = bit32.rshift
local bor = bit32.bor
local lshift = bit32.lshift
local concat = table.concat
local btest = bit32.btest
local abs = math.abs
local frexp = math.frexp
local floor = math.floor
local ldexp = math.ldexp
local huge = math.huge
local byte = string.byte
local char = string.char

type buffer_polyfill = {
	[typeof(privateKey)]: { number },
}

local chars = {}
do
	for i = 0, 255 do
		chars[i + 1] = char(i)
	end
end

local BufferMetatable = {}

function BufferMetatable.__tostring(self: buffer_polyfill)
	return "buffer: " .. tostring(self[privateKey]):sub(8)
end

nativeTypes[BufferMetatable] = "buffer"

local function create(size: number): buffer_polyfill
	if _G.DALBIT_emulate_type_error then
		expectNumber(size, 1, "create")
	end

	local data = {}
	for i = 1, size do
		data[i] = 0
	end
	return setmetatable({
		[privateKey] = data,
	}, BufferMetatable) :: any
end

local function len(b: buffer_polyfill)
	if _G.DALBIT_runtime_type_checking then
		expectTable(b, "buffer", 1, "len")
	end

	return #b[privateKey]
end

local function copy(
	target: buffer_polyfill,
	targetOffset: number,
	source: buffer_polyfill,
	sourceOffset: number?,
	count: number?
)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "copy"
		expectTable(target, "buffer", 1, funcName)
		expectTable(source, "buffer", 3, funcName)
	end
	if _G.DALBIT_emulate_type_error then
		local funcName = "copy"
		expectNumber(targetOffset, 2, funcName)
		if sourceOffset ~= nil and not isNumber(sourceOffset) then
			error(`invalid argument #4 to '{funcName}' (number expected, got {typeof(sourceOffset)})`)
		end
		if count ~= nil and not isNumber(count) then
			error(`invalid argument #5 to '{funcName}' (number expected, got {typeof(count)})`)
		end
	end

	local sourceOffset = (sourceOffset or 0) + 1
	local targetOffset = (targetOffset or 0) + 1
	local count = count or 1
	local targetData = target[privateKey]
	local sourceData = source[privateKey]
	for i = 0, count - 1 do
		targetData[targetOffset + i] = sourceData[sourceOffset + i]
	end
end

local function fill(b: buffer_polyfill, offset: number, value: number, count: number)
	if _G.DALBIT_runtime_type_checking then
		expectTable(b, "buffer", 1, "fill")
	end
	if _G.DALBIT_emulate_type_error then
		local funcName = "fill"
		expectNumber(offset, 2, funcName)
		expectNumber(value, 3, funcName)
		expectNumber(count, 4, funcName)
	end

	local data = b[privateKey]
	count = count or (#data - offset + 1)
	value = band(value, 0xFF)

	for i = offset + 1, offset + count do
		data[i] = value
	end
end

-- unsigned integers

local function writeu8(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		expectTable(b, "buffer", 1, "writeu8")
	end
	if _G.DALBIT_emulate_type_error then
		local funcName = "writeu8"
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	if _G.DALBIT_buffer_out_of_bounds then
		local data = b[privateKey]
		if offset + 1 > #data then
			error("buffer access out of bounds")
		end
		data[offset + 1] = band(value, 0xFF)
		return
	end
	b[privateKey][offset + 1] = band(value, 0xFF)
end

local function writeu16(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writeu16"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 2 > #data then
			error("buffer access out of bounds")
		end
	end
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
end

local function writeu32(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writeu32"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 4 > #data then
			error("buffer access out of bounds")
		end
	end
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
	data[offset + 3] = band(rshift(value, 16), 0xFF)
	data[offset + 4] = band(rshift(value, 24), 0xFF)
end

local function readu8(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readu8"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end

	if _G.DALBIT_buffer_out_of_bounds then
		local data = b[privateKey]
		if offset + 1 > #data then
			error("buffer access out of bounds")
		end
		return data[offset + 1]
	end
	return b[privateKey][offset + 1]
end

local function readu16(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readu16"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 2 > #data then
			error("buffer access out of bounds")
		end
	end
	return bor(data[offset + 1], lshift(data[offset + 2], 8))
end

local function readu32(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readu32"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 4 > #data then
			error("buffer access out of bounds")
		end
	end
	return bor(
		bor(bor(data[offset + 1], lshift(data[offset + 2], 8)), lshift(data[offset + 3], 16)),
		lshift(data[offset + 4], 24)
	)
end

-- signed integers

local function writei8(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writei8"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	if value < 0 then
		value = (128 + value) + 128
	end

	if _G.DALBIT_buffer_out_of_bounds then
		local data = b[privateKey]
		if offset + 1 > #data then
			error("buffer access out of bounds")
		end
		data[offset + 1] = band(value, 0xFF)
		return
	end
	b[privateKey][offset + 1] = band(value, 0xFF)
end

local function writei16(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writei16"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	if value < 0 then
		value = (32768 + value) + 32768
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 2 > #data then
			error("buffer access out of bounds")
		end
	end
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
end

local function writei32(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writei32"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	if value < 0 then
		value = (2147483648 + value) + 2147483648
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 4 > #data then
			error("buffer access out of bounds")
		end
	end
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
	data[offset + 3] = band(rshift(value, 16), 0xFF)
	data[offset + 4] = band(rshift(value, 24), 0xFF)
end

local function readi8(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readi8"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end

	if _G.DALBIT_buffer_out_of_bounds then
		local data = b[privateKey]
		if offset + 1 > #data then
			error("buffer access out of bounds")
		end
		local value = data[offset + 1]
		local sign = btest(value, 128)
		value = band(value, 127)

		if sign then
			return value - 128
		else
			return value
		end
	end
	local value = b[privateKey][offset + 1]
	local sign = btest(value, 128)
	value = band(value, 127)

	if sign then
		return value - 128
	else
		return value
	end
end

local function readi16(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readi16"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 2 > #data then
			error("buffer access out of bounds")
		end
	end
	local value = bor(data[offset + 1], lshift(data[offset + 2], 8))
	local sign = btest(value, 32768)
	value = band(value, 32767)

	if sign then
		return value - 32768
	else
		return value
	end
end

local function readi32(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readi32"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 4 > #data then
			error("buffer access out of bounds")
		end
	end
	local value = bor(
		bor(bor(data[offset + 1], lshift(data[offset + 2], 8)), lshift(data[offset + 3], 16)),
		lshift(data[offset + 4], 24)
	)
	local sign = btest(value, 2147483648)
	value = band(value, 2147483647)

	if sign then
		return value - 2147483648
	else
		return value
	end
end

-- float

local function writef32(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writef32"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	local sign = value < 0
	value = abs(value)

	local mantissa, exponent = frexp(value)
	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 4 > #data then
			error("buffer access out of bounds")
		end
	end

	if value == huge then
		if sign then
			data[offset + 4] = 255 -- 11111111
		else
			data[offset + 4] = 127 -- 01111111
		end
		data[offset + 3] = 128
		data[offset + 2] = 0
		data[offset + 1] = 0
		return
	elseif value ~= value then
		data[offset + 4] = 127
		data[offset + 3] = 255
		data[offset + 2] = 255
		data[offset + 1] = 255
		return
	elseif value == 0 then
		data[offset + 4] = 0
		data[offset + 3] = 0
		data[offset + 2] = 0
		data[offset + 1] = 0
		return
	elseif exponent + 127 <= 1 then
		mantissa = floor(mantissa * 8388608 + 0.5)
		if sign then
			data[offset + 4] = 128 -- Sign bit, 7 empty bits for exponent
		else
			data[offset + 4] = 0
		end
		data[offset + 3] = rshift(mantissa, 16)
		data[offset + 2] = band(rshift(mantissa, 8), 255)
		data[offset + 1] = band(mantissa, 255)
		return
	end

	mantissa = floor((mantissa - 0.5) * 16777216 + 0.5)

	-- 127-1 = 126
	if sign then -- sign + 7 exponent
		data[offset + 4] = 128 + rshift(exponent + 126, 1)
	else
		data[offset + 4] = rshift(exponent + 126, 1)
	end

	data[offset + 3] = band(lshift(exponent + 126, 7), 255) + rshift(mantissa, 16) -- 1 exponent + 7 mantissa
	data[offset + 2] = band(rshift(mantissa, 8), 255) -- 8 mantissa
	data[offset + 1] = band(mantissa, 255) -- 8 mantissa
end

local function writef64(b: buffer_polyfill, offset: number, value: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writef64"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(offset, 3, funcName)
	end

	local sign = value < 0
	value = abs(value)

	local mantissa, exponent = frexp(value)
	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 8 > #data then
			error("buffer access out of bounds")
		end
	end

	if value == math.huge then
		if sign then
			data[offset + 8] = 255 -- 11111111
		else
			data[offset + 8] = 127 -- 01111111
		end
		data[offset + 7] = 240 -- 11110000
		data[offset + 6] = 0 -- 00000000
		data[offset + 5] = 0 -- 00000000
		data[offset + 4] = 0 -- 00000000
		data[offset + 3] = 0 -- 00000000
		data[offset + 2] = 0 -- 00000000
		data[offset + 1] = 0 -- 00000000
		return
	elseif offset ~= offset then
		-- 01111111 11111111 11111111 11111111 11111111 11111111 11111111 11111111
		data[offset + 8] = 127
		data[offset + 7] = 255
		data[offset + 6] = 255
		data[offset + 5] = 255
		data[offset + 4] = 255
		data[offset + 3] = 255
		data[offset + 2] = 255
		data[offset + 1] = 255
		return
	elseif value == 0 then
		data[offset + 1] = 0
		return
	elseif exponent + 1023 <= 1 then -- bias for doubles is 1023
		mantissa = floor(mantissa * 4503599627370496 + 0.5)
		if sign then
			data[offset + 8] = 128 -- Sign bit, 7 empty bits for exponent
		else
			data[offset + 8] = 0
		end

		-- This is labeled better below
		local leastSignificantChunk = mantissa % 0x100000000 -- 32 bits
		local mostSignificantChunk = floor(mantissa / 0x100000000) -- 20 bits

		data[offset + 7] = rshift(mostSignificantChunk, 16)
		data[offset + 6] = band(rshift(mostSignificantChunk, 8), 255)
		data[offset + 5] = band(mostSignificantChunk, 255)
		data[offset + 4] = rshift(leastSignificantChunk, 24)
		data[offset + 3] = band(rshift(leastSignificantChunk, 16), 255)
		data[offset + 2] = band(rshift(leastSignificantChunk, 8), 255)
		data[offset + 1] = band(leastSignificantChunk, 255)
		return
	end

	mantissa = floor((mantissa - 0.5) * 9007199254740992 + 0.5)

	--1023-1 = 1022
	if sign then
		data[offset + 8] = 128 + rshift(exponent + 1022, 4) -- shift out 4 of the bits in exponent
	else
		data[offset + 8] = rshift(exponent + 1022, 4) -- 01000001 0110
	end
	-- Things start to get a bit wack here because the mantissa is 52 bits, so bit32 *can't* be used.
	-- As the Offspring once said... You gotta keep 'em seperated.
	local leastSignificantChunk = mantissa % 0x100000000 -- 32 bits
	local mostSignificantChunk = floor(mantissa / 0x100000000) -- 20 bits

	-- First, the last 4 bits of the exponent and the first 4 bits of the mostSignificantChunk:
	data[offset + 7] = band(lshift(exponent + 1022, 4), 255) + rshift(mostSignificantChunk, 16)
	-- Then, the next 16 bits:
	data[offset + 6] = band(rshift(mostSignificantChunk, 8), 255)
	data[offset + 5] = band(mostSignificantChunk, 255)
	-- Then... 4 bytes of the leastSignificantChunk
	data[offset + 4] = rshift(leastSignificantChunk, 24)
	data[offset + 3] = band(rshift(leastSignificantChunk, 16), 255)
	data[offset + 2] = band(rshift(leastSignificantChunk, 8), 255)
	data[offset + 1] = band(leastSignificantChunk, 255)
end

local function readf32(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readf32"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end
	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 4 > #data then
			error("buffer access out of bounds")
		end
	end
	local b0 = data[offset + 4]
	local b1 = data[offset + 3]
	local sign = btest(b0, 128)
	local exponent = band(lshift(b0, 1), 255) + rshift(b1, 7)
	local mantissa = lshift(band(b1, 127), 23 - 7)
		+ lshift(data[offset + 2], 23 - 7 - 8)
		+ lshift(data[offset + 1], 23 - 7 - 8 - 8)

	if exponent == 255 then -- 2^8-1
		if mantissa ~= 0 then
			return 0 / 0
		else
			return sign and -huge or huge
		end
	elseif exponent == 0 then
		if mantissa == 0 then
			return 0
		else
			-- -126 is the 0-bias+1
			return sign and -ldexp(mantissa / 8388608, -126) or ldexp(mantissa / 8388608, -126)
		end
	end

	mantissa = (mantissa / 8388608) + 1

	return sign and -ldexp(mantissa, exponent - 127) or ldexp(mantissa, exponent - 127)
end

local function readf64(b: buffer_polyfill, offset: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readf64"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
	end
	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + 8 > #data then
			error("buffer access out of bounds")
		end
	end
	local b0 = data[offset + 8]
	local b1 = data[offset + 7]

	local sign = btest(b0, 128)
	local exponent = lshift(band(b0, 127), 4) + rshift(b1, 4)
	local mostSignificantChunk = lshift(band(b1, 15), 16) + lshift(data[offset + 6], 8) + data[offset + 5]
	local leastSignificantChunk = lshift(data[offset + 4], 24)
		+ lshift(data[offset + 3], 16)
		+ lshift(data[offset + 2], 8)
		+ data[offset + 1]

	-- local mantissa = (bit32.lshift(bit32.band(b1, 15), 16)+bit32.lshift(readByte(), 8)+readByte())*0x100000000+
	--     bit32.lshift(readByte(), 24)+bit32.lshift(readByte(), 16)+bit32.lshift(readByte(), 8)+readByte()

	local mantissa = mostSignificantChunk * 0x100000000 + leastSignificantChunk

	if exponent == 2047 then -- 2^11-1
		if mantissa ~= 0 then
			return 0 / 0
		else
			return sign and -huge or huge
		end
	elseif exponent == 0 then
		if mantissa == 0 then
			return 0
		else
			return sign and -ldexp(mantissa / 4503599627370496, -1022) or ldexp(mantissa / 4503599627370496, -1022)
		end
	end

	mantissa = (mantissa / 4503599627370496) + 1

	return sign and -ldexp(mantissa, exponent - 1023) or ldexp(mantissa, exponent - 1023)
end

-- string

local function writestring(b: buffer_polyfill, offset: number, value: string, count: number?)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "writestring"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectString(value, 3, funcName)
		if count ~= nil and not isNumber(count) then
			error(`invalid argument #4 to '{funcName}' (number expected, got {typeof(count)})`)
		end
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		local writeSize = count or #value
		if offset + writeSize > #data then
			error("buffer access out of bounds")
		end
		for i = 1, writeSize do
			data[offset + i] = byte(value, i, i)
		end
		return
	end
	for i = 1, count or #value do
		data[offset + i] = byte(value, i, i)
	end
end

local function readstring(b: buffer_polyfill, offset: number, count: number)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "readstring"
		expectTable(b, "buffer", 1, funcName)
		expectNumber(offset, 2, funcName)
		expectNumber(count, 3, funcName)
	end

	local data = b[privateKey]
	if _G.DALBIT_buffer_out_of_bounds then
		if offset + count > #data then
			error("buffer access out of bounds")
		end
	end
	local str = {}
	for i = 1, count do
		str[i] = chars[data[offset + i] + 1]
	end

	return concat(str)
end

-- serdes

local function tostring(b: buffer_polyfill): string
	if _G.DALBIT_runtime_type_checking then
		expectTable(b, "buffer", 1, "tostring")
	end

	local data = b[privateKey]
	local t = {}
	-- for i = #data, 1, -1 do
	-- 	t[i] = chars[data[i] + 1]
	-- end
	for i = 1, #data do
		t[i] = chars[data[i] + 1]
	end
	return concat(t)
end

local function fromstring(str: string): buffer_polyfill
	if _G.DALBIT_runtime_type_checking then
		expectString(str, 1, "fromstring")
	end

	local data = {}
	-- for i = #str, 1, -1 do
	-- 	data[i] = byte(str, i, i)
	-- end
	for i = 1, #str do
		data[i] = byte(str, i, i)
	end
	return setmetatable({
		[privateKey] = data,
	}, BufferMetatable) :: any
end

local dalbit_buffer
if not _G.DALBIT_test and buffer then
	dalbit_buffer = buffer :: any
else
	dalbit_buffer = {
		create = create,
		len = len,
		copy = copy,
		fill = fill,
		writeu8 = writeu8,
		writeu16 = writeu16,
		writeu32 = writeu32,
		readu8 = readu8,
		readu16 = readu16,
		readu32 = readu32,
		writei8 = writei8,
		writei16 = writei16,
		writei32 = writei32,
		readi8 = readi8,
		readi16 = readi16,
		readi32 = readi32,
		writef32 = writef32,
		writef64 = writef64,
		readf32 = readf32,
		readf64 = readf64,
		writestring = writestring,
		readstring = readstring,
		tostring = tostring,
		fromstring = fromstring,
	}
end

return dalbit_buffer :: typeof(buffer)
