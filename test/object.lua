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
		{ actual = { nested } , id = "nested object list"},
		{ actual = { nested, nested } , id = "double nested object list"},
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

local ref = standard.typeref()
local o1 = standard.object(standard.list(ref))
local o2 = standard.object(o1)
ref:setref(o2)

local selfref = {}
selfref[1] = selfref

runtest {
        mapping = o2,
        { { actual = selfref, id = "OBJECTx2_LIST_SELFREF" } }
}



do
	local concat = _G.table.concat
	local StringObject = standard.object(standard.list(primitive.char))

	local h = { identify = function (self, value) return concat(value) end }
	local StringValue = custom.object(h, StringObject)

	local t = standard.tuple{
		{ key = "objects", mapping = standard.list(StringObject) },
		{ key = "values", mapping = standard.list(StringValue) },
	}

	local A1 = {"A"}
	local A2 = {"A"}

	runtest{ nodynamic = true,
		mapping = t,
		{
			{
				id = "DISTINCT_NESTED_OBJECTS_2",
				actual = {
					objects = { A1, A2, A1 },
					values = { A1, A2, {"B"} },
				},
				expected = {
					objects = { A1, A2, A1 },
					values = { A1, A1, {"B"} },
				},
			},
		}
	}
end