local SimpleLuaCases = 
{
	{ actual = 18723.0 },
	{ actual = "The Dynamic Lua World" },
	{ actual = true, id = "Dynamic_True" },
	{ actual = false, id = "Dynamic_False"},
	{ actual = nil, id = "Dynamic Nil" },
	{ actual = { }, id = "Dynamic Empty List"},
	{ actual = function() end, "Dynamic function" }
}

local ComplexLuaCases =
{
	{ 
		actual = 
		{
			number = 1234,
			text   = "Complex Dynamic",
			flag   = true,
			inner  = { a = 312, b = "Cool",	c = false }
	  	} 
	}
}



--Functions/Threads and Userdata is not valid dynamic stuff. 
local IllegalLuaCases =
{
	{ actual = print },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
	{ actual = { io.stdout }}
}

runtest { mapping = standard.dynamic, SimpleLuaCases  }
runtest { mapping = standard.dynamic, ComplexLuaCases } 
runtest { mapping = standard.dynamic, encodeerror = "any" , IllegalLuaCases }