--This is a premptive module incase bimaps are ever implemented.
--That is it should be interpreted as a bimap but encoded as a normal MAP
--SEMANTIC "bimap" MAP K V

--[[local GoodCases =
{
	{ actual = { [1] = "hi", hi = 1 } },
	{ actual = { [true] = 1, [false] = 0, [0] = false, [1] = true} },
	{ actual = { [10] = 5, [5] = 10, [145] = 23, [23] = 145 } },
	{ actual = 	{ a = "t", t = "a", c = "g", g = "c", 
	  			  A = "T", T = "A", C = "G", G = "C" } }
}

local NonMapCasese = 
{
	{ actual = nil },
	{ actual = 19253 },
	{ actual = "string" },
	{ actual = function() end },
	{ actual = print },
	{ actual = coroutine.running() },
	{ actual = io.stdout }
}

local BadCases = 
{
	{ actual = { [1] = "hi" } },
	{ actual = { [1] = "hi", hi = 2} },
	{ actual = { [10] = 5, [5] = 11} },
}

runtest {
	mapping = standard.bimap(standard.dynamic, standard.dynamic),
	GoodCases
}

runtest {
	mapping = standard.bimap(standard.dynamic, standard.dynamic),
	NonMapCasese
}

runtest {
	mapping = standard.bimap(standard.dynamic, standard.dynamic),
	BadCases
}--]]