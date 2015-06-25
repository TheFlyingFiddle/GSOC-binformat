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
	{ mapping = primitive.varint },
	{ mapping = standard.optional(listref) } 
})
listref:setref(listmapping)

local LinkedListCases = 
{
	{ actual = { 2 } },
	{ actual = { 3 , { 5 } } },
	{ actual = { 4, { 6, { 7 } } } },
}
runtest { mapping = listmapping, LinkedListCases }


local listref 	  = newtyperef()
local listmapping = standard.optional(standard.tuple(
{
	{ mapping = primitive.varint },
	{ mapping = listref } 
}))
listref:setref(listmapping)

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
local node = standard.optional(standard.tuple(
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

runtest { nodynamic = true, mapping = treemapping, TreeCases }

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
	{ key = "next",    mapping = standard.optional(listref) } 
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

runtest { nodynamic = true, mapping = listmapping, CyclicCases}