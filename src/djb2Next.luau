local djb2 = require("./djb2")
local expectTable = require("./expectTable")

local insert = table.insert
local sort = table.sort

local function compareHash(a: any, b)
	return a.hash < b.hash
end

return function<K, V>(t: {[K]: V}, key: K?): (K?, V)
	if _G.DALBIT_runtime_type_checking then
		expectTable(t, "table", 1, "next")
	end

	local hashList = {}
	local array: { any } = {}
	for k in next, t do
		local hash
		if type(k) == "number" and (array[k - 1] or k == 1) then
			hash = k
			array[k] = true
		else
			hash = djb2(tostring(k)) :: any
		end
		insert(hashList, { key = k, hash = hash })
	end

	sort(hashList, compareHash)

	local index_map = {}
	for i, entry in ipairs(hashList) do
		index_map[entry.key] = i
	end

	if key == nil then
		return hashList[1] and hashList[1].key, t[hashList[1].key]
	else
		local current_index = index_map[key]
		if not current_index then
			error("Invalid key passed to next")
		end
		local next_entry = hashList[current_index + 1]
		if next_entry then
			return next_entry.key, t[next_entry.key]
		end
	end

	return nil, nil :: any
end
