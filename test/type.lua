local PrimitiveCases = { }
for k,v in pairs(primitive) do 
	table.insert(PrimitiveCases, { actual = v })
end
table.sort(PrimitiveCases, function(a,b) return a.actual.tag < b.actual.tag end)


local SimpleComposedCases = 
{
	{ actual = standard.array(primitive.varint, 5) },
	{ actual = standard.list(primitive.varint) },
	{ actual = standard.set(primitive.varint) },
	{ actual = standard.map(primitive.varint, primitive.varint) },
	{ actual = standard.nullable(primitive.varint) },
	{ actual = standard.tuple(primitive.varint, primitive.stream, primitive.boolean) },
}

local AlignCases = 
{
	{ actual = custom.align(1, primitive.varint) },
	{ actual = custom.align(2, primitive.varint) },
	{ actual = custom.align(3, primitive.varint) },
	{ actual = custom.align(4, primitive.varint) },
	{ actual = custom.align(8, primitive.varint) },
}

local ObjectCases =
{
	{ actual = standard.object(primitive.varint)   },
}

local SemanticCases = 
{
	{ actual = custom.semantic("test", primitive.varint) },
	{ actual = custom.semantic("color", primitive.uint32)}
}

local newtyperef = custom.typeref

local listref = newtyperef()
local linkedlist = standard.tuple
{
	{ mapping = primitive.varint },
	{ mapping = standard.nullable(listref) }
}
listref:setref(linkedlist)

local luaref   = newtyperef()
local luaunion = standard.union
{
	{ type = "nil", 	mapping = primitive.null },
	{ type = "number", 	mapping = primitive.fpdouble },
	{ type = "boolean", mapping = primitive.boolean },
	{ type = "string",	mapping = primitive.string },
	{ type = "table",   mapping = standard.object(standard.map(luaref, luaref)) }
}
luaref:setref(luaunion)


local noderef = newtyperef()
local node = standard.nullable(standard.tuple(
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
	{ actual = linkedlist },
	{ actual = luaunion },
	{ actual = node },
	{ actual = treemapping }	
}

local function idmatcher(actual, expected)
	local aid = encoding.getid(actual)
	local eid = encoding.getid(expected)
	if aid == eid then return true end
	
	return false, "metadata mismatch"		
end

runtest { mapping = standard.type, noregression = true, PrimitiveCases }
runtest { mapping = standard.type, matcher = idmatcher, SimpleComposedCases }
runtest { mapping = standard.type, matcher = idmatcher, AlignCases }
runtest { mapping = standard.type, matcher = idmatcher, ObjectCases }
runtest { mapping = standard.type, matcher = idmatcher, SemanticCases }
runtest { mapping = standard.type, matcher = idmatcher, TyperefCases }