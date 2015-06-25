local encoding  = require"encoding"
local primitive = encoding.primitive
local standard  = encoding.standard

--Creates a mapping that can map between string or number
--values and their TIER encoding. 
local string_or_int_mapping = standard.union
{
    { type = "number", mapping = primitive.int32 },
    { type = "string", mapping = primitive.string } 
}

local item_mapping = standard.tuple
{
   { key = "item_number", mapping = primitive.int32 },
   { key = "readable_name", mapping = standard.optional(primitive.string) }
}

local with_name    = { item_number = 13, redable_name = "XRay-goggles" }
local without_name = { item_number = 14 } 

local output = io.open("Unions.dat", "wb")

--Encodes a integer value
encoding.encode(output, 123, string_or_int_mapping)

--Encodes a string value
encoding.encode(output, "Hello", string_or_int_mapping)

--Encodes a value with the optional value present.
encoding.encode(output, with_name, item_mapping)

--Encodes a value without the optional value
encoding.encode(output, without_name, item_mapping)
output:close()

local input = io.open("Unions.dat", "rb")
local a_string          = encoding.decode(input, string_or_int_mapping)
local a_int             = encoding.decode(input, string_or_int_mapping)
local item_with_name    = encoding.decode(input, item_mapping)
local item_without_name = encoding.decode(input, item_mapping)
input:close() 