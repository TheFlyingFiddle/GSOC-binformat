local format	= require"format"
local encoding  = require"encoding.core"

encoding.primitive = require"encoding.primitive"
encoding.standard  = require"encoding.standard"

--Convinience function for encoding  single value
function encoding.encode(outStream, value, mapping, usemetadata)
   local encoder = encoding.encoder(outStream, usemetadata)
   encoder:encode(mapping, value)
   encoder:close()   
end

--Convinience function for decoding a single value.
function encoding.decode(stream, mapping, usemetadata)
   local decoder = encoding.decoder(stream, usemetadata)
   local val     = decoder:decode(mapping)
   decoder:close()
   return val
end

return encoding