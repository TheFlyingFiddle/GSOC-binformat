local cformat = require"c.format"
local bench		= require"benchmarks.bench"

bench.benchmark("Writing a billion ints inmemory from C", 1,  function()
	local file	 = cformat.outmemorystream(1024*50);
	local writer = cformat.writer(file)
	
	local write_int32 = writer.varint;
	for i=1, 10^7 do
		write_int32(writer, i);
	end
	file:close();
end);


bench.benchmark("Writing a billion ints from C", 1,  function()
	local file	 = io.open("c_data.dat", "wb")
	local writer = cformat.writer(file)
	
	local write_int32 = writer.varint;
	for i=1, 10^7 do
		write_int32(writer, i);
	end
	file:close();
end)

bench.benchmark("Reading a billiion ints from C", 1, function()
	local file	 = assert(io.open("c_data.dat", "rb"));
	local reader = cformat.reader(file);
	
	local read_int32 = reader.varint;
	for i=1, 10^7 do
		read_int32(reader);
	end
	
	file:close();
end)


local format = require"format"
bench.benchmark("Writing a billion ints from Lua", 1, function()
	local file		= io.open("c_data.dat", "wb");
	local writer 	= format.writer(file);
	
	local write_32  = writer.varint;
	for i=1, 10^7 do
		write_32(writer, i);
	end
	
	file:close();
end);

bench.benchmark("Reading a billion ints from Lua", 1, function()
	local file		= io.open("c_data.dat", "rb");
	local reader 	= format.reader(file);
	
	local read_32  = reader.varint;
	for i=1, 10^7 do
		read_32(reader);
	end
	
	file:close();
end);