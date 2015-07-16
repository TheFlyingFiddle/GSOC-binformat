local cjson = require"cjson"
local cjson_safe = require"cjson.safe"

local tier   = require"tier"
local format = require"format"

local bench = require"benchmarks.bench"

local array = { }
for i=1, 100000 do 
	array[i] = i
end

local json_value 
local from_json_value
local safe_json_value
local from_safe_json_value

local tier_value
local from_tier_value

local fast_tier_value
local from_fast_tier_value

local varint_tier_value
local from_varint_tier_value

local function to_json()
	json_value = cjson.encode(array)
end

local function from_json()
	from_json_value = cjson.decode(json_value)
end

local function safe_to_json()
	safe_json_value = cjson_safe.encode(array)
end

local function safe_from_json()
	from_safe_json_value = cjson_safe.decode(safe_json_value)
end

local function to_tier_dynamic()
	local stream = format.outmemorystream()
	tier.encode(stream, array)
	tier_value = stream:getdata()
end

local function from_tier_dynamic()
	local stream 	= format.inmemorystream(tier_value)
	from_tier_value = tier.decode(stream) 
end

local mapping = tier.standard.dynamic.handler:getmappingof(array)
local function fast_to_tier()
	local stream = format.outmemorystream()
	tier.encode(stream, array, mapping)
	fast_tier_value = stream:getdata()
end

local function fast_from_tier()
	local stream 	= format.inmemorystream(fast_tier_value)
	fast_from_tier_value = tier.decode(stream, mapping) 
end

local varint = tier.standard.list(tier.primitive.varint)
local function varint_to_tier()
	local stream = format.outmemorystream()
	tier.encode(stream, array, varint)
	varint_tier_value = stream:getdata()
end

local function varint_from_tier()
	local stream 	= format.inmemorystream(varint_tier_value)
	varint_from_tier_value = tier.decode(stream, varint) 
end
	
local results = bench.benchmark(1, 
	{ 
		to_json, from_json, 
	  	safe_to_json, safe_from_json,
	  	to_tier_dynamic, from_tier_dynamic,
		fast_to_tier, fast_from_tier,
		varint_to_tier, varint_from_tier
	})

print("JSON Encoding  stream : time -> " .. 
	  #json_value .. " : " .. 
	  results[1].max)

print("JSON Decoding time -> " ..  results[2].max)
	  
print("SAFE JSON Encoding  stream : time -> " .. 
	  #safe_json_value .. " : " .. 
	  results[3].max)

print("SAFE JSON Decoding time -> " ..  results[4].max)
	  
print("TIER Encoding  stream : time -> " .. 
	  #tier_value .. " : " .. 
	  results[5].max)
	    
print("TIER Decoding time -> " ..  results[6].max)

print("FAST TIER Encoding stream : time -> " ..
	  #fast_tier_value .. " : " ..
	  results[7].max)

print("FAST TIER Decoding time -> " ..  results[8].max)

print("VARINT TIER Encoding stream : time -> " ..
	  #varint_tier_value .. " : " ..
	  results[9].max)

print("VARINT TIER Decoding time -> " ..  results[10].max)