local format	= require"c.format"
local encoding  = require"encoding.core"

encoding.primitive = require"encoding.primitive"
encoding.standard  = require"encoding.standard"


encoding.writer = format.writer
--Convinience function for encoding  single value
function encoding.encode(writer, value, mapping, usemetadata)
   if mapping == nil then
      mapping = encoding.standard.dynamic
   end
      
   local encoder = encoding.encoder(writer, usemetadata)
   encoder:encode(mapping, value)
   encoder:close()   
end


encoding.reader = format.reader
--Convinience function for decoding a single value.
function encoding.decode(reader, mapping, usemetadata)
   if mapping == nil then
       mapping = encoding.standard.dynamic
   end
   
   local decoder = encoding.decoder(reader, usemetadata)
   local val     = decoder:decode(mapping)
   decoder:close()
   return val
end

return encoding