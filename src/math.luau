local perlin = require("./perlin")
local expectNumber = require("./expectNumber")

local getmax = math.max
local getmin = math.min
local exp = math.exp
local abs = math.abs
local floor = math.floor
local log = math.log
local log2 = log(2)
local math_atan = math.atan

local function atan(a: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(a, 1, "atan")
	end

	return math_atan(a)
end

local function atan2(a: number, b: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "atan2"
		expectNumber(a, 1, funcName)
		expectNumber(b, 2, funcName)
	end

	return (math_atan :: any)(a, b)
end

local function clamp(v: number, min: number, max: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "clamp"
		expectNumber(v, 1, funcName)
		expectNumber(min, 2, funcName)
		expectNumber(max, 3, funcName)
	end

	if min > max then
		error("max must be greater than or equal to min")
	end

	return getmax(min, getmin(v, max))
end

local function cosh(x: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(x, 1, "cosh")
	end

	if x == 0.0 then
		return 1.0
	end
	if x < 0.0 then
		x = -x
	end
	x = exp(x)
	x = x / 2.0 + 0.5 / x
	return x
end

local function sinh(x: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(x, 1, "sinh")
	end

	if x == 0 then
		return 0.0
	end
	local neg = false
	if x < 0 then
		x = -x
		neg = true
	end
	if x < 1.0 then
		local y = x * x
		x = x
			+ x
				* y
				* (((-0.78966127417357099479e0 * y + -0.16375798202630751372e3) * y + -0.11563521196851768270e5) * y + -0.35181283430177117881e6)
				/ (((0.10000000000000000000e1 * y + -0.27773523119650701667e3) * y + 0.36162723109421836460e5) * y + -0.21108770058106271242e7)
	else
		x = exp(x)
		x = x / 2.0 - 0.5 / x
	end
	if neg then
		x = -x
	end
	return x
end

local function tanh(x: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(x, 1, "tanh")
	end

	if x == 0 then
		return 0.0
	end
	local neg = false
	if x < 0 then
		x = -x
		neg = true
	end
	if x < 0.54930614433405 then
		local y = x * x
		x = x
			+ x
				* y
				* ((-0.96437492777225469787e0 * y + -0.99225929672236083313e2) * y + -0.16134119023996228053e4)
				/ (((0.10000000000000000000e1 * y + 0.11274474380534949335e3) * y + 0.22337720718962312926e4) * y + 0.48402357071988688686e4)
	else
		x = exp(x)
		x = 1.0 - 2.0 / (x * x + 1.0)
	end
	if neg then
		x = -x
	end
	return x
end

local function pow(a: number, b: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "pow"
		expectNumber(a, 1, funcName)
		expectNumber(b, 2, funcName)
	end

	return a ^ b
end

local function frexp(x: number): (number, number)
	if _G.DALBIT_emulate_type_error then
		expectNumber(x, 1, "frexp")
	end

	if x == 0 then
		return 0.0, 0.0
	end
	local e = floor(log(abs(x)) / log2)
	if e > 0 then
		x = x * 2 ^ -e
	else
		x = x / 2 ^ e
	end
	if abs(x) >= 1.0 then
		x, e = x / 2, e + 1
	end
	return x, e
end

local function ldexp(x: number, e: number): number
	if _G.DALBIT_emulate_type_error then
		local funcName = "ldexp"
		expectNumber(x, 1, funcName)
		expectNumber(e, 2, funcName)
	end

	return x * 2 ^ floor(e)
end

local function log10(x: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(x, 1, "log10")
	end

	return log(x, 10)
end

local function round(n: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(n, 1, "round")
	end

	return floor((floor(n * 2) + 1) / 2)
end

local function sign(n: number): number
	if _G.DALBIT_emulate_type_error then
		expectNumber(n, 1, "sign")
	end

	if n > 0 then
		return 1
	elseif n < 0 then
		return -1
	else
		return 0
	end
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local dalbit_math
if _G.DALBIT_test then
	dalbit_math = {
		atan = atan,
		atan2 = math.atan2 or atan2,
		clamp = clamp,
		cosh = cosh,
		sinh = sinh,
		tanh = tanh,
		pow = pow,
		noise = perlin,
		frexp = frexp,
		ldexp = ldexp,
		log10 = log10,
		round = round,
		sign = sign,
		lerp = lerp,
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		ceil = math.ceil,
		cos = math.cos,
		deg = math.deg,
		exp = math.exp,
		floor = math.floor,
		fmod = math.fmod,
		huge = math.huge,
		log = math.log,
		max = math.max,
		min = math.min,
		modf = math.modf,
		pi = math.pi,
		rad = math.rad,
		random = math.random,
		randomseed = math.randomseed,
		sin = math.sin,
		sqrt = math.sqrt,
		tan = math.tan,
	} :: typeof(math)
else
	dalbit_math = {
		atan = math.atan or atan,
		atan2 = math.atan2 or atan2,
		clamp = math.clamp or clamp,
		cosh = math.cosh or cosh,
		sinh = math.sinh or sinh,
		tanh = math.tanh or tanh,
		pow = math.pow or pow,
		noise = math.noise or perlin,
		frexp = math.frexp or frexp,
		ldexp = math.ldexp or ldexp,
		log10 = math.log10 or log10,
		round = math.round or round,
		sign = math.sign or sign,
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		ceil = math.ceil,
		cos = math.cos,
		deg = math.deg,
		exp = math.exp,
		floor = math.floor,
		fmod = math.fmod,
		huge = math.huge,
		log = math.log,
		max = math.max,
		min = math.min,
		modf = math.modf,
		pi = math.pi,
		rad = math.rad,
		random = math.random,
		randomseed = math.randomseed,
		sin = math.sin,
		sqrt = math.sqrt,
		tan = math.tan,
		lerp = (math :: any).lerp or lerp,
	} :: typeof(math)
end

return dalbit_math
