local IntAndStringCases = 
{
	{ actual = { 3551,    "Lifter"  } },
	{ actual = { 3154,    "Greeter" } },
	{ actual = { 3211,    "Dancer"  } }
}

local KeyIntAndStringCases =
{
	{ actual = { id = 3551, role = "Lifter"  } },
	{ actual = { id = 3154, role = "Greeter" } },
	{ actual = { id = 3211, role = "Dancer"  } }
}

local intandstring = standard.tuple
{
	{ mapping = primitive.varint },
	{ mapping = primitive.stream }
}

local keyedintandstring = standard.tuple
{
	{ key = "id",   mapping = primitive.varint },
	{ key = "role", mapping = primitive.stream }
}

runtest { mapping = intandstring, IntAndStringCases }
runtest { mapping = keyedintandstring, KeyIntAndStringCases }

runtest { mapping = intandstring, encodeerror = "any", KeyIntAndStringCases }
runtest { mapping = keyedintandstring, encodeerror = "any", IntAndStringCases }