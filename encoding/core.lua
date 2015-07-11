local format	= require"format"
local tags      = require"encoding.tags"

local core = { }
function core.getid(mapping)
    local id = mapping.id
    if id == nil then
        local buffer  = format.outmemorystream()
        local encoder = core.encoder(format.writer(buffer), false)
        encoder.types = { }
        encoder.types[mapping] = encoder.writer:getposition()
        assert(mapping.encodemeta, tags[mapping.tag] .. " lacking encode meta")
        mapping:encodemeta(encoder)
        encoder:close()
        local body = buffer:getdata()
        id = format.packvarint(mapping.tag) .. format.packvarint(#body) .. body
    end
    return id
end

function core.writemeta(encoder, mapping) 
    local writer = encoder.writer
    if mapping.tag == tags.TYPEREF then    --Typerefs are special 
        assert(mapping.mapper ~= nil, "incomplete typeref")
        core.writemeta(encoder, mapping.mapper)
    elseif mapping.encodemeta == nil then  --Simple single or predefined byte mapping.
        assert(mapping.id ~= nil, "invalid mapping")
        writer:raw(mapping.id)
    else
        local index = encoder.types[mapping]
        if index == nil then -- Type is described for the first time
            writer:varint(mapping.tag)
            encoder.types[mapping]  = writer:getposition()
            mapping:encodemeta(encoder)
        else
            writer:varint(tags.TYPEREF)
            writer:varint(writer:getposition() - index)
        end
    end
end

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
   self.writer:flushbits()
   if self.usemetadata then
      self.writer:raw(core.getid(mapping))
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
   self.reader:discardbits()   
   if self.usemetadata  then 
      local id = core.getid(mapping)
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