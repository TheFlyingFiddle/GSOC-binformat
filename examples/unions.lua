local tier  = require"tier"
local primitive = tier.primitive
local standard  = tier.standard

--Creates a mapping that can map between string or number
--values and their TIER tier. 
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
tier.encode(output, 123, string_or_int_mapping)

--Encodes a string value
tier.encode(output, "Hello", string_or_int_mapping)

--Encodes a value with the optional value present.
tier.encode(output, with_name, item_mapping)

--Encodes a value without the optional value
tier.encode(output, without_name, item_mapping)
output:close()

local input = io.open("Unions.dat", "rb")
local a_string          = tier.decode(input, string_or_int_mapping)
local a_int             = tier.decode(input, string_or_int_mapping)
local item_with_name    = tier.decode(input, item_mapping)
local item_without_name = tier.decode(input, item_mapping)
input:close() 