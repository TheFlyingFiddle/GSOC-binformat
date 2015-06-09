local EmbeddedInt = standard.embedded(primitive.varint)
local IntCases =
{
	{ actual = 1 , id = "Embedded_1"},
	{ actual = 13518274 }
}

local listref 	  = custom.typeref()
local listmapping = standard.nullable(standard.tuple(
{
	{ mapping = primitive.varint },
	{ mapping = listref } 
}))
listref:setref(listmapping)

local EmbeddedList = standard.embedded(listmapping)
local ListCases =
{
	{ actual = { 61 } },
	{ actual = { 1, { 2 } } },
	{ actual = { 1, { 2, { 3 }}}}
}

runtest { mapping = EmbeddedList, ListCases }
runtest { mapping = EmbeddedInt, IntCases }