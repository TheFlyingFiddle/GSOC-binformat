local generating = require"encoding.generating"
local parser  	= require"encoding.parser"
local testing 	= require"tests.testing"


local tree      = parser.parsestring"TUPLE 03 VARINT STRING BIT"
local generator = generating.generator()
local mapping   = generator:fromtype(tree)

local data = { 1, "Hello", true }
testing.testmapping(data, mapping)

--Convinience of having generator generate code from a string.
--Removes the need to create generator object
local mapping = generating.fromstring"TUPLE 03 VARINT STRING BIT"
testing.testmapping(data, mapping)

--Simaraly avoiding having to parse explicitly
local mapping = generator:fromstring"TUPLE 03 VARINT STRING BIT"
testing.testmapping(data, mapping)


--Lua type serialization
local generator = generating.generator()
local mapping = generator:fromstring
[[
	UNION 05
		VOID
		DOUBLE
		BOOLEAN
		STRING
		OBJECT 
			MAP
				TYPEREF 07
				TYPEREF 09
]]

local data = 
{
	flag = true,
	number = 123.45,
	text   = "Lua 5.1",
	list   =
	{
		[1] = "A",
		[2] = "B",
		[3] = "C"
	}
}

testing.testmapping(data, mapping)
--Need to fix typeref now.