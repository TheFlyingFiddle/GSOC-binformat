local util = {} 

local function checkcallable(func, tname, fname)
	local typ = type(func)
	if typ == "function" then 
		return 
	elseif (typ == "table" or typ == "userdata") and func.__call then
		return 
	else
		assert(false, tname .. " missing a method " .. fname)
	end
end

function util.isinputstream(stream)
	assert(stream)
	checkcallable(stream.read, "inputstream", "read")
	checkcallable(stream.close, "inputstream", "close")
end

function util.isoutputstream(stream)
	assert(stream)
	checkcallable(stream.write, "outputstream", "write")
	checkcallable(stream.flush, "outputstream", "flush")
	checkcallable(stream.close, "outputstream", "close")
end

function util.ismapping(mapping)
	local typ = type(mapping)
	assert(typ == "table" or typ == "userdata", "mapping expected")
	assert(mapping.tag, "mapping missing field tag")
	assert(type(mapping.tag) == "number", "mapping.tag must be a number")
	checkcallable(mapping.encode, "mapping", "encode")
	checkcallable(mapping.decode, "mapping", "decode")
end

return util