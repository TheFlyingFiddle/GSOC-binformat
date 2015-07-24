local GoodCases = 
{
	{ actual = "hi" },
	{ actual = "lo" },
	{ actual = "fi" },
	{ actual = "fo" }
}

local BadCases = 
{
	{ actual = "a" },
	{ actual = "aaa"}
}

local NonTextualCases = {
	{ actual = nil },
	{ actual = false },
	{ actual = true },
	{ actual = {} },
	{ actual = print },
	{ actual = function () end },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
}

local bytearray = standard.semantic("bytearray", standard.bytearray(2))
standard.generator:register_mapping(bytearray)

runtest { 
	mapping = bytearray,
	GoodCases
}

runtest {
	mapping = bytearray,
	encodeerror = "string has the wrong length",
	BadCases
}

runtest {
	mapping = bytearray,
	encodeerror = "string expected",
	NonTextualCases
}