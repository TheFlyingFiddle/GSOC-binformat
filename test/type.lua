local PrimitiveCases = { }
for k,v in pairs(primitive) do 
	if k ~= "dynamic" then 
		table.insert(PrimitiveCases, { actual = v , id = "primitive" .. k })
	end 
end
table.sort(PrimitiveCases, function(a,b) return a.actual.meta.tag < b.actual.meta.tag end)


local SimpleComposedCases = 
{
	{ actual = standard.array(primitive.varint, 5) , id = "standard_array"},
	{ actual = standard.list(primitive.varint),      id = "standerd_list" },  
	{ actual = standard.set(primitive.varint),		 id = "standard_set"},
	{ actual = standard.map(primitive.varint, primitive.varint), id = "standard_map" },
	{ actual = standard.optional(primitive.varint), id = "standard_optional" },
	{ actual = standard.tuple(primitive.varint, primitive.stream, primitive.boolean), id = "standard_tuple" },
}

local AlignCases = 
{
	{ actual = custom.align(1, primitive.varint), id = "type_align_1" },
	{ actual = custom.align(2, primitive.varint), id = "type_align_2"},
	{ actual = custom.align(3, primitive.varint), id = "type_align_3" },
	{ actual = custom.align(4, primitive.varint), id = "type_align_4"},
	{ actual = custom.align(8, primitive.varint), id = "type_align_8" },
}

local ObjectCases =
{
	{ actual = standard.object(primitive.varint)   },
}

local SemanticCases = 
{
	--{ actual = custom.semantic("test", primitive.varint) },
	--{ actual = custom.semantic("color", primitive.uint32)}
}

local newtyperef = custom.typeref

local listref = newtyperef()
local linkedlist = standard.tuple
{
	{ mapping = primitive.varint },
	{ mapping = standard.optional(listref) }
}
listref:setref(linkedlist)

local luaref   = newtyperef()
local luaunion = standard.union
{
	{ type = "nil", 	mapping = primitive.null },
	{ type = "number", 	mapping = primitive.double },
	{ type = "boolean", mapping = primitive.boolean },
	{ type = "string",	mapping = primitive.string },
	{ type = "table",   mapping = standard.object(standard.map(luaref, luaref)) }
}
luaref:setref(luaunion)


local noderef = newtyperef()
local node = standard.optional(standard.tuple(
{
	{ mapping = primitive.varint },
	{ mapping = noderef },
	{ mapping = noderef }
}))
noderef:setref(node)

local treemapping = standard.tuple(
{
	{ mapping = primitive.varint },
	{ mapping = node}
})


local TyperefCases = 
{
	{ actual = linkedlist, 	 id = "linked lists" },
	{ actual = node , 		 id = "treenode"},
	{ actual = treemapping , id = "tree"},
	{ actual = luaunion, 	 id = "luaunion" },
}

local meta = require"tier.meta"

local function idmatcher(actual, expected)
	local aid = meta.getid(actual.meta)
	local eid = meta.getid(expected.meta)
	if aid == eid then return true end
	
	return false, "metadata mismatch"		
end

runtest { mapping = standard.type, matcher = idmatcher, SemanticCases }
runtest { mapping = standard.type, noregression = true, PrimitiveCases }
runtest { mapping = standard.type, matcher = idmatcher, SimpleComposedCases }
runtest { mapping = standard.type, matcher = idmatcher, AlignCases }
runtest { mapping = standard.type, matcher = idmatcher, ObjectCases }
runtest { mapping = standard.type, matcher = idmatcher, TyperefCases }