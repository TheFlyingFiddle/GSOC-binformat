local encoding = require"encoding"
local format   = require"format"
local tags = encoding.tags

local LIST  	= tags.LIST
local SET   	= tags.SET
local OBJECT 	= tags.OBJECT
local ARRAY 	= tags.ARRAY
local EMBEDDED  = tags.EMBEDDED
local SEMANTIC  = tags.SEMANTIC
local MAP 		= tags.MAP
local TUPLE     = tags.TUPLE
local UNION     = tags.UNION
local TYPEREF   = tags.TYPEREF

local parser = { }
local function parsenode(metastring, index)
	local tag  = string.sub(metastring, index, index)
	local node = { }
	node.tag   = tag
	node.sindex = index
	
	local children = 0;
	if tag == LIST 	   or tag == ARRAY  or 
	   tag == SET  	   or tag == OBJECT or
	   tag == EMBEDDED or tag == SEMANTIC then
	   children = 1
	elseif tag == MAP then
		children = 2
	end
		
	if tag == ARRAY 	or tag == TUPLE or 
	   tag == UNION 	or tag == TYPEREF or 
	   tag == SEMANTIC then
		local size, off = format.unpackvarint(string.sub(metastring, index + 1))
		index 	 	= index + off
	 
	    if tag == TYPEREF then
			node.offset = size + 1
		elseif tag == SEMANTIC then
			node.id = string.sub(metastring, index, index + size)
			index   = index + size
		else
			node.size	= size
		end
			
		if tag == UNION or tag == TUPLE then
			children = size
		end 
	end
	
	index = index + 1
	for i=1, children do
		local child = parsenode(metastring, index)
		index = child.eindex + 1
		node[i] = child
	end	
	
	node.eindex = index - 1;
	return node		
end

local function tometatype(str)
	local rep = { }
	local iter = string.gmatch(str, "%S+")
	while true do
		local w = iter()
		if not w then break end	
		local u = string.upper(w)
		local tag = tags[u]
		if not tag then
			error(u .. " is not a valid tag!")
		end
		
		table.insert(rep, tag)
		if tag == ARRAY or tag == TUPLE   or 
		   tag == UNION or tag == TYPEREF then 
			local n = tonumber(iter())
			table.insert(rep, format.packvarint(n))
		elseif tag == SEMANTIC then
			local id = iter()
			table.insert(rep, format.packvarint(#id))
			table.insert(rep, id)
		end											
	end
		
	return table.concat(rep)
end

function parser.parsestring(str)
	local metastr = tometatype(str)
	return parser.parsemetatype(metastr)
end

function parser.parsemetatype(metatype)
	assert(type(metatype) == "string", "expected binary metatype string")
	local parsetree =
	{
		rep  = metatype,
		root = parsenode(metatype, 1) 
	}
	return parsetree
end

return parser