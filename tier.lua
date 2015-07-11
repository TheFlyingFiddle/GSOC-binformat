local format    = require"format"
local tier  = require"tier.core"
local util      = require"tier.util"

tier.primitive = require"tier.primitive"
tier.standard  = require"tier.standard"


tier.writer = format.writer
--Convinience function for tier  single value
function tier.encode(stream, value, mapping, usemetadata)
   if mapping == nil then
      mapping = tier.standard.dynamic
   end
   
   if usemetadata == nil then
      usemetadata = true
   end
      
   assert(util.ismapping(mapping))
   assert(util.isoutputstream(stream))
      
   local writer  = format.writer(stream)      
   local encoder = tier.encoder(writer, usemetadata)
   encoder:encode(mapping, value)
   encoder:close()   
end

tier.reader = format.reader

--Convinience function for decoding a single value.
function tier.decode(stream, mapping, usemetadata)
   if mapping == nil then
       mapping = tier.standard.dynamic
   end
   
   if usemetadata == nil then
      usemetadata = true
   end

  
   assert(util.isinputstream(stream))
   assert(util.ismapping(mapping))
      
   local reader  = format.reader(stream)   
   local decoder = tier.decoder(reader, usemetadata)
   local val     = decoder:decode(mapping)
   decoder:close()
   return val
end

return tier