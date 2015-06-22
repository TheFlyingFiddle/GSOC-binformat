local format    = require"format"
local encoding  = require"encoding.core"

encoding.primitive = require"encoding.primitive"
encoding.standard  = require"encoding.standard"


encoding.writer = format.writer
--Convinience function for encoding  single value
function encoding.encode(stream, value, mapping, usemetadata)
   if mapping == nil then
      mapping = encoding.standard.dynamic
   end
   
   if usemetadata == nil then
      usemetadata = true
   end
      
   local writer  = format.writer(stream)      
   local encoder = encoding.encoder(writer, usemetadata)
   encoder:encode(mapping, value)
   encoder:close()   
end

encoding.reader = format.reader

--Convinience function for decoding a single value.
function encoding.decode(stream, mapping, usemetadata)
   if mapping == nil then
       mapping = encoding.standard.dynamic
       if usemetadata == nil then
         usemetadata = false
       end
   else 
      if usemetadata == nil then
         usemetadata = true
      end
   end
      
   local reader  = format.reader(stream)   
   local decoder = encoding.decoder(reader, usemetadata)
   local val     = decoder:decode(mapping)
   decoder:close()
   return val
end

return encoding