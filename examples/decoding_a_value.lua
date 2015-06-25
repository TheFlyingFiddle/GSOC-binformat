local encoding = require"encoding"

local input_stream = assert(io.open("Encoding.dat", "rb"))
local reader       = encoding.reader(input_stream)
local decoder      = encoding.decoder(reader)

local mapping = encoding.primitive.int32
local the_meaning_of_life = decoder:decode(mapping)
assert(the_meaning_of_life == 42)