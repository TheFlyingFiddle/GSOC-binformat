local newtyperef = custom.typeref

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
local listref 	  = newtyperef()
local listmapping = standard.tuple(
{
	{ key = "payload", mapping = primitive.varint },
	{ key = "next",    mapping = standard.nullable(listref) } 
})
listref:setref(listmapping)

local LinkedListCases = 
{
	{ actual = { payload = 2} },
	{ actual = { payload = 2, next = { payload = 3 } } },
	{ actual = { payload = 2, next = { payload = 3, next = { payload = 2 } } } },
}

runtest { mapping = listmapping, LinkedListCases }

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
local noderef = newtyperef()
local node = standard.nullable(standard.tuple(
{
	{ key = "payload", mapping = primitive.varint },
	{ key = "left",    mapping = noderef },
	{ key = "right",   mapping = noderef }
}))
noderef:setref(node)

local treemapping = standard.tuple(
{
	{ key = "nodecount", mapping = primitive.varint },
	{ key = "root", mapping = node}
})

local TreeCases = 
{
	{ actual = { nodecount = 0 } },
	{ actual = {
		nodecount = 2,
		root = 
		{
			payload = 3,
			left = 
			{
				payload = 23
			}
		}
	}},
	{ actual = {
		nodecount = 3,
		root = 
		{
			payload = 123,
			left = 
			{
				payload = 25
			},
			right = 
			{
				payload = 4123
			}
		}
	}},
	{ actual = {
		nodecount = 5,
		root = 
		{
			payload = 34512,
			left = 
			{
				payload = 21,
				right = 
				{
					payload = 321
				}
			},
			right = 
			{
				payload = 13,
				right = 
				{
					payload = 314
				}
			}
		}	
	}}
}

runtest { mapping = treemapping, TreeCases }

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
local listref 	  = newtyperef()
local listmapping = standard.object(standard.tuple(
{
	{ key = "payload", mapping = primitive.varint },
	{ key = "next",    mapping = standard.nullable(listref) } 
}))
listref:setref(listmapping)

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

local CyclicCases = { {actual = data} }

runtest { mapping = listmapping, CyclicCases}