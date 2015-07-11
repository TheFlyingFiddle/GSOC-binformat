runtest { 
	mapping = standard.list(standard.object(primitive.boolean)),
	{ { actual = { true, false, true } } },
}



local table = {}

runtest { 
	mapping = standard.list(standard.object(standard.list(primitive.varint))),
	{ { actual = { {}, table, table } } },
}



local ref = custom.typeref()
local list = standard.list(standard.object(ref))
ref:setref(list)

local nested = {}
nested[1] = nested

runtest { 
	mapping = list,
	{
		{ actual = { nested } },
		{ actual = { nested, nested } },
	},
}


runtest { 
	mapping = standard.dynamic,
	{
		{ actual = nested },
		{ actual = { nested, nested } },
	},
}


runtest { 
	mapping = standard.object(list),
	{
		{ actual = nested, expected = { nested } },
		{ actual = { nested, nested } },
	},
}


runtest { 
	mapping = standard.object(standard.object(standard.list(primitive.varint))),
	{
		{ actual = { 1,2,3 } },
	},
}


runtest {
	mapping = standard.list(standard.object(standard.dynamic)),
	{
		{ actual = { 1,2,3 }, id = "OBJECT_DYNAMIC_1_2_3", },
		{ actual = { nested }, id = "OBJECT_DYNAMIC_NESTED" },
		{ actual = { nested, nested }, id = "OBJECT_DYNAMIC_NESTED_NESTED" },
	},
}


local list = { 1,2,3 }
runtest {
	mapping = standard.list(
	          	standard.object(
	          		standard.optional(
	          			standard.list(
	          				primitive.varint)))),
	{
		{ actual = { list, nil, list }, id = "OBJECT_NULLABLE_LISTS", },
	},
}
