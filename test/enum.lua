local GoodHeadingCases = 
{
	{ actual = "NORTH" },
	{ actual = "EAST"  },
	{ actual = "WEST"  },
	{ actual = "SOUTH" }
}

local BadHeadingCases =
{
	{ actual = "DOWN"}
}

local NonStringHeadingCases = 
{
	{ actual = nil},
	{ actual = false },
	{ actual = true},
	{ actual = function() end },
	{ actual = 19371 },	
	{ actual = "string" },
	{ actual = print },
	{ actual = coroutine.running() },
	{ actual = io.stdout }
}

local heading = standard.enum("heading", { NORTH = 1, EAST = 2, WEST = 3, SOUTH = 4}, primitive.uint8)
standard.generator:register_mapping(heading)

runtest {
	mapping = heading,
	GoodHeadingCases,
}

runtest {
	mapping = heading,
	encodeerror = "no enum id for",
	BadHeadingCases
}

runtest {
	mapping = heading,
	encodeerror = "any",
	NonStringHeadingCases,
}

local Types = 
{
	{ id = "Point2D", size = 8 },
	{ id = "int32",	  size = 4 },
	{ id = "Customer", size = 32}
}

local typeenum = standard.enum("types", {[Types[1]] = 1, [Types[2]] = 23, [Types[3]] = 3}, primitive.uint8)
standard.generator:register_mapping(typeenum)

local GoodTypeCases = 
{
	{ actual = Types[1] },
	{ actual = Types[2] },
	{ actual = Types[3] },
}

local BadTypeCases =
{
	{ actual = { id = "float", size = 4} },
}

runtest {
	mapping = typeenum,
	GoodTypeCases
}

runtest { 
	mapping = typeenum,
	encodeerror = "any",
	BadTypeCases
}