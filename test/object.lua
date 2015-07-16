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


local old_dynamic do
	local lua2tag = 
	{
		["nil"]      = primitive.null,
		["boolean"]  = primitive.boolean,
		["number"]   = primitive.double,
		["string"]   = primitive.string,
		["function"] = nil,
		["thread"]   = nil,
		["userdata"] = nil,
	}

	function lua2tag:getmappingof(value)
	    return self[type(value)] or error("no mapping for value of type " .. type(value))
	end

	old_dynamic = custom.dynamic(lua2tag, standard.type)
	lua2tag["table"] = standard.object(standard.map(old_dynamic, old_dynamic)) 
end

runtest { 
	mapping = old_dynamic,
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
	mapping = standard.list(standard.object(old_dynamic)),
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
