-- integer numbers
local int = {
	positive = {
		[0] = {
			{ actual = 0 },
		},
		{
			{ actual = 1 },
		},
		{
			{ actual = 2 },
			{ actual = 3 },
		},
	},
	negative = {
		{
			{ actual = -1 },
		},
		{
			{ actual = -2 },
		},
		{
			{ actual = -3 },
			{ actual = -4 },
		},
	},
}
do
	local function findlast(list, index)
		for i = index-1, 1, -1 do
			if list[i] ~= nil then
				return i
			end
		end
	end
	local function addints(length, isauto)
		local min
		if not isauto and int.positive[length-1] == nil then
			min = length-1
			addints(min, true)
		else
			min = findlast(int.positive, length)
		end
		min = 1 << min
		local max = ~(-1 << length)
		if min >= 0 then
			int.positive[length] = {
				{ actual = min },
				{ actual = min + 1 },
				{ actual = max - 1 },
				{ actual = max },
			}
		end
		if not isauto then
			local pos = int.positive[length-1]
			local neg = int.negative[findlast(int.negative, length)]
			pos = pos[#pos].actual
			neg = neg==nil and 0 or neg[#neg].actual
			int.negative[length] = {
				{ actual = neg - 1  },
				{ actual = neg - 2  },
				{ actual = -pos },
				{ actual = -pos - 1 },
			}
		end
	end
	addints(4)
	addints(7)
	addints(8)
	addints(16)
	addints(24)
	addints(32)
	addints(53)
	addints(64)
end

-- floating-point numbers
local float = {
	positive = { tiny = {}, huge = {}, other = {} },
	negative = { tiny = {}, huge = {}, other = {} },
}
do
	float.positive.other[32] = {
		{ actual = math.huge },
	}
	float.positive.other[64] = {
		{ actual = math.pi },
	}
	for length, cases in pairs(float.positive.other) do
		local negs = {}
		for index, case in ipairs(cases) do
			negs[index] = { actual = -case.actual }
		end
		float.negative.other[length] = negs
	end
	local function newcases(sig, exp, bits)
		local list = {}
		for index, case in ipairs(int.positive[bits]) do
			local base = case.actual
			list[index] = {
				id = string.format("%s0x%xE%d", sig>0 and "" or "-", base, exp),
				actual = sig * base * 2^exp,
			}
		end
		return list
	end
	local function addfloats(sig, exp)
		local length = sig+exp
		exp = 1 << (exp-1)
		local emin = 1-(exp-2)-sig
		local emax = exp-1-sig
		float.positive.tiny[length] = newcases( 1, emin, sig)
		float.positive.huge[length] = newcases( 1, emax, sig)
		float.negative.tiny[length] = newcases(-1, emin, sig)
		float.negative.huge[length] = newcases(-1, emax, sig)
	end
	addfloats(24, 8)
	addfloats(53, 11)
end

-- non-numeric values
local nonnumber = {
	{ actual = nil },
	{ actual = false },
	{ actual = true },
	{ actual = "text" },
	{ actual = {} },
	{ actual = print },
	{ actual = function () end },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
}



local function collect(res, group, lower, upper)
	if type(next(group)) ~= "number" then
		for _, cases in pairs(group) do
			collect(res, cases, lower, upper)
		end
	else
		for bits = 1+(lower or -1), upper or 128 do
			local cases = group[bits]
			if cases ~= nil then
				for _, case in ipairs(cases) do
					res[#res+1] = case
				end
			end
		end
	end
end

local function numbers(...)
	local res = {}
	collect(res, ...)
	return res
end

local function testuint(mapping, bits)
	print("Num bits: ", bits)
	runtest{ mapping = mapping,
		numbers(int.positive, nil, bits),
	}
	if bits ~= nil and bits ~= 64 then
		runtest{ mapping = mapping, encodeerror = "overflow",
			numbers(int.positive, bits),
			numbers(int.negative),
		}
	elseif bits ~= 64 then
		runtest{ mapping = mapping,
			numbers(int.negative),
		}
	end
	runtest{ mapping = mapping, encodeerror = "no integer representation",
		numbers(float),
	}
	runtest{ mapping = mapping, encodeerror = "number",
		nonnumber,
	}
end

local function testsint(mapping, bits)
	print("Num bits: ", bits)
	runtest{ mapping = mapping,
		numbers(int.positive, nil, bits and bits-1),
		numbers(int.negative, nil, bits),
	}
	if bits ~= nil then
		runtest{ mapping = mapping, encodeerror = "overflow",
			numbers(int.positive, bits-1),
			numbers(int.negative, bits),
		}
	end
	runtest{ mapping = mapping, encodeerror = "no integer representation",
		numbers(float),
	}
	runtest{ mapping = mapping, encodeerror = "number",
		nonnumber,
	}
end

-- number sign
runtest{ mapping = primitive.sign, defaultexpected =  1,
	numbers(int.positive),
	numbers(float.positive),
}
runtest{ mapping = primitive.sign, defaultexpected = -1,
	numbers(int.negative),
	numbers(float.negative),
}
runtest{ mapping = primitive.sign, encodeerror = "number",
	nonnumber,
}
-- unsigned integers
testuint(custom.uint(1), 1)
testuint(custom.uint(2), 2)
testuint(custom.uint(3), 3)
testuint(custom.uint(4), 4)
testuint(custom.uint(7), 7)
testuint(custom.uint(8), 8)
testuint(primitive.uint8, 8)
testuint(custom.uint(16), 16)
testuint(primitive.uint16, 16)
testuint(custom.uint(24), 24)
testuint(primitive.uint32, 32)
testuint(custom.uint(32), 32)
testuint(custom.uint(53), 53)
testuint(primitive.uint64)
testuint(custom.uint(64), 64)
testuint(primitive.varint)
-- signed integers
testsint(custom.int(1), 1)
testsint(custom.int(2), 2)
testsint(custom.int(3), 3)
testsint(custom.int(4), 4)
testsint(custom.int(7), 7)
testsint(custom.int(8), 8)
testsint(primitive.int8, 8)
testsint(custom.int(16), 16)
testsint(primitive.int16, 16)
testsint(custom.int(24), 24)
testsint(primitive.int32, 32)
testsint(custom.int(32), 32)
testsint(custom.int(53), 53)
testsint(primitive.int64)
testsint(custom.int(64), 64)
testsint(primitive.varintzz)

-- single precision floats
runtest{ mapping = primitive.float,
	numbers(int, nil, 24),
	numbers(float, nil, 32),
}
runtest{ mapping = primitive.float, rounderror = 0.00001,
	numbers(int, 24),
}
runtest{ mapping = primitive.float, defaultexpected =    0, numbers(float.positive.tiny, 32) }
runtest{ mapping = primitive.float, defaultexpected =  1/0, numbers(float.positive.huge, 32) }
runtest{ mapping = primitive.float, defaultexpected =   -0, numbers(float.negative.tiny, 32) }
runtest{ mapping = primitive.float, defaultexpected = -1/0, numbers(float.negative.huge, 32) }
runtest{ mapping = primitive.float, encodeerror = "number expected",
	nonnumber,
}
-- double precision floats
runtest{ mapping = primitive.double,
	numbers(float),
}

runtest { mapping = primitive.double,
	rounderror = 0.00000001,
	numbers(int)
}

runtest{ mapping = primitive.double, encodeerror = "number expected",
	nonnumber,
}

--[[ FLOAT ENABLED VARINT
-- varint
runtest{ mapping = primitive.varint,
	numbers(int.positive),
	numbers(float.positive.huge),
}
runtest{ mapping = primitive.varint, encodeerror = "unsigned overflow",
	numbers(int.negative),
	numbers(float.negative),
}
runtest{ mapping = primitive.varint, encodeerror = "has no integer representation",
	numbers(float.positive.tiny),
}
runtest{ mapping = primitive.varint, encodeerror = ".",
	numbers(float.positive.other),
}
runtest{ mapping = primitive.varint, encodeerror = "number expected",
	nonnumber,
}
-- varint zig-zag
runtest{ mapping = primitive.varintzz,
	numbers(int),
	numbers(float.positive.huge),
	numbers(float.negative.huge),
}
runtest{ mapping = primitive.varintzz, encodeerror = "has no integer representation",
	numbers(float.positive.tiny),
	numbers(float.negative.tiny),
}
runtest{ mapping = primitive.varintzz, encodeerror = ".",
	numbers(float.positive.other),
	numbers(float.negative.other),
}
runtest{ mapping = primitive.varintzz, encodeerror = "number expected",
	nonnumber,
}
--]]
