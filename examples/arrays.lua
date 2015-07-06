--We start by fetching the standard libraries.
local encoding  = require"encoding"
local primitive = encoding.primitive
local standard  = encoding.standard

--An output file. 
local file = io.open("Arrays.dat", "wb")

--A mapping from a table with 5 integer numbers.
local int_array_mapping = standard.array(primitive.int32, 5)
local int_array_data = { 0, 1, 2, 3, 4 }

--Encodes the integer array
encoding.encode(file, int_array_data, int_array_mapping)

--Another mapping this time a table with 3 strings.
local string_array_mapping = standard.array(primitive.string, 3)
local string_array_data = { "First", "Second", "Third" }

--Encodes the string array
encoding.encode(file, string_array_data, string_array_mapping)

--A 4x4 matrix of floats.
local matrix_mapping = standard.array(standard.array(primitive.float, 4), 4)
local matrix_data = 
{
   { 1, 0, 0, 0 },
   { 0, 1, 0, 0 },
   { 0, 0, 1, 0 },
   { 0, 0, 0, 1 }
}

--Encodes the matrix
encoding.encode(file, matrix_data, matrix_mapping)
file:close()

--We can now decode the values we wrote. 
local infile = io.open("Arrays.dat", "rb")

--Notice that we supply the mappings here. We do not have to do this
--It will work either way, but supplying the mappings will indicate
--What type we want and provide some type checking.
local int_array    = encoding.decode(infile, int_array_mapping)
local string_array = encoding.decode(infile, string_array_mapping)
local float_matrix = encoding.decode(infile, matrix_mapping)
infile:close()