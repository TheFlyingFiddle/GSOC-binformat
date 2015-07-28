local tier  = require"tier"
local standard  = tier.standard
local primitive = tier.primitive

local tuple = standard.tuple
{
    { key = "a_int", mapping = primitive.int32 },
    { key = "a_float", mapping = primitive.float } 
}

local output = io.open("NamedTupleLimitations.dat", "wb")
tier.encode(output, { a_int = 13, a_float = 1.0 }, tuple)
tier.encode(output, { a_int = 54, a_float = 16.0 }, tuple)
output:close()

local input = io.open("NamedTupleLimitations.dat", "rb")
local with_mapping = tier.decode(input, tuple)
local without_mapping = tier.autodecode(input)
input:close()

--The fields are there as expected and they still have the same values.
assert(with_mapping.a_int == 13)
assert(with_mapping.a_float == 1.0)

--The fields are missing instead the data can be accessed using 
--the indices 1 and 2. In general the values will be placed in 
--1 .. n where n is the number of elements in the tuple.
assert(without_mapping[1] == 54)
assert(without_mapping[2] == 16.0)