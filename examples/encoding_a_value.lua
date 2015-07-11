local tier = require"tier"

local output_stream = assert(io.open("tier.dat", "wb"))
local writer  = tier.writer(output_stream)
local encoder = tier.encoder(writer)

local the_meaning_of_life = 42
local mapping = tier.primitive.int32

encoder:encode(mapping, the_meaning_of_life)
encoder:close()
output_stream:close()