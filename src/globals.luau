local nativeTypes = require("./nativeTypes")
local weakTypes = require("./weakTypes")
local frozenTables = require("./frozenTables")
local privateKey = require("./privateKey")
local proxies = require("./proxies")
local lockedTables = require("./lockedTables")
local isNumber = require("./isNumber")
local expectString = require("./expectString")
local typeof = require("./typeof")
local type = require("./type")
local isString = require("./isString")
local expectTable = require("./expectTable")
local dalbit_next = require("./next")

local function dalbit_rawget(t: {}, k: any): any
	if _G.DALBIT_runtime_type_checking then
		expectTable(t, "table", 1, "rawget")
	end
	if _G.DALBIT_emulate_type_error then
		if k == nil then
			error("missing argument #2")
		end
	end

	if proxies[t] then
		return t[k]
	end
	return rawget(t, k)
end

local function dalbit_rawset(t: {}, k: any, v: any): ()
	if _G.DALBIT_runtime_type_checking then
		expectTable(t, "table", 1, "rawset")
	end
	if _G.DALBIT_emulate_type_error then
		if k == nil then
			error("missing argument #2")
		elseif v == nil then
			error("missing argument #3")
		end
	end

	if proxies[t] then
		t[k] = v
	else
		rawset(t, k, v)
	end
end



local dalbit_ipairs: typeof(ipairs)
if _G.DALBIT_emulate_frozen_table or _G.DALBIT_runtime_type_checking then
	dalbit_ipairs = function<V>(t: { V }): (({ V }, number) -> (number?, V), { V }, number)
		if _G.DALBIT_runtime_type_checking then
			expectTable(t, "table", 1, "ipairs")
		end

		if _G.DALBIT_emulate_frozen_table then
			local frozen = frozenTables[t]
			if frozen then
				t = frozen[privateKey]
			end
		end

		return ipairs(t)
	end
else
	dalbit_ipairs = ipairs
end

local proxyMetatables = {}
local dalbit_getmetatable
if _G.DALBIT_emulate_frozen_table and _G.DALBIT_emulate_newproxy then
	dalbit_getmetatable = function(value: any): any
		if _G.DALBIT_emulate_type_error then
			if value == nil then
				error("missing argument #1")
			end
		end

		local frozen = frozenTables[value]
		if frozen then
			return frozen[1]
		end
		local mt = proxies[value] or getmetatable(value)
		if nativeTypes[mt] or proxyMetatables[value] then
			return nil
		end
		return mt
	end
elseif _G.DALBIT_emulate_frozen_table then
	dalbit_getmetatable = function(value: any): any
		if _G.DALBIT_emulate_type_error then
			if value == nil then
				error("missing argument #1")
			end
		end

		local frozen = frozenTables[value]
		if frozen then
			return frozen[1]
		end
		return getmetatable(value)
	end
elseif _G.DALBIT_emulate_newproxy then
	dalbit_getmetatable = function(value: any): any
		if _G.DALBIT_emulate_type_error then
			if value == nil then
				error("missing argument #1")
			end
		end

		local mt = proxies[value] or getmetatable(value)
		if nativeTypes[mt] or proxyMetatables[value] then
			return nil
		end
		return getmetatable(value)
	end
else
	dalbit_getmetatable = function(value: any): any
		if _G.DALBIT_emulate_type_error then
			if value == nil then
				error("missing argument #1")
			end
		end

		local mt = getmetatable(value)
		if nativeTypes[mt] then
			return nil
		end
		return mt
	end
end

-- a SPECIAL global function for __iter
local function __DALBIT_getmetatable_iter(value)
	if _G.DALBIT_emulate_type_error then
		if value == nil then
			error("missing argument #1")
		end
	end

	local iterMethod = lockedTables[value]
	if iterMethod then
		return {
			__iter = iterMethod,
		}
	end
	return dalbit_getmetatable(value)
end

local function dalbit_setmetatable(tbl: {}, mt: { [any]: any } | nil)
	if _G.DALBIT_runtime_type_checking then
		local funcName = "setmetatable"
		expectTable(tbl, "table", 1, funcName)
		if mt ~= nil and typeof(mt) ~= "table" then
			error(`invalid argument #2 to '{funcName}' (nil or table expected, got {typeof(mt)})`)
		end
	end

	if mt and mt.__metatable then
		local iterMethod = mt.__iter
		if iterMethod then
			lockedTables[tbl] = iterMethod
		else
			lockedTables[tbl] = false
		end
	end
	return setmetatable(tbl, mt)
end

local Proxy = {}

function Proxy.__newindex(self, k, v)
	self[privateKey][k] = v
	rawset(self, k, v)
end

local userdata = {}

function userdata.__index(self, k)
	error(`attempt to index {typeof(self)} with '{k}'`)
end

function userdata.__newindex(self, k)
	error(`attempt to index {typeof(self)} with '{k}'`)
end

function userdata.__len(self)
	error(`attempt to get length of a {typeof(self)} value`)
end

function userdata.__call(self)
	error(`attempt to call a {typeof(self)} value`)
end

local function arithmeticError(metamethod, a, b)
	local aType = typeof(a)
	local bType = typeof(b)
	if aType == bType then
		error(`attempt to perform arithmetic ({metamethod}) on {aType}`)
	else
		error(`attempt to perform arithmetic ({metamethod}) on {aType} and {bType}`)
	end
end

function userdata.__add(a, b)
	arithmeticError("add", a, b)
end

function userdata.__sub(a, b)
	arithmeticError("sub", a, b)
end

function userdata.__mul(a, b)
	arithmeticError("mul", a, b)
end

function userdata.__div(a, b)
	arithmeticError("div", a, b)
end

function userdata.__unm(a, b)
	arithmeticError("unm", a, b)
end

function userdata.__mod(a, b)
	arithmeticError("mod", a, b)
end

function userdata.__pow(a, b)
	arithmeticError("pow", a, b)
end

function userdata.__idiv(a, b)
	arithmeticError("idiv", a, b)
end

function userdata.__lt(a, b)
	error(`attempt to compare {typeof(a)} < {typeof(b)}`)
end

function userdata.__le(a, b)
	error(`attempt to compare {typeof(a)} <= {typeof(b)}`)
end

function userdata.__concat(a, b)
	error(`attempt to concatenate {typeof(a)} with {typeof(b)}`)
end

function userdata.__tostring(self)
	local mt = getmetatable(self)
	setmetatable(self :: any, nil)
	local display = "userdata: " .. tostring(self):sub(8)
	setmetatable(self :: any, mt)
	return display
	-- setmetatable(self :: any, nil)
	-- local display = "userdata: " .. tostring(self):sub(8)
	-- setmetatable(self :: any, userdata)
	-- return display
end

function userdata.__iter(self)
	error(`attempt to iterate over a {typeof(self)} value`)
end

nativeTypes[userdata] = "userdata"

local dalbit_newproxy
if _G.DALBIT_emulate_newproxy then
	dalbit_newproxy = function(mt: boolean?)
		if _G.DALBIT_emulate_type_error then
			if mt ~= nil and type(mt) ~= "boolean" then
				error(`invalid argument #1 to 'newproxy' (nil or boolean expected, got {typeof(mt)})`)
			end
		end

		local newud = {}
		if mt then
			-- selene: allow(manual_table_clone)
			local proxyMt = {}
			for i, v in next, userdata do
				proxyMt[i] = v
			end
			setmetatable(newud, proxyMt)
			local p = {
				__newindex = function(self, k, v)
					proxyMt[k] = v
					rawset(self, k, v)
				end,
			}
			local pt = setmetatable({}, p)
			proxies[newud] = pt
			proxyMetatables[pt] = p
			weakTypes[newud] = "userdata"
		else
			setmetatable(newud, userdata)
		end
		return newud
	end
else
	dalbit_newproxy = function(mt: boolean?)
		if _G.DALBIT_emulate_type_error then
			if mt ~= nil and type(mt) ~= "boolean" then
				error(`invalid argument #1 to 'newproxy' (nil or boolean expected, got {typeof(mt)})`)
			end
		end

		local newud = {}
		if mt then
			setmetatable(newud, {})
			weakTypes[newud] = "userdata"
		else
			setmetatable(newud, userdata)
		end
		return newud
	end
end

local dalbit_gcinfo = gcinfo
if not dalbit_gcinfo then
	dalbit_gcinfo = function(): number
		return collectgarbage("count")
	end
end

local dalbit_setfenv = setfenv
if not dalbit_setfenv then
	dalbit_setfenv = function<T..., R...>(fnOrIndex: (T...) -> R... | number, env): ((T...) -> R...)?
		fnOrIndex = fnOrIndex or 1
		if isNumber(fnOrIndex) then
			local info = (debug :: any).getinfo(fnOrIndex) :: {
				func: (T...) -> R...,
				what: string,
			}
			if info.what == "C" then
				error("invalid argument #1 to 'getfenv' (invalid level)")
			end
			fnOrIndex = info.func
		elseif type(fnOrIndex) ~= "function" then
			error(`invalid argument #1 to 'setfenv' (function expected, got {typeof(fnOrIndex)})`)
		end
		local i = 1
		while true do
			local name = (debug :: any).getupvalue(fnOrIndex, i)
			if name == "_ENV" then
				(debug :: any).upvaluejoin(fnOrIndex, i, function()
					return env
				end, 1)
				break
			elseif not name then
				break
			end
			i = i + 1
		end
		return fnOrIndex :: any -- idk
	end
end

local dalbit_getfenv = getfenv
if not dalbit_getfenv then
	dalbit_getfenv = function(fnOrIndex: (() -> () | number)?)
		fnOrIndex = fnOrIndex or 1
		if isNumber(fnOrIndex) then
			local info = (debug :: any).getinfo(fnOrIndex) :: {
				func: () -> (),
				what: string,
			}
			if info.what == "C" then
				error("invalid argument #1 to 'getfenv' (invalid level)")
			end
			fnOrIndex = info.func
		elseif type(fnOrIndex) ~= "function" then
			error(`invalid argument #1 to 'getfenv' (function expected, got {typeof(fnOrIndex)})`)
		end
		local i = 1
		while true do
			local name, val = (debug :: any).getupvalue(fnOrIndex, i)
			if name == "_ENV" then
				return val
			elseif not name then
				break
			end
			i = i + 1
		end
		return {} -- idk
	end
end

local dalbit_loadstring = loadstring
if not dalbit_loadstring then
	dalbit_loadstring = function<A...>(contents: string, chunkname: string?): (((A...) -> any)?, string?)
		if _G.DALBIT_runtime_type_checking then
			local funcName = "loadstring"
			expectString(contents, 1, funcName)
			if chunkname ~= nil and not isString(chunkname) then
				error(`invalid argument #2 to '{funcName}' (string expected, got {typeof(chunkname)})`)
			end
		end

		-- selene: allow(incorrect_standard_library_use)
		return load(contents, chunkname, "t")
	end
end

return {
	-- globals
	type = type :: typeof(type),
	typeof = typeof :: typeof(typeof),
	rawget = dalbit_rawget :: typeof(rawget),
	rawset = dalbit_rawset :: typeof(rawset),
	next = dalbit_next :: typeof(next),
	unpack = (unpack or table.unpack) :: typeof(unpack),
	pairs = function(tbl)
		return dalbit_next, tbl, nil
	end :: typeof(pairs),
	ipairs = dalbit_ipairs :: typeof(ipairs),
	getmetatable = dalbit_getmetatable :: typeof(getmetatable),
	__DALBIT_getmetatable_iter = __DALBIT_getmetatable_iter :: typeof(getmetatable),
	setmetatable = dalbit_setmetatable :: typeof(setmetatable),
	newproxy = dalbit_newproxy :: typeof(newproxy),
	gcinfo = dalbit_gcinfo :: typeof(gcinfo),
	setfenv = dalbit_setfenv :: typeof(setfenv),
	getfenv = dalbit_getfenv :: typeof(getfenv),
	_VERSION = "Luau",
	loadstring = dalbit_loadstring :: typeof(loadstring),

	-- libraries
	bit32 = require("./bit32"),
	buffer = require("./buffer"),
	debug = require("./debug"),
	math = require("./math"),
	os = require("./os"),
	string = require("./string"),
	table = require("./table"),
	vector = require("./vector"),
}
