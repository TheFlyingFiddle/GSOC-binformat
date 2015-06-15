-- small integer numbers
local Int8Cases = {
	{ actual = 0x00 },
	{ actual = 0x01 },
	{ actual = 0x55 },
	{ actual = 0x7e },
	{ actual = 0x7f },
}
local Int16Cases = {
	{ actual = 0x100 },
	{ actual = 0x101 },
	{ actual = 0x5555 },
	{ actual = 0x7ffe },
	{ actual = 0x7fff },
}
local Int32Cases = {
	{ actual = 0x10000 },
	{ actual = 0x10001 },
	{ actual = 0x55555555 },
	{ actual = 0x7ffffffe },
	{ actual = 0x7fffffff },
}
local Int64Cases = {
	{ actual = 0x100000000 },
	{ actual = 0x100000001 },
	{ actual = 0x5555555555555555 },
	{ actual = 0x7ffffffffffffffe },
	{ actual = 0x7fffffffffffffff },
}
-- large integer numbers
local uInt8Cases = {
	{ actual = 0x80 },
	{ actual = 0x81 },
	{ actual = 0xaa },
	{ actual = 0xfe },
	{ actual = 0xff },
}
local uInt16Cases = {
	{ actual = 0x8000 },
	{ actual = 0x8001 },
	{ actual = 0xaaaa },
	{ actual = 0xfffe },
	{ actual = 0xffff },
}
local uInt32Cases = {
	{ actual = 0x80000000 },
	{ actual = 0x80000001 },
	{ actual = 0xaaaaaaaa },
	{ actual = 0xfffffffe },
	{ actual = 0xffffffff },
}
local uInt64Cases = {
	-- not supported in standard Lua 5.3
	--{ actual = 0x8000000000000000 },
	--{ actual = 0x8000000000000001 },
	--{ actual = 0xaaaaaaaaaaaaaaaa },
	--{ actual = 0xfffffffffffffffe },
	--{ actual = 0xffffffffffffffff },
}
-- negative integer numbers
local sInt8Cases = {
	{ actual = -0x01 },
	{ actual = -0x02 },
	{ actual = -0x55 },
	{ actual = -0x7f },
	{ actual = -0x80 },
}
local sInt16Cases = {
	{ actual = -0x0001 },
	{ actual = -0x0002 },
	{ actual = -0x5555 },
	{ actual = -0x7fff },
	{ actual = -0x8000 },
}
local sInt32Cases = {
	{ actual = -0x8001 },
	{ actual = -0x8002 },
	{ actual = -0x55555555 },
	{ actual = -0x7fffffff },
	{ actual = -0x80000000 },
}
local sInt64Cases = {
	{ actual = -0x80000001 },
	{ actual = -0x80000002 },
	{ actual = -0x5555555555555555 },
	{ actual = -0x7fffffffffffffff },
	{ actual = -0x8000000000000000 },
}
-- irrational numbers
local SinglePrecisionCases = {
	-- must be some value that has precise representation both in single
	-- and double precision!
}
local DoublePrecisionCases = {
	{ actual = math.pi },
	{ actual = -math.pi },
}
-- non-numeric values
local NonNumberCases = {
	{ actual = nil },
	{ actual = false },
	{ actual = true },
	{ actual = "text" },
	{ actual = {} },
	{ actual = print },
	{ actual = function() end },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
}

local SignCases =
{
	{ actual = 1,     expected = 1 },
	{ actual = -1,    expected = -1 }
}

runtest{ mapping = primitive.sign, SignCases }

-- unsigned integer of 8-bit
runtest{ mapping = primitive.byte,
	Int8Cases,
	uInt8Cases,
}
runtest{ mapping = primitive.byte, encodeerror = "unsigned overflow",
	Int16Cases,
	Int32Cases,
	Int64Cases,
	uInt16Cases,
	uInt32Cases,
	uInt64Cases,
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.byte, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.byte, encodeerror = "number expected",
	NonNumberCases,
}
-- unsigned integer of 16-bit
runtest{ mapping = primitive.uint16,
	Int8Cases,
	Int16Cases,
	uInt8Cases,
	uInt16Cases,
}
runtest{ mapping = primitive.uint16, encodeerror = "unsigned overflow",
	Int32Cases,
	Int64Cases,
	uInt32Cases,
	uInt64Cases,
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.uint16, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.uint16, encodeerror = "number expected",
	NonNumberCases,
}
-- unsigned integer of 32-bit
runtest{ mapping = primitive.uint32,
	Int8Cases,
	Int16Cases,
	Int32Cases,
	uInt8Cases,
	uInt16Cases,
	uInt32Cases,
}
runtest{ mapping = primitive.uint32, encodeerror = "unsigned overflow",
	Int64Cases,
	uInt64Cases,
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.uint32, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.uint32, encodeerror = "number expected",
	NonNumberCases,
}
-- unsigned integer of 64-bit
runtest{ mapping = primitive.uint64,
	Int8Cases,
	Int16Cases,
	Int32Cases,
	Int64Cases,
	uInt8Cases,
	uInt16Cases,
	uInt32Cases,
	uInt64Cases,
}
runtest{ mapping = primitive.uint64, --encodeerror = "unsigned overflow",
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.uint64, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.uint64, encodeerror = "number expected",
	NonNumberCases,
}
-- varint
runtest{ mapping = primitive.varint,
	Int8Cases,
	Int16Cases,
	Int32Cases,
	Int64Cases,
	uInt8Cases,
	uInt16Cases,
	uInt32Cases,
	uInt64Cases,
}
runtest{ mapping = primitive.varint, --encodeerror = "unsigned overflow",
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.varint, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.varint, encodeerror = "number expected",
	NonNumberCases,
}
-- signed integer of 16-bit
runtest{ mapping = primitive.int16,
	Int8Cases,
	Int16Cases,
	uInt8Cases,
	sInt8Cases,
	sInt16Cases,
}
runtest{ mapping = primitive.int16, encodeerror = "integer overflow",
	Int32Cases,
	Int64Cases,
	uInt16Cases,
	uInt32Cases,
	uInt64Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.int16, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.int16, encodeerror = "number expected",
	NonNumberCases,
}
-- signed integer of 32-bit
runtest{ mapping = primitive.int32,
	Int8Cases,
	Int16Cases,
	Int32Cases,
	uInt8Cases,
	uInt16Cases,
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
}
runtest{ mapping = primitive.int32, encodeerror = "integer overflow",
	Int64Cases,
	uInt32Cases,
	uInt64Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.int32, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.int32, encodeerror = "number expected",
	NonNumberCases,
}
-- signed integer of 64-bit
runtest{ mapping = primitive.int64,
	Int8Cases,
	Int16Cases,
	Int32Cases,
	Int64Cases,
	uInt8Cases,
	uInt16Cases,
	uInt32Cases,
	uInt64Cases,
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.int64, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.int64, encodeerror = "number expected",
	NonNumberCases,
}
-- varint zig-zag
runtest{ mapping = primitive.varintzz,
	Int8Cases,
	Int16Cases,
	Int32Cases,
	Int64Cases,
	uInt8Cases,
	uInt16Cases,
	uInt32Cases,
	uInt64Cases,
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
}
runtest{ mapping = primitive.varintzz, encodeerror = "has no integer representation",
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.varintzz, encodeerror = "attempt to compare number",
	NonNumberCases,
}
-- single precision floats
runtest{ mapping = primitive.fpsingle,
	Int8Cases,
	Int16Cases,
	uInt8Cases,
	uInt16Cases,
	sInt8Cases,
	sInt16Cases,
	SinglePrecisionCases,
}
runtest{ mapping = primitive.fpsingle, rounderror = 0.001,
	Int32Cases,
	Int64Cases,
	uInt32Cases,
	uInt64Cases,
	sInt32Cases,
	sInt64Cases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.fpsingle, encodeerror = "number expected",
	NonNumberCases,
}
-- double precision floats
runtest{ mapping = primitive.fpdouble,
	Int8Cases,
	Int16Cases,
	Int32Cases,
	Int64Cases,
	uInt8Cases,
	uInt16Cases,
	uInt32Cases,
	uInt64Cases,
	sInt8Cases,
	sInt16Cases,
	sInt32Cases,
	sInt64Cases,
	SinglePrecisionCases,
	DoublePrecisionCases,
}
runtest{ mapping = primitive.fpdouble, encodeerror = "number expected",
	NonNumberCases,
}