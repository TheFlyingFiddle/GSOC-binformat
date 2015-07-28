local tier   = require"tier"
local standard  = tier.standard
local primitive = tier.primitive

local output = io.open("Graphs.dat", "wb")

--Creates a linked list mapping via the selfref method
local linked_list_mapping = standard.selfref(function(self_ref)
    return standard.object(standard.tuple
    {
        { key = "payload", mapping = primitive.double },
        { key = "next",    mapping = standard.optional(self_ref) }
    })
end)

--Creates an identical linked list mapping using the typeref api. 
local list_ref = standard.typeref()
local linked_list_mapping2 = standard.object(standard.tuple
{
   { key = "payload", mapping = primitive.double },
   { key = "next",    mapping = standard.optional(list_ref) }
})
list_ref:setref(linked_list_mapping2)

local linked_list = 
{
    payload = 2,
    next    = 
    {
        payload = 32,
        next = 
        {
            payload = 22
        }
    }
}

--Encodes a linked_list with the list mapping
tier.encode(output, linked_list, linked_list_mapping)
tier.encode(output, linked_list, linked_list_mapping2)

--We can also encode linked lists with references 
--Since we created them as reference mappings.
linked_list.next = linked_list
tier.encode(output, linked_list, linked_list_mapping)

--Creates a tree mapping
--A mapping where two of the sub mappings refer back to 
--the parent mapping.
local tree_node_mapping = standard.selfref(function(self_ref)
    return standard.tuple 
    {
        { key = "payload",   mapping = primitive.double },
        { key = "left",      mapping = standard.optional(self_ref) },
        { key = "right",     mapping = standard.optional(self_ref) }
    }
end)

--A simple tree mapping
local tree_mapping = standard.tuple
{
    { key = "num_nodes", mapping = primitive.varint },
    { key = "root",      mapping = tree_node_mapping }
}

local tree = 
{
   num_nodes = 5,
   root = 
   {
      payload = 3, 
      left = { payload = 2 },
      right = 
      {
          payload = 32,
          left = { payload = 65 },
          right = { payload = 22 }
      }
   } 
}

--Encode the tree
tier.encode(output, tree, tree_mapping)
output:close()

local input = io.open("Graphs.dat", "rb")
local list_a = tier.decode(input, linked_list_mapping)
local list_b = tier.autodecode(input) --Dynamic decoding
local cyclic_list = tier.decode(input, linked_list_mapping2)
local tree_a = tier.decode(input, tree_mapping)
input:close()