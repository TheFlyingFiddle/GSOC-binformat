local encoding = require("encoding")
local testing   = require"tests.testing"
--This function tests that mirroring encoding/decoding functions work.
--@params encodeFunc the encoding function under test
--@params decodeFunc the decoding function under test
--@params args a number of arguments to encode and decode.

--The function tests the encode and decode function by first encoding all elements
--in the args parameter. After this it decodes the values produced by the encoding 
--function. These decoded values are checked agains the input and if they are inccorect
--an error is produced. 
function testSuccess(func, args)
	local mockOut  = testing.outstream()
	local encoder = encoding.encoder(mockOut)
	local writer  = encoder.writer;	
	--Start by encoding the values in args
	for _, v in pairs(args) do
		local f = writer[func];
		local status, err = pcall(f, writer, v);
		if not status then
			error(string.format(
			   "Failed to encode %s with %s. \nWith error %s",
				tostring(v), func, err))
		end
	end
	encoder:close()
	
	local mockIn = testing.instream(mockOut.buffer)
	local decoder = encoding.decoder(mockIn)
	local reader  = decoder.reader

	--Then we decode them and make sure they are the same.
	for _, v in pairs(args) do
		local f = reader[func];
		local status, decodedOrErr = pcall(f, reader);
		if decodedOrErr ~= v then 
			error(string.format(
				"Did not decode input correctly. Input:%s Output:%s" ..
				" Using %s.",
				tostring(v), tostring(decodedOrErr), func));
		end
	end
end

function testEncodingFaliure(encodeFunc, args)
	local mockIn  = testing.instream()
	local encoder = encoding.encoder(mockIn)

	--Start by encoding the values in args
	for _, v in pairs(args) do
		local func = encoder[encodeFunc];
		local status, err = pcall(func, encoder, v);
		if status then 
			error(string.format(
				  "Incorrectly succeeded to encode %s with encoder %s and decoder %s",
				  tostring(v), encodeFunc))	
		end	
	end
end


print("Testing encoding.")

--Tests that we can write/read bits (booleans)
testSuccess("bool",  {true, false});

--Test that we can write/read floats.
--Singles are abit tricky since you lose precisions.
testSuccess("single", testing.randomInts(0, 0xffff, 20)); 

--Test that we can write/read doubles.
testSuccess("double", testing.randomDoubles(20))

--Test that write/read bytes works correctly.
testSuccess("byte", 
{
	0, 
	0xff, 
	table.unpack(testing.randomInts(0, 0xff, 20))
})


--Test that write/read 16-bit uints works correctly.
testSuccess("uint16", 
{
	0, 
	0xffff, 
	table.unpack(testing.randomInts(0, 0xffff, 20))
})

--Test that write/read 32-bit uints works correctly.
testSuccess("uint32", 
{
	0,
	0xffffffff, 
	table.unpack(testing.randomInts(0, 0xffffffff, 20))
})

--Test that write/read 64-bit uints works correctly.
testSuccess("uint64", 
{	
	0, 
	0xffffffffffffffff, 
	table.unpack(testing.randomInts(0, 0x7fffffffffffffff, 20))
})

--Test that write/read 16-bit signed ints works correctly.
testSuccess("int16",  
{
	-0x8000, 
	0x7fff, 
	table.unpack(testing.randomInts(-0x8000, 0x7fff, 20))
})

--Test that write/read 32-bit signed ints works correctly.
testSuccess("int32",
{
	-0x80000000,
	0x7fffffff,
	table.unpack(testing.randomInts(-0x80000000, 0x7fffffff, 20))
})


--Test that write/read 64-bit signed ints works correctly.
testSuccess("int64",
{
	-0x8000000000000000,
	0x7fffffffffffffff,
	table.unpack(testing.randomInts(-0x800000000000, 0x800000000000, 20))
})

--Test that we cannot write bytes larger then 0xff.
testEncodingFaliure("byte", testing.randomInts(0x100, 0xffff, 20))

--Test that we cannot write 16-bit ints larger then 0xffff.
testEncodingFaliure("uint16", testing.randomInts(0x10000, 0xffffffff, 20))

--Test that we cannot write 32-bit ints larger then 0xffffffff.
testEncodingFaliure("uint32", testing.randomInts(0x100000000, 0x800000000000000, 20))

--Test that we cannot write 16-bit signed ints larger then 0x8000
testEncodingFaliure("int16", testing.randomInts(0x8000, 0xffff, 20))

--Test that we cannot write 32-bit signed ints larger then 0x80000000
testEncodingFaliure("int32", testing.randomInts(0x80000000, 0xffffffff, 20))

--Tests that we can write/read variable length integers in various ranges.
testSuccess("varint", 
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
testSuccess("varintzz", 
{
	0,
	-0x80,
	0xff,
	-0x8000, 
	0xffff, 
	-0x8000000, 
	0xffffffff,
	-0x7fffffffffffffff,
	0xffffffffffffffff,
	table.unpack(testing.randomInts(0, 0xff, 20)),									--Byte range
	table.unpack(testing.randomInts(0x100, 0xffff, 20)),								--Short range
	table.unpack(testing.randomInts(0x10000, 0xffffffff, 20)),						--Int	range
	table.unpack(testing.randomInts(0x100000000, 0x7fffffffffffffff, 20)),			--long  range
	table.unpack(testing.randomInts(0x8000000000000000, 0xffffffffffffffff, 20))		--long  range
})


--Test that we can write/read strings.
testSuccess("stream",
{
	"Lorem ipsum dolor",
	"sit amet, consectetur",
	"Ut lobortis",
	"placerat mi vel tempor",
	"Il et felis eu sapien interdum",
	"sollicitudin sit anet quis mi. Proin",
	"iaculis vehicula ultrices"
})

local function testBits(func, bits, cases)
	local mockOut  = testing.outstream()
	local encoder = encoding.encoder(mockOut)
	local writer  = encoder.writer;	
	--Start by encoding the values in args
	for _, v in pairs(cases) do
		local f = writer[func]
		f(writer, bits, v)
	end
	
	encoder:close()
	
	local mockIn = testing.instream(mockOut.buffer)
	local decoder = encoding.decoder(mockIn)
	local reader  = decoder.reader

	--Then we decode them and make sure they are the same.
	for _, v in pairs(cases) do
		local f = reader[func];
		local decoded = f(reader, bits)
		assert(decoded == v, "expected " .. v .. " actual " .. decoded)
	end

end


for i=1, 63 do 
	local uints = testing.randomInts(0, (1 << 1) - 1, 20)
	local ints  = testing.randomInts(-(1 << (i - 1)), (1 << (i - 1)) - 1, 20)
	
	testBits("uint", i, uints)
	testBits("int",  i, ints)	
end


print("All encoding tests passed.")