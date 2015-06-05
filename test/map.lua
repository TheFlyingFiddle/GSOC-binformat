local InttoIntCases =
{
	{ actual = { } },
	{ actual = { 1, 2, 3, 4, 5, 6} },
	{ actual = { [0] = 3, [1] = 2, [321] = 3}},
	{ actual = { [0] = 3, [3] = 0, [123] = 314 } },
	{ actual = { [123] = 2, [123] = 3, [3124] = 5 } }
}

local StringToIntCases = 
{
	{ 
		actual =
		{
			mana   = 150,
			health = 32,
			durability = 322,
			carisma	= 3
		},
	},
	{
		actual =
		{
			foo = 150,
			bar = 32,
			baz = 322,
			buz	= 3
		}
	}
}

local NonMapCases =
{
	{ actual = 1 },
	{ actual = nil },
	{ actual = false },
	{ actual = true },
	{ actual = print },
	{ actual = function() end },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
	{ actual = { 1, 2, 3, 4, 5, 6} }
}


runtest {
	mapping = standard.map(primitive.varint, primitive.varint),
	noregression = true, --The encoding order is random each time.
	InttoIntCases
}

runtest {
	mapping = standard.map(primitive.stream, primitive.varint),
	noregression = true,
	StringToIntCases
}

runtest {
	mapping = standard.map(primitive.stream, primitive.varint), encodeerror = "any",
	noregression = true,
	NonMapCases
}
