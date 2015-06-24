local encoding  = require"encoding"
local primitive = encoding.primitive
local standard  = encoding.standard

local point_mapping = standard.tuple
{
   { mapping = primitive.float },
   { mapping = primitive.float }
}

local output = io.open("AnonymousTuples.dat", "wb")
encoding.encode(output, { 14, -12 }, point_mapping)
encoding.encode(output, { 21, 24}, point_mapping)
output:close()

local input = io.open("AnonymousTuples.dat", "rb")
local point_a = encoding.decode(input, point_mapping)
local point_b = encoding.decode(input)
input:close()

--The values in the points are accessed with the integers 
-- 1 .. n where n is the number of items in the tuple.
assert(point_a[1] == 14)
assert(point_a[2] == -12)