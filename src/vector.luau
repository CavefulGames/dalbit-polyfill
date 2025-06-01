type vector = {
	x: number,
	y: number,
	z: number,
} & number

local math = require("./math")
local abs = math.abs
local atan2 = math.atan2
local ceil = math.ceil
local clamp = math.clamp
local floor = math.floor
local sign = math.sign

local function vector_create(x: number, y: number, z: number): vector
	return setmetatable({
		x = x,
		y = y,
		z = z,
	}, {
		__newindex = function(_, key)
			error(`attempt to index vector with '{key}'`)
		end,
		__tostring = function(self)
			return `{self.x}, {self.y}, {self.z}`
		end,
		__add = function(vec1: vector, vec2: vector)
			return vector_create(vec1.x + vec2.x, vec1.y + vec2.y, vec1.z + vec2.z)
		end,
		__sub = function(vec1: vector, vec2: vector)
			return vector_create(vec1.x - vec2.x, vec1.y - vec2.y, vec1.z - vec2.z)
		end,
		__mul = function(vec1: vector, vec2: vector)
			return vector_create(vec1.x * vec2.x, vec1.y * vec2.y, vec1.z * vec2.z)
		end,
		__div = function(vec1: vector, vec2: vector)
			return vector_create(vec1.x / vec2.x, vec1.y / vec2.y, vec1.z / vec2.z)
		end,
	}) :: any
end

local function vector_magnitude(vec: vector)
	return (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5
end

local function vector_normalize(vec: vector)
	local invSqrt = 1 / ((vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5)
	return vector_create(vec.x * invSqrt, vec.y * invSqrt, vec.z * invSqrt)
end

local function vector_cross(vec1: vector, vec2: vector)
	return vector_create(
		vec1.y * vec2.z - vec1.z * vec2.y,
		vec1.z * vec2.x - vec1.x * vec2.z,
		vec1.x * vec2.y - vec1.y * vec2.x
	)
end

local function vector_dot(vec1: vector, vec2: vector)
	return (vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z)
end

local function vector_angle(vec1: vector, vec2: vector, axis: vector?)
	local cross =
		{ vec1.y * vec2.z - vec1.z * vec2.y, vec1.z * vec2.x - vec1.x * vec2.z, vec1.x * vec2.y - vec1.y * vec2.x }

	local sin_vec1 = (cross[1] ^ 2 + cross[2] ^ 2 + cross[3] ^ 2) ^ 0.5
	local cos_vec1 = vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z
	local angle = atan2(sin_vec1, cos_vec1)

	if axis then
		if (cross[1] * axis.x + cross[2] * axis.y + cross[3] * axis.z) < 0 then
			angle = -angle
		end
	end

	return angle
end

local function vector_floor(vec: vector)
	return vector_create(floor(vec.x), floor(vec.y), floor(vec.z))
end

local function vector_ceil(vec: vector)
	return vector_create(ceil(vec.x), ceil(vec.y), ceil(vec.z))
end

local function vector_abs(vec: vector)
	return vector_create(abs(vec.x), abs(vec.y), abs(vec.z))
end

local function vector_sign(vec: vector)
	return vector_create(sign(vec.x), sign(vec.y), sign(vec.z))
end

local function vector_clamp(vec: vector, min: vector, max: vector)
	for k, v in min :: any do
		if not ((v :: number) > (max :: any)[k]) then
			continue
		end
		error(`invalid argument #3 to 'clamp' (max.{k} must be greater than or equal to min.{k})`)
	end

	return vector_create(clamp(vec.x, min.x, max.x), clamp(vec.y, min.y, max.y), clamp(vec.z, min.z, max.z))
end

local function vector_min(vector: vector, ...: vector)
	local result = { vector.x, vector.y, vector.z }
	local args = { ... }

	for i = 1, #args do
		local vec: vector = args[i]
		if vec.x < result[1] then
			result[1] = vec.x
		end
		if vec.y < result[2] then
			result[2] = vec.y
		end
		if vec.z < result[3] then
			result[3] = vec.z
		end
	end

	return vector_create(result[1], result[2], result[3])
end

local function vector_max(vector: vector, ...: vector)
	local result = { vector.x, vector.y, vector.z }
	local args = { ... }

	for i = 1, #args do
		local vec: vector = args[i]
		if vec.x > result[1] then
			result[1] = vec.x
		end
		if vec.y > result[2] then
			result[2] = vec.y
		end
		if vec.z > result[3] then
			result[3] = vec.z
		end
	end

	return vector_create(result[1], result[2], result[3])
end

local vector_zero = vector_create(0, 0, 0)
local vector_one: vector = vector_create(1, 1, 1)

return {
	abs = vector_abs,
	angle = vector_angle,
	ceil = vector_ceil,
	clamp = vector_clamp,
	create = vector_create,
	cross = vector_cross,
	dot = vector_dot,
	floor = vector_floor,
	magnitude = vector_magnitude,
	max = vector_max,
	min = vector_min,
	normalize = vector_normalize,
	sign = vector_sign,

	zero = vector_zero,
	one = vector_one,
}
