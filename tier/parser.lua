local format   = require"format"
local tags 	   = require"tier.tags"

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
local UINT		= tags.UINT
local SINT		= tags.SINT

local ALIGN		= tags.ALIGN
local ALIGN1	= tags.ALIGN1
local ALIGN2	= tags.ALIGN2
local ALIGN4	= tags.ALIGN4
local ALIGN8	= tags.ALIGN8

local parser = { }

local unpackvar = format.unpackvarint
local function parsenode(metastring, index)
	local tag  = unpackvar(string.sub(metastring, index, index))
	
	local node = { }
	node.tag   = tag
	node.sindex = index
	
	local children = 0;	
	if tag == LIST 	   or tag == ARRAY    or 
	   tag == SET  	   or tag == OBJECT   or
	   tag == EMBEDDED or tag == SEMANTIC or 
	   tag == ALIGN	   or tag == ALIGN1   or
	   tag == ALIGN2   or tag == ALIGN4  or
	   tag == ALIGN8 then
	   children = 1
	elseif tag == MAP then
		children = 2
	end
		
	if tag == ARRAY   or tag == TUPLE or 
	   tag == TYPEREF or tag == ALIGN or
	   tag == UINT	  or tag == SINT then
		local size, off = unpackvar(string.sub(metastring, index + 1))
		index 	 	= index + off
		
		if tag == TYPEREF then
			node.offset = size
		else
			node.size = size
		end		
		
		if tag == TUPLE then
			children = size
		end
	elseif tag == LIST or tag == SET or
		   tag == MAP  or tag == UNION then 
		local size, off = unpackvar(string.sub(metastring, index + 1))
		index 	= index + off
		node.bitsize = size		
		
		if tag == UNION then
			size, off = unpackvar(string.sub(metastring, index + 1))
			index = index + off
			node.size = size
			children = size
		end
	elseif tag == SEMANTIC then
		local size, off = unpackvar(string.sub(metastring, index + 1))
		index 	= index + off
		node.identifier = string.sub(metastring, index + 1, index + size)		
		index   = index + size
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

function parser.parsemetatype(metatype)
	assert(type(metatype) == "string", "expected binary metatype string")
	local parsetree =
	{
		rep  = metatype,
		root = parsenode(metatype, 1) 
	}
	return parsetree
end


local function debugtype(node, level)
	local spacing = ""
	for i=1, level do
		spacing = spacing .. " "
	end	
	
	local id = spacing .. tags[node.tag]
	for i=1, #node do
		id = id .. "\n" .. spacing .. " " .. debugtype(node[i], level + 1)
	end
	
	return id
end

function parser.idtodebugid(id)
	local metatype = string.sub(id, 1, 1) .. string.sub(id, 3)
	local pt = parser.parsemetatype(metatype)
	return debugtype(pt.root, 0)
end

return parser