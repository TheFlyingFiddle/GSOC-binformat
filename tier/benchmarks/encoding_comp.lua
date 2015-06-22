local cformat = require"c.format"
local bench		= require"benchmarks.bench"

--Time: min 853ms max 1027ms average 936.2ms
bench.benchmark("Writing 10 million varints inmemory from C", 5,  function()
	local file	 = cformat.outmemorystream();
	local writer = cformat.writer(file)
	
	local write = writer.varint;
	for i=1, 10^7 do
		write(writer, i);
	end
	file:close();
end);


--Time: min 1138ms max 1357ms average 1236ms
bench.benchmark("Writing 10 million varints to a file in C", 5,  function()
	local file	 = io.open("c_data.dat", "wb")
	local writer = cformat.writer(file)
	
	local write = writer.varint;
	for i=1, 10^7 do
		write(writer, i);
	end
	file:close();
end)

--Time: min 904ms max 962ms average 936ms
bench.benchmark("Reading 10 million varints froma a file in C", 5, function()
	local file	 = assert(io.open("c_data.dat", "rb"));
	local reader = cformat.reader(file);
	
	local read = reader.varint;
	for i=1, 10^7 do
		read(reader);
	end
	
	file:close();
end)


local format = require"format"

--Time: min 38392ms max 40337ms average 39325ms
bench.benchmark("Writing 10 million varints to a file in Lua", 5, function()
	local file		= io.open("c_data.dat", "wb");
	local writer 	= format.writer(file);
	
	local write  = writer.varint;
	for i=1, 10^7 do
		write(writer, i);
	end
	
	file:close();
end);

bench.benchmark("Reading 10 million varints from a file in Lua", 5, function()
	local file		= io.open("c_data.dat", "rb");
	local reader 	= format.reader(file);
	
	local read  = reader.varint;
	for i=1, 10^7 do
		read(reader);
	end
	
	file:close();
end);