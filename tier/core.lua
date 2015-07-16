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
    local top = #pending+1
    pending[top] = { domain = domain, id = id }
    return false, top
  end
  return true, domain.values[id]
end

function Decoder:setobject(value)
  local pending = self.pending
  local top = #pending
  if top > 0 then
    local entry = pending[top]
    pending[top] = nil
    local domain, id = entry.domain, entry.id
    domain.defined[id] = true
    domain.values[id] = value
  end
end

function Decoder:endobject(mapping, expected, id, value)
  local domain = self.domains[mapping]
  local pending = self.pending
  local top = #pending
  if domain.defined[id] then
    expected = expected-1
  else
    pending[top] = nil
    domain.defined[id] = true
    domain.values[id] = value
  end
  assert(top == expected, "corrupted mapping, unresolved objects")
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