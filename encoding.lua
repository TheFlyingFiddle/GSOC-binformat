local format    = require"format"
local encoding  = require"encoding.core"
local util      = require"encoding.util"

encoding.primitive = require"encoding.primitive"
encoding.standard  = require"encoding.standard"


encoding.writer = format.writer
--Convinience function for encoding  single value
function encoding.encode(stream, value, mapping, usemetadata)
   if mapping == nil then
      mapping = encoding.standard.dynamic
   else
      util.ismapping(mapping)
   end
   
   if usemetadata == nil then
      usemetadata = true
   end
      
   util.isinputstream(stream)
      
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
      util.ismapping(mapping)
       
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