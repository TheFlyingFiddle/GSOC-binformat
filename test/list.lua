local IntListCases =
{
	{ actual = { } },
	{ actual = {0} } , 
	{ actual = {0, 1} },
	{ actual = {0,1, 2} }, 
	{ actual = {0, 1, 2, 3} },
	{ actual = {0, 1, 2, 3, 4} },
	{ actual = {12412, 123512, 66513, 98213, 1235} } ,
	{ actual = {0,0,0,0,0,1,1,1,1,1,11,1,1,1,1,1,11,1,1,1,1,1,11,1,1,1,1,1,1,1,1,1} }
}

local WrongElementTypeCases = 
{
	{ actual = {"A", "B", "C", "D", "E"} },
	{ actual = { false, true, true, true, true } },
	{ actual = { {}, {}, {}, {}, {} } },
	{ actual = { print, print, print, print, print } },
	{ actual = { function() end, function() end, function() end, 
				 function() end, function() end} },
	{ actual = { coroutine.running(), coroutine.running(),
				 coroutine.running(), coroutine.running(),coroutine.running() } },
	{ actual = { io.stdout, io.stdout,io.stdout,io.stdout,io.stdout} }
}

local NonListCases = 
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
	{ actual = { {}, {0}, {0,0}, {0,0,0}, {0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0,0} } },
	{ actual = { {0,0, 9}, {1}, {2,2, 3, 4, 1}, {}, {134} } },
	{ actual = { {123,123}, {321,312}, {12354, 12354}, {512351, 512351}, {31551, 31515} } },
	{ actual = { {0,1,1,1,1,1,1,0}, {0,0}, {0,0}, {0,0}, {0,0} } }
}

runtest { 
	mapping = standard.list(primitive.varint),
	IntListCases
} 

runtest {
	mapping = standard.list(primitive.varint),  encodeerror = "number expected",
	WrongElementTypeCases
}

runtest {
	mapping = standard.list(primitive.varint), encodeerror = "attempt to get length",
	NonListCases
}

runtest {
	mapping = standard.list(standard.list(primitive.varint)),
	ComposedCases
}