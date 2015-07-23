local format	= require"format"

local core = { }

local Encoder = { }
Encoder.__index = Encoder

function Encoder:getobjectmap(mapping)
  local domain = self.domains[mapping]
  if domain == nil then
    domain = {}
    self.domains[mapping] = domain
  end
  return domain
end

--Encodes data using the specified mapping.
function Encoder:encode(mapping, data)
   local meta = require"tier.meta"
   self.writer:flushbits()
   if self.usemetadata then
      meta.encodetype(self, mapping.meta)
   end
   
   mapping:encode(self, data)	
end

function Encoder:writef(fmt, ...)
   self.writer:writef(fmt, ...)  
end 

--Finishes any pending operations and closes 
--the encoder. After this operation the encoder can no longer be used.
function Encoder:close()
   self.writer:flush()
   self.objects = nil;
   self.writer  = nil;
   setmetatable(self, nil);
end

function core.encoder(writer, usemetadata)
	local encoder = setmetatable({ }, Encoder)
  encoder.writer = writer;
  encoder.domains = { }
	encoder.usemetadata = usemetadata
	return encoder	
end


local Decoder = { }
Decoder.__index = Decoder

function Decoder:getobject(mapping, id)
  local domain = self.domains[mapping]
  if domain == nil then
    domain = { values = {}, defined = {} }
    self.domains[mapping] = domain
  end
  if not domain.defined[id] then
    local pending = self.pending
    pending[#pending+1] = { domain = domain, id = id }
    return false
  end
  return true, domain.values[id]
end

function Decoder:setobject(value)
  local pending = self.pending
  for _, entry in ipairs(pending) do
    local domain, id = entry.domain, entry.id
    domain.defined[id] = true
    domain.values[id] = value
  end
  self.pending = {}
end

function Decoder:endobject(mapping, id, value)
  if not self.domains[mapping].defined[id] then
    self:setobject(value)  
  end
  return value
end

--Decodes using the specified mapping.
function Decoder:decode(mapping)
  local meta = require"tier.meta"

   self.reader:discardbits()   
   if self.usemetadata and mapping.meta ~= meta.dynamic then 
      local id         = meta.getencodeid(mapping.meta)
      local meta_types = self.reader:raw(#id)
      assert(meta_types == id)
   end 
   
   return mapping:decode(self)
end

function Decoder:readf(fmt, ...)
  return self.reader:readf(fmt, ...)
end 

--Closes the decoder.
--After this operation is performed the decoder can no longer be used.
function Decoder:close()
   self.objects = nil
   self.reader  = nil
   setmetatable(self, nil)
end

--Creates a decoder
function core.decoder(reader, usemetadata)
	local decoder = setmetatable({ }, Decoder)
    decoder.reader  = reader
	decoder.domains = {}
	decoder.pending = {}
	decoder.usemetadata = usemetadata
	return decoder
end

return core