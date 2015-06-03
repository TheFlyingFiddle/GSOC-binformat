local BoolCases = {
	{ actual = nil                , expected = false },
	{ actual = false                                 },
	{ actual = true                                  },
	{ actual = 0                  , expected = true  },
	{ actual = 1                  , expected = true  },
	{ actual = "text"             , expected = true  },
	{ actual = {}                 , expected = true  },
	{ actual = print              , expected = true  },
	{ actual = function() end     , expected = true  },
	{ actual = coroutine.running(), expected = true  },
	{ actual = io.stdout          , expected = true  },
}

local SignCases =
{
	{ actual = true,  expected = 1},
	{ actual = false, expected = -1	},
	{ actual = 1,     expected = 1 },
	{ actual = -1,    expected = -1 }
}

local FlagCases =
{
	{ actual = true,  expected = 1},
	{ actual = false, expected = 0},
	{ actual = 1,     expected = 1},
	{ actual = 0,     expected = 0}
}


runtest{ mapping = primitive.boolean, BoolCases }
runtest{ mapping = primitive.sign, SignCases }
runtest{ mapping = primitive.flag, FlagCases }