local frktest = require("@frktest/")
local test = frktest.test
local check = frktest.assert.check
local utils = require("./utils")

return function()
	test.suite("bit32", function()
		test.case("bitwise operations", function()
			check.table.equal(utils.execute([[
			return {
				bit32.band(1, 3, 7),
				bit32.band(-1, -3, -7),
				bit32.band(0.1, 0.3, 0.7)
			}
			]]))

			check.table.equal(utils.execute([[
			return {
				bit32.bor(1, 2, 4),
				bit32.bor(0xF0, 0x0F),
				bit32.bor(-1, -2, -4),
				bit32.bor(0.1, 0.2, 0.4)
			}
			]]))

			check.table.equal(utils.execute([[
			return {
				bit32.bxor(1, 2, 3),
				bit32.bxor(0xFF, 0xAA),
				bit32.bxor(-1, -2, -3),
				bit32.bxor(0.1, 0.2, 0.3)
			}
			]]))

			check.table.equal(utils.execute([[
			return {
				bit32.lshift(1, 3),
				bit32.lshift(0x01, 8),
				bit32.lshift(-1, -3),
				bit32.lshift(0.1, 0.3)
			}
			]]))

			check.table.equal(utils.execute([[
			return {
				bit32.rshift(16, 2),
				bit32.rshift(0x100, 8),
				bit32.rshift(-16, -2),
				bit32.rshift(0.16, 0.2)
			}
			]]))

			check.table.equal(utils.execute([[
			return {
				bit32.bnot(0),
				bit32.bnot(0xFFFFFFFF),
				bit32.bnot(-5),
				bit32.bnot(0.5)
			}
			]]))
		end)

		test.case("arshift", function()
			check.equal(utils.execute([[

			return bit32.arshift(0b1111, 2)

			]]))

			check.equal(utils.execute([[

			return bit32.arshift(-4, 1)

			]]))

			check.equal(utils.execute([[

			return bit32.arshift(0xFF, 32)

			]]))
		end)

		test.case("extract", function()
			check.equal(utils.execute([[

			return bit32.extract(0x1234, 4, 4)

			]]))

			check.equal(utils.execute([[

			return bit32.extract(0xFFFF, 8, 8)

			]]))
		end)

		test.case("rrotate", function()
			check.equal(utils.execute([[

			return bit32.rrotate(0x12345678, 4)

			]]))

			check.equal(utils.execute([[

			return bit32.rrotate(0x80000000, 1)

			]]))
		end)

		test.case("lrotate", function()
			check.equal(utils.execute([[

			return bit32.lrotate(0x12345678, 4)

			]]))

			check.equal(utils.execute([[

			return bit32.lrotate(0x80000000, 1)

			]]))
		end)

		test.case("replace", function()
			check.equal(utils.execute([[

			return bit32.replace(0x1234, 0x5, 4, 4)

			]]))

			check.equal(utils.execute([[

			return bit32.replace(0xFFFF, 0x0, 8, 8)

			]]))
		end)

		test.case("countz", function()
			check.equal(utils.execute([[

			return bit32.countrz(32)

			]]))

			check.equal(utils.execute([[

			return bit32.countlz(32)

			]]))
		end)
	end)

	test.suite("buffer", function()
		test.case("integers", function()
			check.table.equal(utils.execute([[

			local offset = 0
			local b = buffer.create(14)

			-- writing unsigned
			buffer.writeu8(b, offset, 2^8-1)
			offset += 1

			buffer.writeu16(b, offset, 2^16-1)
			offset += 2

			buffer.writeu32(b, offset, 2^32-1)
			offset += 4

			-- writing signed
			buffer.writei8(b, offset, 2^7-1)
			offset += 1

			buffer.writei16(b, offset, 2^15-1)
			offset += 2

			buffer.writei32(b, offset, 2^31-1)
			offset += 4

			-- reading unsigned
			local read = {}
			offset = 0

			table.insert(read, buffer.readu8(b, offset))
			offset += 1

			table.insert(read, buffer.readu16(b, offset))
			offset += 2

			table.insert(read, buffer.readu32(b, offset))
			offset += 4

			-- reading signed
			table.insert(read, buffer.readi8(b, offset))
			offset += 1

			table.insert(read, buffer.readi16(b, offset))
			offset += 2

			table.insert(read, buffer.readi32(b, offset))
			offset += 4

			return { buffer.tostring(b), table.concat(read, ",") }

			]]))
		end)

		test.case("floats", function()
			check.table.equal(utils.execute([[

			-- writing
			local offset = 0
			local b = buffer.create(12 * 3)

			buffer.writef32(b, offset, 1234.56789)
			offset += 4

			buffer.writef64(b, offset, 1234.56789)
			offset += 8

			buffer.writef32(b, offset, math.huge)
			offset += 4

			buffer.writef64(b, offset, math.huge)
			offset += 8

			buffer.writef32(b, offset, 0)
			offset += 4

			buffer.writef64(b, offset, 0)
			offset += 8

			-- reading
			local read = {}
			offset = 0

			table.insert(read, buffer.readf32(b, offset))
			offset += 4

			table.insert(read, buffer.readf64(b, offset))
			offset += 8

			table.insert(read, buffer.readf32(b, offset))
			offset += 4

			table.insert(read, buffer.readf64(b, offset))
			offset += 8

			table.insert(read, buffer.readf32(b, offset))
			offset += 4

			table.insert(read, buffer.readf64(b, offset))
			offset += 8

			return { buffer.tostring(b), table.concat(read, ",") }

			]]))
		end)

		test.case("strings", function()
			check.table.equal(utils.execute([[

			-- writing
			local offset = 0
			local msg = "hello"
			local char = "A"
			local b = buffer.create(#msg + 4 + 1)

			buffer.writeu32(b, offset, 12345678) -- just a test
			offset += 4

			buffer.writestring(b, offset, msg)
			offset += #msg

			buffer.writestring(b, offset, char, 1)
			offset += 1

			-- reading
			local read = {}
			offset = 0

			table.insert(read, buffer.readu32(b, offset))
			offset += 4

			table.insert(read, buffer.readstring(b, offset, #msg))
			offset += #msg

			table.insert(read, buffer.readstring(b, offset, 1))
			offset += 1

			return {buffer.tostring(b), table.concat(read, ",")}

			]]))
		end)

		test.case("fill", function()
			check.equal(utils.execute([[

			local b = buffer.create(4)

			buffer.fill(b, 0, 255, 4)

			return buffer.tostring(b)

			]]))
		end)

		test.case("copy", function()
			check.equal(utils.execute([[

			local b = buffer.create(4)
			local source = buffer.create(4)

			buffer.writeu32(source, 0, 12345678)
			buffer.copy(b, 0, source, 0, 4)

			return buffer.tostring(b)

			]]))
		end)

		test.case("len", function()
			check.equal(utils.execute([[

			return buffer.len(buffer.create(5))

			]]))
		end)

		test.case("fromstring", function()
			check.equal(utils.execute([[

			local b = buffer.fromstring("abcd")

			local read = {}

			table.insert(read, buffer.readu32(b, 0))
			table.insert(read, buffer.readi32(b, 0))
			table.insert(read, buffer.readf32(b, 0))

			return table.concat(read, ",")

			]]))
		end)
	end)

	test.suite("global functions", function()
		test.case("types", function()
			check.table.equal(utils.execute([[

			local types = {}
			local b = buffer.create(1)

			table.insert(types, type(b))
			table.insert(types, typeof(b))
			table.insert(types, type(true))
			table.insert(types, typeof(false))
			table.insert(types, type(1))
			table.insert(types, typeof(2))
			table.insert(types, type("a"))
			table.insert(types, typeof("ABCD"))
			table.insert(types, type({}))
			table.insert(types, typeof({}))
			table.insert(types, type(newproxy()))
			table.insert(types, typeof(newproxy()))
			table.insert(types, type(type))
			table.insert(types, typeof(function() end))
			table.insert(types, type(table.freeze({})))
			table.insert(types, typeof(table.freeze({1})))

			return types

			]]))
		end)

		test.case("rawset/get", function()
			check.equal(utils.execute([[
			local t = setmetatable({}, {
				__newindex = function()
					return "this is newindex"
				end,
				__index = function()
					return "this is index"
				end
			})

			rawset(t, "key", "value")
			return rawget(t, "key")

			]]))
		end)

		test.case("calling next with invalid table", function()
			check.table.equal(utils.execute([[
			return {pcall(next, newproxy())}
			]]))
		end)

		test.case("emulating newproxy/userdata", function()
			check.table.equal(utils.execute([[
			return {
				{pcall(function()
					newproxy().key = true
				end)},
				{pcall(function()
					return newproxy(true).key
				end)},
				{pcall(function()
					return newproxy(false) < newproxy(true)
				end)},
				{pcall(function()
					return newproxy() + 5
				end)},
			}
			]]))
		end)

		test.case("iterators", function()
			check.table.equal(utils.execute([[

			local t = {}
			local hashTable = {
				apple = 55,
				banana = 111,
				peach = 123,
				grape = 255
			}

			for _ = 1, 100 do
				local i = 0
				for _, v in pairs(hashTable) do
					i += 1
					t[i] = v
				end

				i = 0
				for _, v in pairs(hashTable) do
					i += 1
					t[i] -= v
				end
			end

			return t

			]]))
		end)

		test.case("version", function()
			check.equal(utils.executeWithLuau([[

			return _VERSION

			]]))
		end)

		test.case("newproxy with metatable", function()
			check.table.equal(utils.execute([[

			local ud = newproxy(true)
			local mt = getmetatable(ud)

			mt.__tostring = function()
				return "hellooo"
			end

			mt.__len = function()
				return 1000
			end

			return {tostring(ud), #ud}

			]]))
		end)
	end)

	test.suite("math", function()
		test.case("atan", function()
			check.equal(utils.execute([[
			return math.atan(123)
			]]))

			check.equal(utils.execute([[
			return math.atan(1/3)
			]]))
		end)

		test.case("atan2", function()
			check.equal(utils.execute([[
			return math.atan2(1, 2)
			]]))

			check.equal(utils.execute([[
			return math.atan2(6, 9)
			]]))
		end)

		test.case("clamp", function()
			check.equal(utils.execute([[
			return math.clamp(5, -1, 3)
			]]))

			check.equal(utils.execute([[
			return math.clamp(-5, -1, 10)
			]]))
		end)

		test.case("cosh", function()
			check.equal(utils.execute([[
			return math.cosh(123)
			]]))

			check.equal(utils.execute([[
			return math.cosh(math.rad(30))
			]]))
		end)

		test.case("sinh", function()
			check.equal(utils.execute([[
			return math.sinh(123)
			]]))

			check.equal(utils.execute([[
			return math.sinh(math.rad(30))
			]]))
		end)

		test.case("tanh", function()
			check.equal(utils.execute([[
			return math.tanh(123)
			]]))

			check.equal(utils.execute([[
			return math.tanh(math.rad(90))
			]]))
		end)

		test.case("pow", function()
			check.equal(utils.execute([[
			return math.pow(2, 8)
			]]))

			check.equal(utils.execute([[
			return math.pow(2, -16)
			]]))
		end)

		test.case("frexp", function()
			check.table.equal(utils.execute([[
			return { math.frexp(1.234) }
			]]))

			check.table.equal(utils.execute([[
			return { math.frexp(33) }
			]]))
		end)

		test.case("ldexp", function()
			check.table.equal(utils.execute([[
			return { math.ldexp(1.234, 1.234) }
			]]))

			check.table.equal(utils.execute([[
			return { math.ldexp(33, 12) }
			]]))
		end)

		test.case("log10", function()
			check.equal(utils.execute([[
			return math.log10(10)
			]]))

			check.equal(utils.execute([[
			return math.log10(2)
			]]))
		end)

		test.case("round", function()
			check.equal(utils.execute([[
			return math.round(0.5)
			]]))

			check.equal(utils.execute([[
			return math.round(0.54321)
			]]))

			check.equal(utils.execute([[
			return math.round(0.1)
			]]))

			check.equal(utils.execute([[
			return math.round(0.9)
			]]))
		end)

		test.case("sign", function()
			check.equal(utils.execute([[
			return math.sign(-123)
			]]))

			check.equal(utils.execute([[
			return math.sign(123)
			]]))
		end)

		test.case("noise(perlin)", function()
			check.equal(utils.execute([[
			return math.noise(1.5)
			]]))

			check.equal(utils.execute([[
			return math.noise(1.5, 2.5)
			]]))

			check.equal(utils.execute([[
			return math.noise(1.5, 2.5, 3.5)
			]]))
		end)
	end)

	test.suite("string", function()
		test.case("split method", function()
			check.table.equal(utils.execute([[
			return ("a,bc,def"):split(",")
			]]))
		end)

		test.case("split", function()
			check.table.equal(utils.execute([[
			return {
				unpack(string.split("apple;banana", ";")),
				unpack(string.split(";apple;banana;", ";")),
				unpack(string.split("apple;banana;", ".")),
			}
			]]))
		end)
	end)

	test.suite("table", function()
		test.case("create and clear", function()
			check.equal(utils.execute([[

			local t = table.create(math.random(20, 50), "A")

			table.clear(t)

			return #t

			]]))
		end)

		test.case("clone", function()
			check.table.equal(utils.execute([[

			local checks = {}

			local fruits = {"banana", "apple", "peach", "grape"}

			table.insert(checks, table.clone(fruits))

			local readOnly = setmetatable({}, {
				__newindex = function()
					error("this is read-only!")
				end
			})

			table.insert(checks, {pcall(function()
				local newReadOnly = table.clone(readOnly)

				newReadOnly.key = "value"
			end)})

			return checks

			]]))
		end)

		test.case("find", function()
			check.equal(utils.execute([[

			local t = {"A", "AA", "AAA", "S", "SS", "SS", "SS", "SS", "BB", "BB", "C"}

			return table.find(t, "SS")

			]]))
		end)

		test.case("foreach", function()
			check.table.equal(utils.execute([[

			local sum = 0
			table.foreach({ a = 1, b = 2, c = 3, d = 4 }, function(k, v)
				sum = sum + v
			end)

			local msg = ""
			local doubleLastIndex = 0
			table.foreachi({ "A", "PP", "L", "E" }, function(i, v)
				msg = msg .. v
				doubleLastIndex = i * 2
			end)

			return { sum, msg, doubleLastIndex }

			]]))
		end)

		test.case("freeze", function()
			check.equal(utils.execute([[

			local readonly = table.freeze({
				key = "oldValue"
			})

			return pcall(function()
				readonly.key = "newValue"
			end)

			]]))
		end)

		test.case("getn maxn", function()
			check.table.equal(utils.execute([[

			return {
				table.getn({1, 2, 3, 4}),
				table.maxn({"apple", "banana", "grape"})
			}

			]]))
		end)
	end)

	test.suite("debug", function()
		test.case("traceback_thread", function()
			check.equal(utils.execute([[

			return debug.traceback((function()
				local co = coroutine.create(function()
					coroutine.yield()
				end)
				coroutine.resume(co)
				return co
			end)(), 'apple', 2)

			]]))
		end)

		test.case("traceback_msg", function()
			check.equal(utils.execute([[

			local t
			return (function()
				local co = coroutine.create(function()
					t = debug.traceback('apple', 2)
					coroutine.yield()
				end)
				coroutine.resume(co)
				return t
			end)()

			]]))
		end)

		test.case("info_thread", function()
			check.equal(utils.execute([[

			local function getInfo()
				local t = {}
				for i=1, 6 do
					t[#t + 1] = debug.info((function()
						local co = coroutine.create(function()
							coroutine.yield()
						end)
						coroutine.resume(co)
						return co
					end)(), i - 1, 'slnf')
				end
				return t
			end

			return table.unpack(getInfo())

			]]))
		end)

		test.case("info_function", function()
			check.equal(utils.execute([[

			local function x(num)
				return num * 2
			end

			local function getInfo()
				debug.info(x, 'slnf')
			end

			return getInfo()

			]]))
		end)

		test.case("info_number", function()
			check.equal(utils.execute([[

			local function getInfo()
				local t = {}
				for i=1, 6 do
					t[#t + 1] = debug.info(i - 1, 'slnf')
				end
				return t
			end

			return table.unpack(getInfo())

			]]))
		end)
	end)

	test.suite("utf8", function()
		test.case("offset", function()
			check.equal(utils.execute([[

			return utf8.offset('한', 0, 1)

			]]))
		end)

		test.case("codepoint", function()
			check.equal(utils.execute([[

			return utf8.codepoint('뷁둙', 1, 4)

			]]))
		end)

		test.case("char", function()
			check.equal(utils.execute([[

			return utf8.char(65, 5000, 67)

			]]))
		end)

		test.case("len", function()
			check.equal(utils.execute([[

			return utf8.len('한글')

			]]))
		end)

		test.case("codes", function()
			check.equal(utils.execute([[

			local posResult = 0
			local codeResult = 0

			for pos, code in utf8.codes("안녕하세요") do
				posResult = posResult + pos
				codeResult = codeResult + code
			end

			return posResult, codeResult

			]]))
		end)
	end)

	test.suite("vector", function() 
		test.case("magnitude", function()
			check.equal(utils.executeWithLuau([[

			return string.sub(vector.magnitude(vector.create(10, 5, 5)), 1, 2)

			]]))
		end)

		test.case("normalize", function()
			check.equal(utils.executeWithLuau([[

			return tostring(math.round(vector.normalize(vector.create(10, 5, 5)).x))

			]]))
		end)

		test.case("cross", function()
			check.equal(utils.executeWithLuau([[

			return tostring(vector.cross(vector.create(10, 5, 5), vector.create(5, 5, 10)).x)

			]]))
		end)

		test.case("dot", function()
			check.equal(utils.executeWithLuau([[

			return tostring(vector.dot(vector.create(10, 5, 5), vector.create(5, 5, 10)))

			]]))
		end)

		test.case("angle", function()
			check.equal(utils.executeWithLuau([[

			return tostring(math.round(vector.angle(vector.create(10, 5, 5), vector.create(5, 5, 10), vector.create(10, 5, 5))))

			]]))
		end)

		test.case("floor", function()
			check.equal(utils.executeWithLuau([[

			return tostring(vector.floor(vector.create(10.123, 20.234, 30.345)).x)

			]]))
		end)
		
		test.case("ceil", function()
			check.equal(utils.executeWithLuau([[

			return tostring(vector.ceil(vector.create(10.01, 20.222, 30.0001)).x)

			]]))
		end)

		test.case("abs", function()
			check.equal(utils.executeWithLuau([[

			return tostring(math.round(vector.abs(vector.create(-10.01, 20.222, -30.0001)).x))

			]]))
		end)

		test.case("sign", function()
			check.equal(utils.executeWithLuau([[

			return tostring(vector.sign(vector.create(-10, 20, -30)).x)

			]]))
		end)

		test.case("min", function()
			check.equal(utils.executeWithLuau([[

			return tostring(vector.min(vector.create(100, 100, 100), vector.create(1, 100, 100), vector.create(100, 2, 100), vector.create(100, 100, 3), vector.one).x)

			]]))
		end)
		
		test.case("max", function()
			check.equal(utils.executeWithLuau([[

			return tostring(vector.max(vector.create(-100, -100, -100), vector.create(1, 100, 100), vector.create(100, 2, 100), vector.create(100, 100, 3), vector.one).x)
			
			]]))
		end)
	end)
end
