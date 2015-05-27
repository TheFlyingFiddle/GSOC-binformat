package.path = package.path .. ";../?.lua"

local encoding  = require"encoding"
local primitive = require"encoding.primitive"
local standard	= require"encoding.standard"
local testing   = require"testing"

--This function tests that mirroring encoding/decoding functions work.
--@params mapper the mapping object used for encoding and decoding.
--@params args a number of arguments to encode and decode.

--The function tests the mapper by using it to encode and decode 
--to a faked stream.
function testSuccess(mapper, args, equals)
	if not equals then
		equals = function(a, b) return a == b end
	end

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
	
	local mockIn = testing.instream(mockOut.buffer)
	local decoder = encoding.decoder(mockIn)
	--Then we decode them and make sure they are the same.
	for _, v in pairs(args) do
		local status, decodedOrErr = pcall(decoder.decode, decoder, mapper);
		if status then 
			if not equals(decodedOrErr, v) then 
				error(string.format(
					"Did not decode input correctly. Input:%s Output:%s" ..
					"Using mapper %s",
					tostring(v), decodeOrErr, mapper, decoderFunc));
			end
		else 
			error(string.format(
				"Decoding failed for valid input %s with mapper %s\nWith error: %s"
				, tostring(v), mapper, decodedOrErr));
		end
	end
end


print("Staring encoding.standard tests")

local mapping = standard.list(primitive.bit);
testSuccess(mapping, 
{
	{true, false, false, true, false},
	{false, true, true, false, true}
}, testing.deepEquals)

local mapping = standard.map(primitive.stream, primitive.varint)
testSuccess(mapping, 
{
	{
		["John Doe"] = 25,
		["Jane Doe"] = 25,
		["Baby Doe"] = 1	
	},
	{
		["Donald Duck"]  = 312,
		["Mickey Mouse"] = 32,
		["Goofy"]		 = 12
	}
}, testing.deepEquals);

local mapping = standard.tuple(
{
	{mapping = primitive.stream},
	{mapping = primitive.varint},
	{mapping = primitive.bit}	
})

testSuccess(mapping,
{
	{
		"Picard",
		20,
		true
	},
	{
		"Worf",
		15,
		false
	},
	{
		"Riker",
		18,
		false
	},
	{
		"Data",
		13,
		false
	}
}, testing.deepEquals)

local mapping = standard.tuple(
{
	{key = "name", mapping = primitive.stream},
	{key = "rank", mapping = primitive.varint},
	{key = "captain", mapping = primitive.bit}
})

testSuccess(mapping,
{
	{
		name = "Pickard",
		rank = 20,
		captain = true
	},
	{
		name = "Worf",
		rank = 15,
		captain = false
	},
	{
		name = "Riker",
		rank = 18,
		captain = false
	},
	{
		name = "Data",
		rank = 13,
		captain = false
	}
}, testing.deepEquals)

local mapping = standard.list(standard.union(
{
	{ type = "string", mapping = primitive.stream },
	{ type = "nil",    mapping = primitive.null }
}))

testSuccess(mapping, 
{
	{ "A", nil, "B", nil, "C" },
	{ "D", "E", nil, nil, "F" }
}, testing.deepEquals)

print("All tests succeeded.")