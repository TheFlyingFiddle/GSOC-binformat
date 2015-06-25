--This example aims to emulate the monster example
--from the flatbuffers documentation.
--tuple Vec3
--{
--	float x, y, z;
--}
--
-- Currently enums do not exist. Need to emulate 
-- enum Color 
-- {
--    Red = 0,
--    Green = 1,
--    Blue = 2
-- }
--
--tuple Monster
--{
--	Vec3 pos;
--  sint16 mana;
--  sint16 hp;
--  string name;
--  bool friendly;
--  List(byte) inventory
--  Color color;
--}

local vec3 = standard.tuple(
{
	{ key = "x", mapping = primitive.float },
	{ key = "y", mapping = primitive.float },
	{ key = "z", mapping = primitive.float }		
})

local monster = standard.tuple(
{
	{ key = "pos",  		mapping = vec3 },
	{ key = "mana", 		mapping = primitive.int16 },
	{ key = "hp",   		mapping = primitive.int16 },
	{ key = "name", 		mapping = primitive.string },
	{ key = "friendly",  	mapping = primitive.boolean },
	{ key = "inventory", 	mapping = standard.list(primitive.byte) },
	{ key = "color",		mapping = primitive.byte }	
})

local Color = { Red = 0, Green = 1, Blue = 2 }
local MonsterCases =
{
	{ actual = {
		pos  = { x = 10, y = 15, z = 10 },
		mana = 150,
		hp   = 100,
		name = "Oger",
		friendly = false,
		inventory = { 0, 3, 12, 51, 42, 81, 44, 28, 15, 92, 123 },
		color    = Color.Blue --Blue
	}},
	{
		actual = {
		pos  = { x = 15, y = 25, z = 31 },
		mana = 15,
		hp   = 10,
		name = "Imp",
		friendly = true,
		inventory = { 0, 3, 12 },
		color    = Color.Blue --Blue
	}}
}

runtest { nodynamic = true, mapping = monster, MonsterCases}