package.path = package.path .. ";../?.lua"

local encoding  = require"encoding"
local primitive = require"encoding.primitive"
local standard	= require"encoding.standard"
local testing   = require"testing"



local out = testing.outstream()
local encoder = encoding.encoder(out)

-- table with a sequence of booleans encoded as 'LIST BIT'
local data = { true, false, true, false }
local mapping = standard.list(primitive.bit)
encoder:encode(mapping, data) -- encode raw data

-- table mapping strings to numbers encoded as 'MAP STREAM VARINT'
local data = {
	["John Doe"] = 25,
	["Jane Doe"] = 25,
	["Baby Doe"] = 1,
}
local mapping = standard.map(primitive.stream, primitive.varint)
encoder:encode(mapping, data) -- encode raw data

-- table containg info about a person as 'TUPLE 03 STREAM VARINT BIT'
local data = {
	"John Doe", -- name
	25, -- age
	true, -- male
}
local mapping = standard.tuple({
	{mapping = primitive.stream}, -- default value for 'key' is 1
	{mapping = primitive.varint}, -- default value for 'key' is 2
	{mapping = primitive.bit}, -- default value for 'key' is 3
})
encoder:encode(mapping, data) -- encode raw data

-- table containg fields about a person as 'TUPLE 03 STREAM VARINT BIT'
local data = {
	name = "John Doe",
	age = 25,
	male = true,
}
local mapping = standard.tuple({
	{key = "name", mapping = primitive.stream},
	{key = "age", mapping = primitive.varint},
	{key = "male", mapping = primitive.bit},
})
encoder:encode(mapping, data) -- encode raw data

-- table containing strings and nils as 'LIST UNION 02 STREAM NULL'
local data = { "A", nil, "B", nil, "C" }
local mapping = standard.list(standard.union({
	["string"] = primitive.stream, -- when value is a string
	["nil"] = primitive.null, -- when value is nil
}))
encoder:encode(mapping, data) -- encode raw data

-- flushes any pending data and finished the encoding scope
encoder:close()
out:close()
