local format   = require"format"
local tier = require"tier"
 
local bench = { }

function bench.benchmark(count, funs)
	local times = { }
	for i=1, count do
		for j=1, #funs do
			collectgarbage()
			if not times[j] then times[j] = { } end
			local start = os.clock()
			funs[j]()
			local stop  = os.clock()
			table.insert(times[j], stop - start)
		end
	end
	
	local timings = { }
	for i=1, #funs do
		timings[i]   = { }
		timings[i].min  = times[i][1]
		timings[i].max  = times[i][1]
		timings[i].mean = 0
	end
	
	for j=1, #funs do
		for i=1, count do
			timings[j].min  = math.min(timings[j].min, times[j][i])
			timings[j].max  = math.max(timings[j].max, times[j][i])
			timings[j].mean = timings[j].mean + times[j][i]
		end
		
		timings[j].min  = (timings[j].min * 1000) // 1
		timings[j].max  = (timings[j].max * 1000) // 1		
		timings[j].mean = (timings[j].mean * 1000 / count) / 1
	end
	
	return timings
end

function bench.mapping(format, name, count, to_encode, mapping, equality)
	print("Starting benchmark")
	local encode_output = format.outmemorystream()
	tier.encode(encode_output, to_encode, mapping, false)
	local stream_data    = encode_output:getdata()
		
	if equality then
		local decoded = tier.decode(decode_input, mapping)
		equality(decoded, to_encode)
	end	
		
	local function encode()
		local stream  = format.outmemorystream()
		local writer  = format.writer(stream)
		local encoder = tier.encoder(writer)
		encoder:encode(mapping, to_encode)
		encoder:close()
	end
	
	local function decode()
		local input	  = format.inmemorystream(stream_data)
		local reader  = format.reader(input)
		local decoder = tier.decoder(reader)
		decoder:decode(mapping)
		decoder:close()
	end	
	
	local function combined()
		local outstream = format.outmemorystream()
		local encoder   = tier.encoder(format.writer(outstream))
		encoder:encode(mapping, to_encode)
		encoder:close()
		
		local instream  = format.inmemorystream(outstream:getdata())
		local decoder	= tier.decoder(format.reader(instream))
		local decoded   = decoder:decode(mapping)
		decoder:close()
	
		if equality then
			equality(decoded, to_encode)
		end	
	end
		
	local timings = bench.benchmark(count, { encode, decode, combined } )
	
	print(name .. ":")
	print("tier min:max:mean " .. timings[1].min .. " : " .. timings[1].max .. " : " .. timings[1].mean)
	print("Decoding min:max:mean " .. timings[2].min .. " : " .. timings[2].max .. " : " .. timings[2].mean)
	print("Combined min:max:mean " .. timings[3].min .. " : " .. timings[3].max .. " : " .. timings[3].mean)
	print("Stream size " .. #stream_data)
end




return bench