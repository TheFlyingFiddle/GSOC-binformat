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


local cyclic = { 1 }
cyclic[2] = { 2, { 3, cyclic } } 

local ComplexLuaCases =
{
	{ actual = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10} } ,
	{ actual = { { 1, 2, 3}, { 4, 5, 6}, { 10, 13, 3}, { 7, 8, 9} } },
	{ actual = { {1, 2, 3, 4}, { 5, 6, 7}, { 8, 87 }, {10}, { } } },
	{ actual = { { 1, 2, "dance", 4}, { 5, 6}, { "hello"}, { 7, 8, 9} } },
	{ actual = { {1, 2000, "hi"}, { 0xffff, 2, "lo"}, {6, 0xfff, "mid"} } },
	
	{ 
		actual = 
		{	 
			a = 12, 
			b = "we", 
			c = true, 
			d = 
			{
				a = 12,
				b = "we",
				c = true,	
			}
		} 
	},
	
	{ 
		actual = 
		{ 
			[1] = true, 
			[0xFF] = true,
			[0x100] = true,
			[0xFFFF] = true,  
			[0x10000] = true, 
			[0xFFFFFFFF] = true 
		} 
	},
	
	{ 
		actual =
		{
			[{1,  "lo"}] = true,
			[{0xFF, "hi"}] = true,
			[{0x100, "lo"}] = true,
			[{0xFFFF, "hi"}] = true,
			[{0x10000, "lo"}] = true,
			[{0xFFFFFFFF, "hi"}] = true
		} 
	},
	
	{ 
		actual =
		{
			a = { 1, 2, { 3, 4} },
			b = { 3, 3, { 5, "lo"} },
			c = { 5, 1, { 51, 13} },
			d = { 14, 12, { 31, "hi"} }
		} 
	},
	--{ actual = cyclic }, 
}



--Threads and Userdata is not valid dynamic stuff. 
local IllegalLuaCases =
{
	{ actual = print },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
	{ actual = { io.stdout }}
}

runtest { mapping = standard.dynamic, SimpleLuaCases  }
runtest { mapping = standard.dynamic, noregression = true, ComplexLuaCases } 
runtest { mapping = standard.dynamic, encodeerror = "any" , IllegalLuaCases }