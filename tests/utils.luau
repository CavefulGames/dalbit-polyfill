local utils = {}
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")

local function pcallWithoutTrace(fn, ...)
	return xpcall(fn, function(err)
		return err:gsub("^[^:]+:%d+: ", "")
	end, ...)
end

local polyfill: { config: { [string]: boolean } } = serde.decode("toml", fs.readFile("polyfill.toml"))
for k, v in polyfill.config do
	_G["DALBIT_" .. k] = v
end
_G.DALBIT_test = true
local globals = require("../src/globals")
;(globals :: any).pcall = pcallWithoutTrace
;(globals :: any)._G = _G

function utils.executePolyfill(code: string)
	return luau.load(code, {
		debugName = "polyfill execution",
		environment = globals,
		injectGlobals = true
	})()
end

function utils.execute(code: string): (any, any)
	local luauResult = luau.load(code, {
		debugName = "luau execution",
		environment = {
			pcall = pcallWithoutTrace,
			_VERSION = "Luau",
		}
	})()
	local polyfillResult = utils.executePolyfill(code)

	return luauResult, polyfillResult
end

--[=[
	Return types must be a string.
]=]
function utils.executeWithLuau(code: string): (string, string)
	local luauResult = process.spawn("luau", nil, { stdin = [[pcall = function(fn, ...) return xpcall(fn, function(err) return err:gsub("^[^:]+:%d+: ", "") end, ...)  end;]] .. code })
	if luauResult.ok then
		if luauResult.stdout:sub(-2) == '\r\n' then
			return luauResult.stdout:sub(1, -3), utils.executePolyfill(code)
		end
		return luauResult.stdout:sub(1, -2), utils.executePolyfill(code)
	else
		error(`Luau failure:\nerr: {luauResult.stderr}\nstdout: {luauResult.stdout}`)
	end
end

return utils
