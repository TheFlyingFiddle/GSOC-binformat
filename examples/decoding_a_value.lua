local tier = require"tier"

local input_stream = assert(io.open("tier.dat", "rb"))
local reader       = tier.reader(input_stream)
local decoder      = tier.decoder(reader)

local mapping = tier.primitive.int32
local the_meaning_of_life = decoder:decode(mapping)
assert(the_meaning_of_life == 42)