
local bench		= require"benchmarks.bench"
local encoding  = require"encoding"
local standard  = encoding.standard
local primitive = encoding.primitive


local SIZE = 100000

local array = { }
--Create a million elements
for i=1, SIZE do
	array[i] = i;
end

local uint_mapping 	 = standard.list(primitive.uint32)
local bit_mapping    = standard.list(primitive.uint20)
local varint_mapping = standard.list(primitive.varint)
local float_mapping  = standard.list(primitive.fpsingle)


local cformat   = require"c.format"
local luaformat = require"format"

bench.mapping(cformat, "C FLOAT", 10, array, float_mapping)
bench.mapping(cformat, "C UINT32", 10, array, uint_mapping)
bench.mapping(cformat, "C UINT20", 10, array, bit_mapping)
bench.mapping(cformat, "C VARINT", 10, array, varint_mapping)
bench.mapping(cformat, "C DYNAMIC", 10, array, standard.dynamic)

bench.mapping(luaformat, "LUA FLOAT", 10, array, float_mapping)
bench.mapping(luaformat, "LUA UINT32", 10, array, uint_mapping)
bench.mapping(luaformat, "LUA UINT20", 10, array, bit_mapping)
bench.mapping(luaformat, "LUA VARINT", 10, array, varint_mapping)
bench.mapping(luaformat, "LUA DYNAMIC", 10, array, standard.dynamic)

--Time encoding.