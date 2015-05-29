package.path = package.path .. ";../?.lua"

local encoding  = require"encoding"
local primitive = require"encoding.primitive"
local standard	= require"encoding.standard"
local composed  = require"encoding.composed"
local testing   = require"testing"

print("Starting tests for typeref")

--A lua object as union with typeref
-- union LuaValue
-- {
--     null,
--     string,
--     double,
--     boolean,
--     object map(LuaValue, LuaValue)
-- }
--
--Metadata: 
--UNION 05
--	VOID
--  STRING
--  DOUBLE
--  BOOLEAN
--  OBJECT MAP 
--		TYPEREF 06
--      TYPEREF 08
--  (Could possebly include functions aswell)
local luaref = composed.typeref()
local luamapping = standard.union(
{ 
	{ type = "nil",     mapping = primitive.void },
  	{ type = "string",  mapping = primitive.string},
	{ type = "number",  mapping = primitive.fpdouble},
	{ type = "boolean", mapping = primitive.bit },
	{ type = "table",   mapping = standard.object(standard.map(luaref, luaref)) }
})

luaref:setRef(luamapping)

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

testing.testmapping(data, luamapping)

--Linked list.
-- tuple List
-- {
--    varint payload;
--    List? next;
-- }
--
--Meta:
--TUPLE 02
--	VARINT
--  UNION 02
--		VOID
--		TYPEREF 05
local listref 	  = composed.typeref()
local listmapping = standard.tuple(
{
	{ key = "payload", mapping = primitive.varint },
	{ key = "next",    mapping = standard.nullable(listref) } 
})
listref:setRef(listmapping)

local data =
{
	payload = 2,
	next = 
	{
		payload = 12,
		next =
		{
			payload = 22,
			next = nil
		}
	}
}

testing.testmapping(data, listmapping)

--A binary tree
-- tuple Tree 
-- {
--    varint count;
--    Node?   root;
-- }
-- tuple Node
-- {
--    varint payload;
--    Node?  left;
--    Node?  right;
-- }
--
--Meta:
-- TUPLE 02
--	VARINT
--	UNION 02
--		VOID
--		TUPLE 03
--			VARINT
--			TYPEREF 06
--			TYPEREF 08

local noderef = composed.typeref()
local node = standard.nullable(standard.tuple(
{
	{ key = "payload", mapping = primitive.varint },
	{ key = "left",    mapping = noderef },
	{ key = "right",   mapping = noderef }
}))
noderef:setRef(node)

local treemapping = standard.tuple(
{
	{ key = "nodecount", mapping = primitive.varint },
	{ key = "root", mapping = node}
})

local data = 
{
	nodecount = 4,
	root = 
	{
		payload = 3,
		left = 
		{
			payload = 8,
			left = 
			{
				payload = 21
			}	
		},
		right = 
		{
			payload = 32	
		}
	}
}
testing.testmapping(data, treemapping)

-- Linked list with cycle
-- tuple List
-- {
--    varint payload;
--    object List? next;
-- }
--
--Meta:
-- OBJECT 
--  TUPLE 02
-- 	  VARINT
--    UNION 02
--	    VOID
--		TYPEREF 06
local listref 	  = composed.typeref()
local listmapping = standard.object(standard.tuple(
{
	{ key = "payload", mapping = primitive.varint },
	{ key = "next",    mapping = standard.nullable(listref) } 
}))
listref:setRef(listmapping)

local last = { payload = 3 }
local data =
{
	payload = 2,
	next = 
	{
		payload = 12,
		next =
		{
			payload = 22,
			next = last
		}
	}
}
last.next = data;

local out = testing.outstream();
encoding.encode(out, data, listmapping)

local in_ = testing.instream(out.buffer)
local value = encoding.decode(in_, listmapping)

assert(value.payload == data.payload)
assert(value.next.payload == data.next.payload)
assert(value.next.next.payload == data.next.next.payload)
assert(value.next.next.next.payload == last.payload)
assert(value == value.next.next.next.next)

print("all tests passed")