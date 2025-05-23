-- lua port of https://github.com/luau-lang/luau/blob/master/VM/src/lmathlib.cpp

local bit32 = require("./bit32")

local floor = math.floor
local band = bit32.band

-- stylua: ignore
local kPerlinHash = {
	151, 160, 137, 91,  90,  15,  131, 13,  201, 95,  96,  53,  194, 233, 7,   225, 140, 36,  103, 30,  69,  142, 8,   99,  37,  240, 21,  10,  23,
    190, 6,   148, 247, 120, 234, 75,  0,   26,  197, 62,  94,  252, 219, 203, 117, 35,  11,  32,  57,  177, 33,  88,  237, 149, 56,  87,  174, 20,
    125, 136, 171, 168, 68,  175, 74,  165, 71,  134, 139, 48,  27,  166, 77,  146, 158, 231, 83,  111, 229, 122, 60,  211, 133, 230, 220, 105, 92,
    41,  55,  46,  245, 40,  244, 102, 143, 54,  65,  25,  63,  161, 1,   216, 80,  73,  209, 76,  132, 187, 208, 89,  18,  169, 200, 196, 135, 130,
    116, 188, 159, 86,  164, 100, 109, 198, 173, 186, 3,   64,  52,  217, 226, 250, 124, 123, 5,   202, 38,  147, 118, 126, 255, 82,  85,  212, 207,
    206, 59,  227, 47,  16,  58,  17,  182, 189, 28,  42,  223, 183, 170, 213, 119, 248, 152, 2,   44,  154, 163, 70,  221, 153, 101, 155, 167, 43,
    172, 9,   129, 22,  39,  253, 19,  98,  108, 110, 79,  113, 224, 232, 178, 185, 112, 104, 218, 246, 97,  228, 251, 34,  242, 193, 238, 210, 144,
    12,  191, 179, 162, 241, 81,  51,  145, 235, 249, 14,  239, 107, 49,  192, 214, 31,  181, 199, 106, 157, 184, 84,  204, 176, 115, 121, 50,  45,
    127, 4,   150, 254, 138, 236, 205, 93,  222, 114, 67,  29,  24,  72,  243, 141, 128, 195, 78,  66,  215, 61,  156, 180, 151
}

local kPerlinGrad = {
	{ 1, 1, 0 },
	{ -1, 1, 0 },
	{ 1, -1, 0 },
	{ -1, -1, 0 },
	{ 1, 0, 1 },
	{ -1, 0, 1 },
	{ 1, 0, -1 },
	{ -1, 0, -1 },
	{ 0, 1, 1 },
	{ 0, -1, 1 },
	{ 0, 1, -1 },
	{ 0, -1, -1 },
	{ 1, 1, 0 },
	{ 0, -1, 1 },
	{ -1, 1, 0 },
	{ 0, -1, -1 },
}

local function perlin_grad(hash, x, y, z): number
	local g = kPerlinGrad[band(hash, 15) + 1]
	return g[1] * x + g[2] * y + g[3] * z
end

local function perlin_fade(t: number): number
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function perlin_lerp(t: number, a: number, b: number): number
	return a + t * (b - a)
end

return function(x: number, y: number?, z: number?)
	local y = y or 0
	local z = z or 0

	local xflr = floor(x)
	local yflr = floor(y)
	local zflr = floor(z)

	local xi = band(xflr, 255)
	local yi = band(yflr, 255)
	local zi = band(zflr, 255)

	local xf = x - xflr
	local yf = y - yflr
	local zf = z - zflr

	local u = perlin_fade(xf)
	local v = perlin_fade(yf)
	local w = perlin_fade(zf)

	local p = kPerlinHash

	local a = band(p[xi + 1] + yi, 255)
	local aa = band(p[a + 1] + zi, 255)
	local ab = band(p[a + 1 + 1] + zi, 255)

	local b = band(p[xi + 1 + 1] + yi, 255)
	local ba = band(p[b + 1] + zi, 255)
	local bb = band(p[b + 1 + 1] + zi, 255)

	local la = perlin_lerp(u, perlin_grad(p[aa + 1], xf, yf, zf), perlin_grad(p[ba + 1], xf - 1, yf, zf))
	local lb = perlin_lerp(u, perlin_grad(p[ab + 1], xf, yf - 1, zf), perlin_grad(p[bb + 1], xf - 1, yf - 1, zf))
	local la1 =
		perlin_lerp(u, perlin_grad(p[aa + 1 + 1], xf, yf, zf - 1), perlin_grad(p[ba + 1 + 1], xf - 1, yf, zf - 1))
	local lb1 = perlin_lerp(
		u,
		perlin_grad(p[ab + 1 + 1], xf, yf - 1, zf - 1),
		perlin_grad(p[bb + 1 + 1], xf - 1, yf - 1, zf - 1)
	)

	return perlin_lerp(w, perlin_lerp(v, la, lb), perlin_lerp(v, la1, lb1))
end
