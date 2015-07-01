local util = {} 

local function checkcallable(func, tname, fname)
	local typ = type(func)
	if typ == "function" then 
		return true
	elseif (typ == "table" or typ == "userdata") and func.__call then
		return true
	else
		return false, tname .. " missing a method " .. fname
	end
end

function util.isinputstream(stream)
	local typ = type(stream)
	if  typ ~= "table" and typ ~= "userdata" then 
	    return false, "input stream expected got " .. typ 
	end
    	
	local sucess, err = checkcallable(stream.read, "inputstream", "read")
	if not sucess then return false, err end
	
	sucess, err = checkcallable(stream.close, "inputstream", "close")
	if not sucess then return false, err end
	
	return true
end

function util.isoutputstream(stream)
	local typ = type(stream)
	if typ ~= "table" and typ ~= "userdata" then 
	    return false, "outputstream expected got " .. typ 
	end
    	
	local sucess, err = checkcallable(stream.write, "outputstream", "write")
	if not sucess then return false, err end
	
	sucess, err = checkcallable(stream.flush, "outputstream", "flush")
	if not sucess then return false, err end
	
	sucess, err = checkcallable(stream.close, "outputstream", "close")
	if not sucess then return false, err end
	
	return true
end

function util.ismapping(mapping)
	local typ = type(mapping)
	if typ ~= "table" and typ ~= "userdata" then
		return false, "mapping expected got " .. typ
	end
		
	if type(mapping.tag) ~= "number" then
		return false, "mapping.tag must be a number not " .. type(mapping.tag)
	end
	
	local sucess, err = checkcallable(mapping.encode, "mapping", "encode")
	if not sucess then return false, err end
	
	
	sucess, err = checkcallable(mapping.encode, "mapping", "decode")
	if not sucess then return false, err end
	
	return true
end

return util