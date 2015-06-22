local format   = require"format"
local encoding = require"encoding"
 
local bench = { }

function bench.benchmark(name, count, fun)
	local times = { }
	for i=1, count do
		local start = os.clock()
		fun()
		local stop  = os.clock()
		table.insert(times,  stop - start)	
	end
	
	local min = times[1]
	local max = times[1]
	local mean = 0
	for i=1, count do
		min = math.min(min, times[i])
		max = math.max(max, times[i])
		mean = mean + times[i]
	end
	mean = mean / count				
	
	min = min * 1000
	max = max * 1000
	mean = mean * 1000
	
	
	print(string.format("Benchmarking %s:(msec) min %s max %s mean %s", name, min, max, mean))	
end

function bench.mapping(format, name, count, to_encode, mapping)
	collectgarbage()
	
	local memstream = format.outmemorystream();
	local writer    = format.writer(memstream)
	bench.benchmark("encode of " .. name, count, function()
		local encoder = encoding.encoder(writer)
		encoder:encode(mapping, to_encode);
		encoder:close();
	end)

	local data = memstream:getdata();
	local in_mem_stream = format.inmemorystream(data);
	local reader 		= format.reader(in_mem_stream)
	
	bench.benchmark("decode of " .. name, count, function()	
		local decoder = encoding.decoder(reader)
		decoder:decode(mapping)
		decoder:close()
	end)
	
	print(string.format("Outstream size is: %s", #data / count))
end




return bench