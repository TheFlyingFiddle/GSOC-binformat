local bench		= require"benchmarks.bench"
local encoding  = require"encoding"
local custom	= require"encoding.custom"
local standard  = encoding.standard
local primitive = encoding.primitive
local expmappings  = require"experimental.optimal"

local reqr = require"reqaweqwad"

local SIZE = 1000000

local array = { }
--Create a million elements
for i=1, SIZE do
	array[i] = i;
end

local lua_value_mapping = standard.selfref(function(ref)
	return standard.union 
	{
		{ type = "nil", 	mapping = primitive.null    },
		{ type = "number", 	mapping = primitive.double  },
		{ type = "boolean", mapping = primitive.boolean },
		{ type = "string",	mapping = primitive.string  },
		{ type = "table",   mapping = standard.object(standard.map(ref, ref)) }
	}
end)

local luaformat = require"format"
local num_list  = expmappings.number_list
local slist		= standard.list
local custom_dynamic  = require"experimental.new_dynamic"
local custom_mapping  = custom_dynamic.handler:getmappingof(array) 

local lua_items =
{
	format   = luaformat,
	count    = 500,
	data     = array,
	outfile  = "large_array_benchmarks.benchmark",
	mappings = 	
	{
		{"Fast Float",  num_list(primitive.float) },
		{"Fast Double", num_list(primitive.double) },
		{"Fast uint32", num_list(primitive.uint32) },
		{"Fast uint64", num_list(primitive.uint64) },
		{"Fast int32",  num_list(primitive.int32)  },
		{"Fast int64",  num_list(primitive.int64)  },
		{"Float",		slist(primitive.float)	   },
		{"Double",		slist(primitive.double)	   },
		{"uint32",		slist(primitive.uint32)	   },
		{"uint64",		slist(primitive.uint64)	   },
		{"int32",		slist(primitive.int32)	   },
		{"int64",		slist(primitive.int64)	   },
		{"UINT20", 		slist(primitive.uint20)	   },
		{"Experiment dynamic", 	    custom_dynamic },
		{"Experiment dyn mapping",  custom_mapping },
		{"Standard dynamic",	  standard.dynamic },
		{"Union",				  lua_value_union  },
	}
}

local function equals(arr0, arr1)
	if #arr0 == #arr1 then
		for i=1, #arr0 do
			if #arr0[i] ~= #arr1[i] then
				return false			
			end
		end
		return true
	end
	
	return false
end 

local function perform_benchmarks(items)
	local maps = items.mappings
	for i=1, #items.mappings do
		local m = maps[i]
		bench.mapping(items.format, m[1], items.count, items.data, m[2])
	end
end


perform_benchmarks(lua_items)

--[[
local cformat   = require"c.format"
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

--Encoding: min 2722ms max 2900ms average 2775.8ms
--Decoding: min 5673ms max 6288ms average 5954ms
--Stream length: 18000010.0 bytes
bench.mapping(cformat, "C DYNAMIC", 5, array, standard.dynamic)

bench.mapping(cformat  , "FAST C FLOAT LIST 50",10, array,expmappings.number_list("f", 50))
bench.mapping(cformat  , "FAST C FLOAT LIST 100",10, array,expmappings.number_list("f", 100))
bench.mapping(cformat, "C DYNAMIC", 5, array, experimental.dynamic)
bench.mapping(cformat  , "FAST C FLOAT LIST 10",10, array,expmappings.number_list("f", 10))
bench.mapping(cformat  , "FAST C FLOAT LIST 5",10, array,expmappings.number_list("f", 5))
bench.mapping(cformat  , "FAST C FLOAT LIST 2",10, array,expmappings.number_list("f", 2))
bench.mapping(cformat  , "FAST C FLOAT LIST 20",10, array,expmappings.number_list("f", 20))
]]--