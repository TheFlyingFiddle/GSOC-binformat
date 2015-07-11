local tier  = require"tier"
local primitive = tier.primitive
local standard  = tier.standard

local outfile = io.open("Maps.dat", "wb")

--Mapping of a map with strings and ints
local string_to_int_mapping = standard.map(primitive.string, primitive.int32)
local string_to_int_data =
{
    this = 1, is = 32, a = 123,
    mapping = 32, between = 3,
    strings = 23, ["and"] = 123,
    ints = 61
}

--Encode the string to int map
tier.encode(outfile, string_to_int_data, string_to_int_mapping)

--Mapping of a map 
local string_to_string_mapping = standard.map(primitive.string, primitive.string)
local string_to_string_data  =
{
   A = "T", T = "A", 
   G = "C", C = "G",
   a = "t", t = "a",
   g = "c", c = "g"
}

tier.encode(outfile, string_to_string_data, string_to_string_mapping)
outfile:close()

--Reads back the values encoded
local infile = io.open("Maps.dat", "rb")
local string_to_int = tier.decode(infile, string_to_int_mapping)
local string_to_string = tier.decode(infile, string_to_string_mapping)
infile:close()