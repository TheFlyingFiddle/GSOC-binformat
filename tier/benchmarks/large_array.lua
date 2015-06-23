
local bench		= require"benchmarks.bench"
local encoding  = require"encoding"
local custom	= require"encoding.custom"
local standard  = encoding.standard
local primitive = encoding.primitive


local SIZE = 1000000

local array = { }
--Create a million elements
for i=1, SIZE do
	array[i] = i;
end

local uint_mapping 	 = standard.list(primitive.uint32)
local bit_mapping    = standard.list(primitive.uint20)
local varint_mapping = standard.list(primitive.varint)
local float_mapping  = standard.list(primitive.float)

local luaref   			= custom.typeref()
local lua_value_mapping = standard.union
{
	{ type = "nil", 	mapping = primitive.null },
	{ type = "number", 	mapping = primitive.double },
	{ type = "boolean", mapping = primitive.boolean },
	{ type = "string",	mapping = primitive.string },
	{ type = "table",   mapping = standard.object(standard.map(luaref, luaref)) }
}
luaref:setref(lua_value_mapping)


local cformat   = require"c.format"
local luaformat = require"format"


--Encoding: min 2240ms max 2326ms average 2276ms 
--Decoding: min 2112ms max 2324ms average 2218ms
--Stream length: 400003 bytes
bench.mapping(luaformat, "LUA FLOAT", 5, array, float_mapping)

--Encoding: min 2590ms max 2948ms average 2698ms
--Decoding: min 2569ms max 2810ms average 2660ms
--Stream length: 400003 bytes
bench.mapping(luaformat, "LUA UINT32", 5, array, uint_mapping)

--Encoding: min 5343ms max 5773ms average 5552ms
--Decoding: min 4048ms max 4244ms average 4126ms
--Stream length: 2500003 bytes
bench.mapping(luaformat, "LUA UINT20", 5, array, bit_mapping)

--Encoding: min 4345ms max 5034ms average 4753ms
--Decoding: min 4053ms max 4265ms average 4136ms
--Stream length: 2983493 bytes
bench.mapping(luaformat, "LUA VARINT", 5, array, varint_mapping)


--Encoding: min 359ms max 386ms average 366.8ms 
--Decoding: min 448ms max 496ms average 464.0ms
--Stream length: 400003 bytes
bench.mapping(cformat, "C FLOAT", 5, array, float_mapping)

--Encoding: min 417ms max 511ms average 462.6ms
--Decoding: min 491ms max 586ms average 542ms
--Stream length: 400003 bytes
bench.mapping(cformat, "C UINT32", 5, array, uint_mapping)

--Encoding: min 467ms max 530ms average 496.4ms
--Decoding: min 541ms max 624ms average 585ms
--Stream length: 2500003 bytes
bench.mapping(cformat, "C UINT20", 5, array, bit_mapping)

--Encoding: min 448ms max 512ms average 469ms
--Decoding: min 559ms max 610ms average 581ms
--Stream length: 2983493 bytes
bench.mapping(cformat, "C VARINT", 5, array, varint_mapping)

bench.mapping(cformat, "C UNION", 1, array, lua_value_mapping)

bench.mapping(luaformat, "LUA UNION", 1, array, lua_value_mapping)

--Encoding: min 2722ms max 2900ms average 2775.8ms
--Decoding: min 5673ms max 6288ms average 5954ms
--Stream length: 18000010.0 bytes
bench.mapping(cformat, "C DYNAMIC", 5, array, standard.dynamic)

--Encoding: min 9467ms max 10262ms average 9919ms
--Decoding: min 14655ms max 15060ms average 14794ms
bench.mapping(luaformat, "LUA DYNAMIC", 1, array, standard.dynamic)