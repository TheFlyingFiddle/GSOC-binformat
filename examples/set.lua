local encoding  = require"encoding"
local primitive = encoding.primitive
local standard  = encoding.standard

local outfile = io.open("Sets.dat", "wb")

--Mapping of a lua set of integers
local int_set_mapping = standard.set(primitive.int32)
local int_set_data =
{
  [2] = true, [3] = true,
  [5] = true, [7] = true,
  [11] = true, [13] = true
}

encoding.encode(outfile, int_set_data, int_set_mapping)
outfile:close()

--We can read the data back like this
local infile = io.open("Sets.dat", "rb")
local int_set = encoding.decode(infile, int_set_mapping)
infile:close()