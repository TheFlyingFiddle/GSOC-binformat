local NilCases = {
	{ actual = nil },
}
local NonNilCases = {
	{ actual = false },
	{ actual = true },
	{ actual = 0 },
	{ actual = 1 },
	{ actual = "text" },
	{ actual = {} },
	{ actual = print },
	{ actual = function () end },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
}

runtest{ mapping = primitive.void, countexpected = 0,
	NilCases,
}

runtest{ mapping = primitive.null,
	NilCases,
}
runtest{ mapping = primitive.null, encodeerror = "nil expected",
	NonNilCases,
}

local mapping = standard.optional(primitive.void)
runtest{ mapping = mapping, NilCases, }

--I am unsure about this. How do I do this correctly?
runtest{ nodynamic = true, mapping = mapping, countexpected = 0, NonNilCases, }
