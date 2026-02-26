-- credits to https://github.com/luau-lang/luau/blob/master/VM/src/ltable.cpp

local bit32 = require("./bit32")
local buffer = require("./buffer")
local expectTable = require("./expectTable")

local bufferFromString = buffer.fromstring
local readu32 = buffer.readu32
local bxor = bit32.bxor
local sub = string.sub
local lshift = bit32.lshift
local rshift = bit32.rshift
local byte = string.byte
local bor = bit32.bor
local createBuffer = buffer.create
local writef64 = buffer.writef64
local ceil = math.ceil
local log  = math.log
local floor = math.floor
local band = bit32.band

local MAXBITS = 26
local MAXSIZE = lshift(1, MAXBITS)
local LN2 = math.log(2)

type LuaNode_key_val_next = { any }

local function rol(x, s)
	return bor(rshift(x, s), lshift(x, 32 - s))
end

local function hashstr(str: string)
	local len = #str
	-- Note that this hashing algorithm is replicated in BytecodeBuilder.cpp, BytecodeBuilder::getStringHash
	local a, b = 0, 0
	local h = len

	-- hash prefix in 12b chunks (using aligned reads) with ARX based hash (LuaJIT v2.1, lookup3)
	-- note that we stop at length<32 to maintain compatibility with Lua 5.1
	while len >= 32 do

		local block = bufferFromString(str)
		a = a + readu32(block, 0)
		b = b + readu32(block, 1)
		h = h + readu32(block, 2)

		--mix(14, 11, 25)
		a = bxor(a, h)
		a = a - rol(h, 14)
		b = bxor(b, a)
		b = b - rol(a, 11)
		h = bxor(h, b)
		h = h - rol(b, 25)

		str = sub(str, 12 + 1)
		-- str += 12
		len -= 12
	end

	-- original Lua 5.1 hash for compatibility (exact match when len<32)
	for i = len, 1, -1 do
		h = bxor(h, lshift(h, 5) + rshift(h, 2) + byte(str, i))
	end

	return h
end

local function mult(a: number, b: number): number
	local ah, al = rshift(a, 16), a % 2 ^ 16
	local bh, bl = rshift(b, 16), b % 2 ^ 16
	return bor(lshift((ah * bl) + (al * bh), 16) + (al * bl), 0)
end

local function hashnum(n: number)
	local i = createBuffer(8)
	writef64(i, 0, n)

	-- mask out sign bit to make sure -0 and 0 hash to the same value
	local h1 = readu32(i, 0)
	local h2 = band(readu32(i, 4), 0x7fffffff);

	-- finalizer from MurmurHash64B
	local m = 0x5bd1e995
	h1 = bxor(h1, rshift(h2, 18))
	h1 = mult(h1, m)
	h2 = bxor(h2, rshift(h1, 22))
	h2 = mult(h2, m)
	h1 = bxor(h1, rshift(h2, 17))
	h1 = mult(h1, m)
	h2 = bxor(h2, rshift(h1, 19))
	h2 = mult(h2, m)

	-- print("to be hashed:", n, "hash:", h2, "hashpow2:", (h2 % 8) + 1)

	-- ... truncated to 32-bit output (normally hash is equal to (uint64_t(h1) << 32) | h2, but we only really need the lower 32-bit half)
	return h2
end

local function hashpointer(p: any)
	local str = tostring(p)
	local len = #str
	-- Note that this hashing algorithm is replicated in BytecodeBuilder.cpp, BytecodeBuilder::getStringHash
	local a, b = 0, 0
	local h = len

	-- hash prefix in 12b chunks (using aligned reads) with ARX based hash (LuaJIT v2.1, lookup3)
	-- note that we stop at length<32 to maintain compatibility with Lua 5.1
	while len >= 32 do

		local block = bufferFromString(str)
		a = a + readu32(block, 0)
		b = b + readu32(block, 1)
		h = h + readu32(block, 2)

		--mix(14, 11, 25)
		a = bxor(a, h)
		a = a - rol(h, 14)
		b = bxor(b, a)
		b = b - rol(a, 11)
		h = bxor(h, b)
		h = h - rol(b, 25)

		str = sub(str, 12 + 1)
		-- str += 12
		len = len - 12
	end

	-- original Lua 5.1 hash for compatibility (exact match when len<32)
	for i = len, 1, -1 do
		h = bxor(h, lshift(h, 5) + rshift(h, 2) + byte(str, i))
	end

	return h
end

local boolToNumber = {
	[false] = 0,
	[true] = 1
}

local function hashbool(b: boolean)
	return boolToNumber[b]
end

local mainposition_getters = {
	string = hashstr,
	number = hashnum,
	boolean = hashbool,
}

return function<K, V>(t: {[K]: V}, key: K?): (K?, V)
	if _G.DALBIT_runtime_type_checking then
		expectTable(t, "table", 1, "next")
	end

	local nodes = { n = 0 }

	-- sets arrayvector and nodevector
	local sizearray = 0
	local sizenode = 0
	local array: { any } = {}
	for i, v in next, t do
		if type(i) == "number" and (array[i - 1] ~= nil or i == 1) then -- check if entries are continuous
			array[i] = v
			sizearray += 1
		else
			sizenode += 1
		end
	end
	local oldnhash = nodes.n
	local requireRehash = oldnhash ~= sizenode
	local lsize = ceil(log(sizenode) / LN2)
	local nhash = sizenode
	sizenode = sizenode < 1 and 1 or lshift(1, lsize)
	local keyType = type(key)

	if _G.DALBIT_emulate_type_error then
		if sizearray > MAXSIZE then
			error("table overflow")
		end

		if lsize > MAXBITS then
			error("table overflow")
		end
	end

	if requireRehash then
		if oldnhash > 0 then
			for i, _ in next, nodes do
				nodes[i] = nil
			end
		end
		nodes.n = nhash

		local lastfree = sizenode + 1

		-- create new keys
		for k, v in next, t do
			if array[k :: any] ~= nil then -- skip array
				continue
			end
			local mp = (mainposition_getters[type(k)] or hashpointer)(k) % sizenode + 1 -- mainposition(sizenode, k)
			local colliding = nodes[mp]
			if colliding then
				local freenode
				while lastfree > 0 do
					lastfree -= 1
					if not nodes[lastfree] then
						freenode = {
							k,
							v,
							0
						} :: LuaNode_key_val_next
						nodes[lastfree] = freenode
						break
					end
				end
				if lastfree < 1 then
					error("cannot find a free place")
				end
				if colliding[3] ~= 0 then
					freenode[3] = (mp + colliding[3]) - lastfree -- chaining
				end
				-- print(`collider key: {k} key collided with: {colliding[1]} at: {mp}`)
				-- print(`free pos found at: {lastfree}`)
				colliding[3] = lastfree - mp
				mp = lastfree
				-- local n = nodes[mp]
				-- n[1] = k
				-- n[2] = v
			else
				nodes[mp] = {
					k,
					v,
					0
				}
			end
		end
	end

	-- find a index
	local i = 0
	if key ~= nil then
		if keyType == "number" then
			if floor(key :: any) == key :: any then
				i = key :: any
			end
		end
		if 0 >= i or i > sizearray then -- is `key' outside array part?
			local np = (mainposition_getters[keyType] or hashpointer)(key) % sizenode + 1 -- mainposition(sizenode, key)
			local n = nodes[np]
			local notfound = true
			while true do -- check whether `key' is somewhere in the chain
				-- key may be dead already, but it is ok to use it in `next'
				if rawequal(n[1], key) then
					i = np
					-- i = cast_int(n - gnode(t, 0)) -- key index in hash table
					-- hash elements are numbered after array ones
					i = i + sizearray
					notfound = false
					break
				end
				if n[3] == 0 then
					break
				end
				np += n[3]
				n = nodes[np]
			end
			if notfound then
				error("invalid key to 'next'") -- key not found
			end
		end
	end

	i += 1 -- next!
	while i - 1 < sizearray do -- try first array part
		if array[i] ~= nil then -- a non-nil value?
			return i :: any, array[i]
		end

		i += 1
	end

	i -= sizearray
	while i - 1 < sizenode do -- then hash part
		if nodes[i] ~= nil then -- a non-nil value?
			key = nodes[i][1]

			return key, nodes[i][2]
		end

		i += 1
	end

	return nil, nil :: any
end
