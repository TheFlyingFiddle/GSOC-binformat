package.path = package.path .. ";../?.lua"

local encoding  = require"encoding"
local primitive = require"encoding.primitive"
local standard	= require"encoding.standard"
local testing   = require"testing"

--Inout dynamic encoding
local data = 
{
	flag = true,
	number = 123.45,
	text   = "Lua 5.1",
	list   =
	{
		[1] = "A",
		[2] = "B",
		[3] = "C"
	}
}

local dynamic  = standard.dynamic()
testing.testmapping(data, dynamic)

local function testdynamicmapping(data, mapping)
	local out = testing.outstream()
	encoding.encode(out, data, mapping)

	local in_ 	= testing.instream(out.buffer)
	local value = encoding.decode(in_, dynamic, false)
	assert(testing.deepEquals(data, value))
end

--Dynamic readout of varint list. 
local list = standard.list(primitive.varint)
local data = {0,1,32,1512,123,412,31,251,235,1235,1235,123,123,512}
testdynamicmapping(data, list)

--Dynamic readout of tuple 
local tuple = standard.tuple({{mapping = primitive.stream}, {mapping =primitive.varint}})
local data = { "Hello", 1234 }
testdynamicmapping(data, tuple)

--Dynamic readout of union
local union = standard.list(standard.union(
{
	{ type = "string", mapping = primitive.stream },
	{ type = "number", mapping = primitive.fpdouble }	
}))

local data = { "Hello", 23, "Hello Again", 42, 42, 1512, "Yes", "No", "Please", 312, 123 }
testdynamicmapping(data, union)


--Dynamic readout of more complex type.
local vec3 = standard.tuple(
{
	{ mapping = primitive.fpsingle },
	{ mapping = primitive.fpsingle },
	{ mapping = primitive.fpsingle }		
})

local monster = standard.tuple(
{
	{ mapping = vec3 },
	{ mapping = primitive.int16 },
	{ mapping = primitive.int16 },
	{ mapping = primitive.string },
	{ mapping = primitive.boolean },
	{ mapping = standard.list(primitive.byte) },
	{ mapping = primitive.byte }	
})

local Color = { Red = 0, Green = 1, Blue = 2 }
local data = 
{
	{ 10, 15, 10 },
	150,
	100,
	"Oger",
	false,
	{ 0, 3, 12, 51, 42, 81, 44, 28, 15, 92, 123 },
	Color.Blue --Blue
}

testdynamicmapping(data, monster)