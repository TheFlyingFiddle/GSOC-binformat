package.path = package.path .. ";../?.lua"

local encoding  = require"encoding"
local primitive = require"encoding.primitive"
local standard	= require"encoding.standard"
local testing   = require"testing"

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
testing.prettyPrint(data)

local mapping  = standard.dynamic()
local out = testing.outstream();
encoding.encode(out, data, mapping)

local in_ = testing.instream(out.buffer)
local value = encoding.decode(in_, mapping)

testing.prettyPrint(value)
assert(testing.deepEquals(data, value))