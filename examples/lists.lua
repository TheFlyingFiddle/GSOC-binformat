local tier  = require"tier"
local primitive = tier.primitive
local standard  = tier.standard

local outfile = io.open("Lists.dat", "wb")

--A mapping from a table with integer numbers.
local int_list_mapping = standard.list(primitive.int32)
local int_list_1 = { 1, 2, 3, 4, 5 }
local int_list_2 = { 0, 2 }

--Encode a couple of different integer lists.
tier.encode(outfile, int_list_1, int_list_mapping)
tier.encode(outfile, int_list_2, int_list_mapping)

--A mapping from an List of List of floats.
local float_lists_mapping = standard.list(standard.list(primitive.float))
local float_list_data =
{
   { 0, 1, 0 },
   { 1 },
   { 0, 1, 2 , 3 ,4, 5 }
}

--Encode the list of float list data.
tier.encode(outfile, float_list_data, float_lists_mapping)
outfile:close()

--We can now read back the values.
local infile = io.open("Lists.dat", "rb")
local int_list_a = tier.decode(infile, int_list_mapping)
local int_list_b = tier.decode(infile, int_list_mapping)
local float_list = tier.decode(infile, float_lists_mapping)
infile:close()