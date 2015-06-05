local NumberOrNilCases =
{
	{actual = 1   },
	{actual = nil }
}

local NoNumberOrNilCases =
{
	{ actual = "A" },
	{ actual = true },
	{ actual = { }  }
}

local LuaValueCases =  
{
	{ actual = 1   	 },
	{ actual = true  },
	{ actual = false },
	{ actual = "A"   },
	{ actual = { }   },
	{ actual = { "A", "B", "C" } }
}

local NonStandardUnionCases = 
{
	{ actual = print },
	{ actual = function() end },
	{ actual = coroutine.running() },
	{ actual = io.stdout }	
}

local NumberOrList = 
{
	{ actual = 1 },
	{ actual = { 0, 1, 2, 3, 4, 5 } }
}


local intornil = standard.union
{
	{ type = "number", mapping = primitive.fpdouble },
	{ type = "nil",    mapping = primitive.null }
}

local numberorlist = standard.union
{
	{ type = "number", mapping = primitive.varint },
	{ type = "table",  mapping = standard.list(primitive.varint) }
}


local luaref   = custom.typeref()
local luaunion = standard.union
{
	{ type = "nil", 	mapping = primitive.null },
	{ type = "number", 	mapping = primitive.fpdouble },
	{ type = "boolean", mapping = primitive.boolean },
	{ type = "string",	mapping = primitive.string },
	{ type = "table",   mapping = standard.object(standard.map(luaref, luaref)) }
}
luaref:setref(luaunion)


runtest { mapping = intornil, IntOrNilCases }
runtest { mapping = intornil, encodeerror = "any", NoNumberOrNilCases }

runtest { mapping = numberorlist, NumberOrList }

runtest { mapping = luaunion, LuaValueCases}
runtest { mapping = luaunion, encodeerror = "any", NonStandardUnionCases }