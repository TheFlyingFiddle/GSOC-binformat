local format	= require"format"
local bench		= require"benchmarks.bench"
local encoding  = require"encoding"
local standard  = encoding.standard
local primitive = encoding.primitive


local array = { }
--Create a million elements
for i=1, 10000 do
	table.insert(array, i)
end

local uint_mapping 	 = standard.list(primitive.uint32)
local bit_mapping    = standard.list(primitive.uint20)
local varint_mapping = standard.list(primitive.varint)


function timemapping(name, count, to_encode, mapping)
	collectgarbage()

	local outstream = format.memoryoutstream()
	bench.benchmark("encode of " .. name, count, function()
		encoding.encode(outstream, to_encode, mapping)
	end)

	local data = outstream:getdata()
	local instream = format.memoryinstream(data)
	bench.benchmark("decode of " .. name, count, function()	
		encoding.decode(instream, mapping)	
	end)
	print(string.format("Outstream size is: %s", #data / count))
end

timemapping("uint32", 10, array, uint_mapping)
timemapping("uint20", 10, array, bit_mapping)
timemapping("varint", 10, array, varint_mapping)
timemapping("dynamic", 1, array, standard.dynamic)

--bench.timemapping("dynamic", 1,  array, standard.dynamic)

--Time encoding.