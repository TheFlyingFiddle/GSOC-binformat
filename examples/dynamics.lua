local tier = require"tier"

--The dynamic mapping
local dynamic = tier.standard.dynamic

local output = io.open("Dynamics.dat", "wb")

--Encode a string
tier.encode(output, "some string", dynamic)

--Encode a number
--The tier.encode function defaults to using dynamic tier
--so the _dynamic_ mapping can be eluded if wanted.
tier.encode(output, 132)

--Encode a boolean
tier.encode(output, true)

--Encode nothing
tier.encode(output, nil)

--Encode a more complex table
tier.encode(output, { a = "Hello", b = 412, c = false, d = { 1, 2, 3 } })
output:close()

local input = io.open("Dynamics.dat", "rb")

--The decoding function defaults to using dynamic decoding.
--This decoding is the same as standard.dynamic so it can be 
--eluded. 
local string  = tier.decode(input, dynamic)
local number  = tier.decode(input)
local boolean = tier.decode(input)
local null    = tier.decode(input)
local table   = tier.decode(input)
input:close()