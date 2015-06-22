local encoding = require"encoding"

local output_stream = assert(io.open("Encoding.dat", "wb"))
local writer  = encoding.writer(output_stream)
local encoder = encoding.encoder(writer)

local the_meaning_of_life = 42
local mapping = encoding.primitive.int32

encoder:encode(mapping, the_meaning_of_life)
encoder:close()
output_stream:close()