local encoding = require"encoding"

--The dynamic mapping
local dynamic = encoding.standard.dynamic

local output = io.open("Dynamics.dat", "wb")

--Encode a string
encoding.encode(output, "some string", dynamic)

--Encode a number
--The encoding.encode function defaults to using dynamic encoding
--so the _dynamic_ mapping can be eluded if wanted.
encoding.encode(output, 132)

--Encode a boolean
encoding.encode(output, true)

--Encode nothing
encoding.encode(output, nil)

--Encode a more complex table
encoding.encode(output, { a = "Hello", b = 412, c = false, d = { 1, 2, 3 } })
output:close()

local input = io.open("Dynamics.dat", "rb")

--The decoding function defaults to using dynamic decoding.
--This decoding is the same as standard.dynamic so it can be 
--eluded. 
local string  = encoding.decode(input, dynamic)
local number  = encoding.decode(input)
local boolean = encoding.decode(input)
local null    = encoding.decode(input)
local table   = encoding.decode(input)
input:close()