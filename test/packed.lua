local colormapper5551 = standard.tuple
{
	{ mapping = primitive.uint5},
	{ mapping = primitive.uint5},
	{ mapping = primitive.uint5},
	{ mapping = primitive.uint1}
}

local Colors = 
{
	{  actual = { 15, 12, 2, 1 } },
	{  actual = { 31, 31, 31, 1} },
	{  actual = { 31, 31, 31, 0} },
	{  actual = { 0, 0, 0, 1} },
	{  actual = { 0, 0, 0, 0} },
}

--[[
Emulate a C++ struct
struct A
{
	uint32_t first;
	uint8_t  second; --Will be some invisible padding here. 
	uint32_t third;
}

]]--

local cstructmapper = standard.tuple
{
	{ mapping = custom.align(4, primitive.uint32) },
	{ mapping = primitive.uint8 },
	{ mapping = custom.align(4, primitive.uint32)}
}

local StructCases = 
{
	{ actual = { 0xFFFFFFFF, 0xFF, 0xFFFFFFFF} } ,
	{ actual = { 0, 0, 0} } ,
	{ actual = { 0x33333333, 0x33, 0x33333333} } 
}

runtest { mapping = cstructmapper, StructCases}
runtest { mapping = colormapper5551, Colors } 