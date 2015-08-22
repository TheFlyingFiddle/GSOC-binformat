local format    = require"format"
local tier  = require"tier.core"
local util      = require"tier.util"

tier.primitive = require"tier.primitive"
tier.standard  = require"tier.standard"


--Convinience function for tier  single value
tier.writer = format.writer
function tier.encode(stream, value, mapping, ...)
   if mapping == nil then
      mapping = tier.standard.dynamic
   end
      
   assert(util.ismapping(mapping))
   assert(util.isoutputstream(stream))
      
   local encoder = tier.encoder(tier.writer(stream))
   encoder:encode(mapping, value, ...)
   encoder:close()   
end

function tier.encodestring(value, mapping)
    local out = format.outmemorystream()
    tier.encode(out, value, mapping)
    return out:getdata()
end 

tier.reader = format.reader
function tier.decode(stream, mapping, ...)
   if mapping == nil then
       mapping = tier.standard.dynamic
   end
   
   if type(stream) == "string" then 
      stream = format.inmemorystream(stream)
   end 
  
   assert(util.isinputstream(stream))
   assert(util.ismapping(mapping))
   
   local decoder = tier.decoder(tier.reader(stream))
   local val     = decoder:decode(mapping, ...)
   decoder:close()
   return val    
end 

return tier