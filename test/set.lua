local IntSetCases =
{
	{ actual = { } },
	{ actual = { [0] = true } },
	{ actual = { [5] = true, [1] = true} },
	{ actual = { [0] = true, [9] = true, [2] = true, [3] = true } }, 
	{ actual = { [123] = true, [1692] = true, [3132] = true } }
}

local NonSetCases = 
{
	{ actual = 1 },
	{ actual = nil },
	{ actual = false },
	{ actual = true },
	{ actual = print },
	{ actual = function() end },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
}

local ComposedCases = 
{
	{ actual = { [{}] = true,  [{ [0] = true }] = true, [{ [123] = true	}] = true }	},
	{ actual = { [{[3] = true}] = true} }
}

runtest { 
	mapping = standard.set(primitive.varint), 
	noregression = true,
	IntSetCases
} 

runtest {
	mapping = standard.set(standard.set(primitive.varint)),
	noregression = true,
	ComposedCases
}

runtest {
	mapping = standard.set(primitive.varint), encodeerror = "any",
	noregression = true,
	NonSetCases
}