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

runtest{ mapping = primitive.bit, BoolCases }
runtest{ mapping = primitive.boolean, BoolCases }
