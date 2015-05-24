package.path = package.path .. ";../?.lua"

local encoding   = require"encoding"
local primitives = require"encoding.primitive"
local testing    = require"testing"

--This function tests that mirroring encoding/decoding functions work.
--@params mapper the mapping object used for encoding and decoding.
--@params args a number of arguments to encode and decode.

--The function tests the mapper by using it to encode and decode 
--to a faked stream.
function testSuccess(mapper, args)
	local mockOut = testing.outstream()
	local encoder = encoding.encoder(mockOut)

	--Start by encoding the values in args
	for _, v in pairs(args) do
		local status, err = pcall(encoder.encode, encoder, mapper, v);
		if not status then
			error(string.format(
			   "Failed to encode %s using mapper %s.\nWith error %s",
				tostring(v), mapper, err))
		end
	end
	
	local mockIn = testing.outstream(mockOut.buffer)
	local decoder = encoding.decoder(mockOut)

	--Then we decode them and make sure they are the same.
	for _, v in pairs(args) do
		local status, decodedOrErr = pcall(decoder.decode, decoder, mapper);
		if status then 
			if decodedOrErr ~= v then 
				error(string.format(
					"Did not decode input correctly. Input:%s Output:%s" ..
					"Using mapper %s",
					tostring(v), decodeOrErr, mapper, decoderFunc));
			end
		else 
			if shouldWork then 
				error(string.format(
					"Decoding failed for valid input %s with mapper %s\nWith error: %s"
					, tostring(v), mapper));
			end
		end
	end
end

print("Starting encoding.primitive tests")

testSuccess(primitives.bit, {true, false})
testSuccess(primitives.boolean, {true, false})

--Test that we can write/read floats.
--Singles are abit tricky since you lose precisions.
testSuccess(primitives.fpsimple, testing.randomInts(0, 0xffff, 20)); 

--Test that we can write/read doubles.
testSuccess(primitives.fpdouble, testing.randomDoubles(20))

--Test that write/read bytes works correctly.
testSuccess(primitives.byte, 
{
	0, 
	0xff, 
	table.unpack(testing.randomInts(0, 0xff, 20))
})

--Test that write/read of chars works correctly.
testSuccess(primitives.char, 
{
	0, 
	0xff, 
	table.unpack(testing.randomInts(0, 0xff, 20))
})

--Test that write/read of wchars works correctly. 
testSuccess(primitives.wchar,
{
	-0x8000, 
	0x7fff, 
	table.unpack(testing.randomInts(-0x8000, 0x7fff, 20))
})

--Test that write/read 16-bit uints works correctly.
testSuccess(primitives.uint16, 
{
	0, 
	0xffff, 
	table.unpack(testing.randomInts(0, 0xffff, 20))
})

--Test that write/read 32-bit uints works correctly.
testSuccess(primitives.uint32,
{
	0,
	0xffffffff, 
	table.unpack(testing.randomInts(0, 0xffffffff, 20))
})

--Test that write/read 64-bit uints works correctly.
testSuccess(primitives.uint64,
{	
	0, 
	0xffffffffffffffff, 
	table.unpack(testing.randomInts(0, 0x7fffffffffffffff, 20))
})

--Test that write/read 16-bit signed ints works correctly.
testSuccess(primitives.int16,
{
	-0x8000, 
	0x7fff, 
	table.unpack(testing.randomInts(-0x8000, 0x7fff, 20))
})

--Test that write/read 32-bit signed ints works correctly.
testSuccess(primitives.int32,
{
	-0x80000000,
	0x7fffffff,
	table.unpack(testing.randomInts(-0x80000000, 0x7fffffff, 20))
})


--Test that write/read 64-bit signed ints works correctly.
testSuccess(primitives.int64,
{
	-0x8000000000000000,
	0x7fffffffffffffff,
	table.unpack(testing.randomInts(-0x800000000000, 0x800000000000, 20))
})

--Tests that we can write/read variable length integers in various ranges.
testSuccess(primitives.varint,
{
	0,
	0xff, 
	0xffff, 
	0xffffffff, 
	0xffffffffffffffff,
	table.unpack(testing.randomInts(0, 0xff, 20)),									--Byte range
	table.unpack(testing.randomInts(0x100, 0xffff, 20)),								--Short range
	table.unpack(testing.randomInts(0x10000, 0xffffffff, 20)),						--Int	range
	table.unpack(testing.randomInts(0x100000000, 0x7fffffffffffffff, 20)),			--long  range
	table.unpack(testing.randomInts(0x8000000000000000, 0xffffffffffffffff, 20))	--long  range
})

--Tests that we can write/read variable length signed integers in various ranges.
testSuccess(primitives.varintzz,
{
	0,
	-0x80,
	0xff,
	-0x8000, 
	0xffff, 
	-0x8000000, 
	0xffffffff,
	-0x8000000000000000,
	0xffffffffffffffff,
	table.unpack(testing.randomInts(0, 0xff, 20)),									--Byte range
	table.unpack(testing.randomInts(0x100, 0xffff, 20)),								--Short range
	table.unpack(testing.randomInts(0x10000, 0xffffffff, 20)),						--Int	range
	table.unpack(testing.randomInts(0x100000000, 0x7fffffffffffffff, 20)),			--long  range
	table.unpack(testing.randomInts(0x8000000000000000, 0xffffffffffffffff, 20))		--long  range
})


--Test that we can write/read strings.
testSuccess(primitives.stream,
{
	"Lorem ipsum dolor",
	"sit amet, consectetur",
	"Ut lobortis",
	"placerat mi vel tempor",
	"Il et felis eu sapien interdum",
	"sollicitudin sit anet quis mi. Proin",
	"iaculis vehicula ultrices"
})

testSuccess(primitives.string,
{
	"Lorem ipsum dolor",
	"sit amet, consectetur",
	"Ut lobortis",
	"placerat mi vel tempor",
	"Il et felis eu sapien interdum",
	"sollicitudin sit anet quis mi. Proin",
	"iaculis vehicula ultrices"
})

testSuccess(primitives.wstring,
{
	"Lorem ipsum dolor",
	"sit amet, consectetur",
	"Ut lobortis",
	"placerat mi vel tempor",
	"Il et felis eu sapien interdum",
	"sollicitudin sit anet quis mi. Proin",
	"iaculis vehicula ultrices"
})

print("all test passed")