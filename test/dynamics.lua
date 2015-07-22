--This module was very usefull in testing
--Migration from the old dynamic implementation to 
--the new one. However it is no longer needed.
--I am leaving the code here uncommented incase 
--I ever feel like updating the dynamic code yet again.

--[[
local tier  = require"tier"
local standard  = tier.standard
local primitive = tier.primitive
local display   = require"test.user_display"
local format    = require"format"
local parser	= require"tier.parser"
local Matcher   = require "loop.debug.Matcher"

local dynamic = standard.dynamic

local function assertmatch(recovered, expected)
	local matcher = Matcher({})
	local ok, errmsg = matcher:match(recovered, expected)
	if not ok then 
		print(recovered, expected) 
	end
	assert(ok, errmsg)
end

local is_debuging = true

local function comp_dynamic(value, manual_mapping)
	local dyn_stream	 = format.outmemorystream()
	local new_dyn_stream = format.outmemorystream()
	local manual_stream    = format.outmemorystream()
	

	tier.encode(dyn_stream, value)	
	tier.encode(new_dyn_stream, value, dynamic)
	tier.encode(manual_stream, value, manual_mapping)
	
	local data     	   = dyn_stream:getdata()
	local new_data 	   = new_dyn_stream:getdata()
	local manual_data    = manual_stream:getdata()
		
	local dyn_in  = format.inmemorystream(	   data)
	local ndyn_in = format.inmemorystream( new_data)
	local manual_in = format.inmemorystream(manual_data)
	
	--assertmatch(tier.decode(dyn_in), value)
	assertmatch(tier.decode(ndyn_in, dynamic), value)
	assertmatch(tier.decode(manual_in, manual_mapping), value)
	local is_larger = #new_data > #data
	if is_debuging or is_larger then	
		print("\nStream size <manual : new : old> | " .. #manual_data .. " : " 
											 .. #new_data    .. " : " .. 
											    #data .. " |")
												
		--local mapping = dynamic.handler:getmappingof(value)
		--local id 	  = tier.getid(mapping)
		--print(parser.idtodebugid(id))
				
		print("Manual data:")
		display.hexastream(io.stdout, manual_data)
		
		print("\nNew data")
		display.hexastream(io.stdout, new_data)
		
		print("\nOld data:") 
		display.hexastream(io.stdout, data) 
		print()
		
		assert(is_larger == false, "new dynamic mapping creates larger stream!")
	end
end

local data = { }
--Should be OBJECT ARRAY VOID
comp_dynamic(data, standard.list(primitive.uint8))

local data = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
--Should be OBJECT LIST UINT8
comp_dynamic(data, standard.list(primitive.uint8))

local data = { { 1, 2, 3}, { 4, 5, 6}, { 10, 13, 3}, { 7, 8, 9} }
--Should be OBJECT LIST TUPLE UINT8 UINT8 UINT8
comp_dynamic(data, standard.list(standard.list(primitive.uint8)))

local data = { {1, 2, 3, 4}, { 5, 6, 7}, { 8, 9 }, {10}, { } }

--Should be OBJECT LIST DYNAMIC
comp_dynamic(data, standard.list(standard.list(primitive.uint8)))

local data = { { 1, 2, "dance", 4}, { 5, 6}, { "hello"}, { 7, 8, 9} }
--Should be OBJECT LIST DYNAMIC
comp_dynamic(data, standard.list(standard.list(standard.union
								 {
								 	{ type = "number", mapping = primitive.uint8 },
									{ type = "string", mapping = primitive.stream } 
								 })))

local data = { {1, 2000, "hi"}, { 0xffff, 2, "lo"}, {6, 0xfff, "mid"} }
--Should be OBJECT LIST TUPLE UINT16 UINT16 STREAM
comp_dynamic(data, standard.list(standard.tuple
								 {
									 { mapping = primitive.uint32 },
									 { mapping = primitive.uint32 },
									 { mapping = primitive.stream }
								 }))
local data = 
{	 
	a = 12, 
	b = "we", 
	c = true, 
	d = 
	{
		a = 12,
		b = "we",
		c = true,	
	}
}

local mapping = standard.tuple
{
	{ key = "a", mapping = primitive.uint8 },
	{ key = "b", mapping = primitive.stream },
	{ key = "c", mapping = primitive.boolean },
	{ key = "d", mapping = standard.tuple
				 {
					 { key = "a", mapping = primitive.uint8   },
					 { key = "b", mapping = primitive.stream },
					 { key = "c", mapping = primitive.boolean}
				 }}
}

--Should be OBJECT MAP STREAM DYNAMIC
comp_dynamic(data, mapping)

--Cyclic data :O
local data = { 1 }
data[2] = { 2, { 3, data } } 
local mapping = standard.selfref(function(ref)
	return standard.object(standard.tuple
	{
		{ ["mapping"] = primitive.uint32 },
		{ ["mapping"] = ref}
	})
end)

--Tuples are as we know recursive (should they be?) maybe not
comp_dynamic(data, mapping)

local data 	  = 
{ 
	[1] = true, 
	[0xFF] = true,
	[0x100] = true,
	[0xFFFF] = true,  
	[0x10000] = true, 
	[0xFFFFFFFF] = true 
}

local mapping = standard.set(primitive.uint32)
comp_dynamic(data, mapping)

local data 	   =
{
	[{1,  "lo"}] = true,
	[{0xFF, "hi"}] = true,
	[{0x100, "lo"}] = true,
	[{0xFFFF, "hi"}] = true,
	[{0x10000, "lo"}] = true,
	[{0xFFFFFFFF, "hi"}] = true
}

local setmapping = standard.set(standard.tuple
{
	{ mapping = primitive.uint32 },
	{ mapping = primitive.stream }
})

comp_dynamic(data, setmapping)

local data = 
{
	a = 0x01,
	b = 0xff,
	c = 0x100,
	d = 0xffff,
	e = 0x10000,
	f = 0xFFFFFFFF
}

local mapping = standard.map(primitive.stream, primitive.uint32)
comp_dynamic(data, mapping)

local data = 
{
	a = { 1, 2, { 3, 4} },
	b = { 3, 3, { 5, "lo"} },
	c = { 5, 1, { 51, 13} },
	d = { 14, 12, { 31, "hi"} }
}

local mapping = standard.map(primitive.stream, standard.tuple
{
	{ mapping = primitive.uint8 },
	{ mapping = primitive.uint8 },
	{ mapping = standard.tuple 
				{
					{ mapping = primitive.uint8 },
					{ mapping = standard.union
								{
									{ type = "string", mapping = primitive.stream },
									{ type = "number", mapping = primitive.uint8  }
								} 
					}
				} 
	}
})

comp_dynamic(data, mapping)]]--