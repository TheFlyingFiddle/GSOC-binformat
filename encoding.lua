local format = require"format"

local encoding = { } 
local tags     = { }
--Standard tags
tags.VOID    = string.pack("B", 0x00) 
tags.NULL    = string.pack("B", 0x01)

tags.BIT     = string.pack("B", 0x02) 
tags.BOOLEAN = string.pack("B", 0x03)

--NUMBERS
tags.BYTE     = string.pack("B", 0x04)
tags.UINT16   = string.pack("B", 0x05)
tags.SINT16   = string.pack("B", 0x06)
tags.UINT32   = string.pack("B", 0x07)
tags.SINT32   = string.pack("B", 0x08)
tags.UINT64   = string.pack("B", 0x09)
tags.SINT64   = string.pack("B", 0x0A)
tags.SINGLE   = string.pack("B", 0x0B)
tags.DOUBLE   = string.pack("B", 0x0C)
tags.QUAD     = string.pack("B", 0x0D)
tags.VARINT   = string.pack("B", 0x0E)
tags.VARINTZZ = string.pack("B", 0x0F)

--CHARS, STREAM and STRINGS
tags.CHAR     = string.pack("B", 0x10)
tags.WCHAR    = string.pack("B", 0x11)
tags.STREAM   = string.pack("B", 0x12)
tags.STRING   = string.pack("B", 0x13)
tags.WSTRING  = string.pack("B", 0x14)

-- Encode changing
tags.DYNAMIC  = string.pack("B", 0x15)
tags.OBJECT   = string.pack("B", 0x16)
tags.EMBEDDED = string.pack("B", 0x17)
tags.SEMANTIC = string.pack("B", 0x18)

--Aggregate types
tags.LIST     = string.pack("B", 0x19)
tags.SET      = string.pack("B", 0x1A)
tags.ARRAY    = string.pack("B", 0x1B)
tags.TUPLE    = string.pack("B", 0x1C)
tags.UNION    = string.pack("B", 0x1D)
tags.MAP      = string.pack("B", 0x1E)

--Time and Date
tags.TIME     = string.pack("B", 0x1F)
tags.DATE     = string.pack("B", 0x20)

--Types
tags.TYPEREF  = string.pack("B", 0x21)
tags.TYPE     = string.pack("B", 0x22) 


--Possible extension that have not gotten approved by Renato yet.
--Universal unique identifiers. (128-bit integers used to represent unique values)
--tags.UUID     = string.pack("B", 0x23)
--tags.PACKED   = string.pack("B", 0x24)
--tags.UINT     = string.pack("B", 0x25)
--tags.SINT     = string.pack("B", 0x26) 

encoding.tags = tags;

function encoding.tagstring(tag)
   for k,v in pairs(tags) do
      if v == tag then
         return k
      end
   end
   
   return "Tag not found"
end

local Encoder = { }
Encoder.__index = Encoder;

--Writes the bytes contained in a raw string,
--to the output stream of the encoder.
function Encoder:writeraw(string)
   self.stream:writeraw(string)
end

--Encodes s string.
function Encoder:writestring(s)
   self.stream:writestring(s)
end

--Encodes an integer that is in the range [0 .. 0xff].
function Encoder:writebyte(byte)
   self.stream:writebyte(byte)
end

--Encodes an integer that is in the range [0 .. 0xffff].
function Encoder:writeuint16(number)
   self.stream:writeuint16(number)
end

--Encodes an integer that is in the range [0 .. 0xffffffff].
function Encoder:writeuint32(number)
   self.stream:writeuint32(number)
end

--Encodes an integer that is in the range [0 .. 0xffffffffffffffff].
function Encoder:writeuint64(number)
   self.stream:writeuint64(number)
end

--Encodes an integer that is in the range [-0x8000 .. 0x7fff].
function Encoder:writeint16(number)
   self.stream:writeint16(number)
end

--Encodesan integer that is in the range [-0x80000000 .. 0x7fffffff].
function Encoder:writeint32(number)
   self.stream:writeint32(number)
end

--Encodes an integer that is in the range [-0x8000000000000000 .. 0x7fffffffffffffff].
function Encoder:writeint64(number)
   self.stream:writeint64(number)
end

--Encodes a float point value with 32-bit precision in IEEE 754 format.
function Encoder:writesingle(number)
   self.stream:writesingle(number)
end

--Encodes a float point value with 64-bit precision in IEEE 754 format.
function Encoder:writedouble(number)
   self.stream:writedouble(number)
end

--Encodes a number in the variable integer encoding
--used by google protocol buffers. 
function Encoder:writevarint(number)
   self.stream:writevarint(number)
end

--Encodes a number in zigzag encoded format 
--used for zigzag variable integer encoding used in 
--google protocol buffers. 
function Encoder:writevarintzz(number)
   self.stream:writevarintzz(number)
end

--Encodes a boolean value. This value could be encoded as 
--a single bit. But I do not really like that. Since it affects
--All write functions if that is the case. 
function Encoder:writebit(bit)
   self.stream:writebit(bit)
end


--Finishes any pending operations and closes 
--the encoder. After this operation the encoder can no longer be used.
function Encoder:close()
   self.stream:flush()
   self.objects = nil;
   self.stream  = nil;
   setmetatable(self, nil);
end

--Encodes data using the specified mapping.
function Encoder:encode(mapping, data)
   if self.usemetadata then 
      self:writeraw(mapping.tag)
   end
   
   mapping:encode(self, data)	
end

--Creates an encoder from an output stream.
--Defaults to output metadata.
function encoding.encoder(outStream, usemetadata)
   local encoder = { stream = format.writer(outStream) }
   setmetatable(encoder, Encoder)
   encoder.objects = { }
   
   if usemetadata == false then 
      encoder.usemetadata = false
   else 
      encoder.usemetadata = true;
   end
   
   return encoder
end

function encoding.encode(outStream, value, mapping, usemetadata)
   local encoder = encoding.encoder(outStream, usemetadata)
   encoder:encode(mapping, value)
   encoder:close()   
end

local Decoder = { }
Decoder.__index = Decoder;

--Reads a string of length count from the input stream.
function Decoder:readraw(count)
   return self.stream:readraw(count)
end

--Reads a length prefixed string from the input stream.
function Decoder:readstring()
   return self.stream:readstring() 
end

--Reads a byte from the input stream.
function Decoder:readbyte()
   return self.stream:readbyte()
end

--Reads a number between [0 .. 0xffff] from the input stream.
function Decoder:readuint16()
   return self.stream:readuint16()
end

--Reads a number between [0 .. 0xffffffff] from the input stream.
function Decoder:readuint32()
   return self.stream:readuint32();
end

--Reads a number between [0 .. 0xffffffffffff] from the input stream.
function Decoder:readuint64()
   return self.stream:readuint64()
end

--Reads a number between [-0x8000 .. 0x7fff] from the input stream.
function Decoder:readint16()
   return self.stream:readint16()
end

--Reads a number between [-0x80000000 .. 0x7fffffff] from the input stream.
function Decoder:readint32()
   return self.stream:readint32()
end

--Reads a number between [-0x8000000000000000 .. 0x7fffffffffffffff]  from the input stream.
function Decoder:readint64()
   return self.stream:readint64()
end

--Reads a floting point number of precision 32-bit in 
--IEEE 754 single precision format.
function Decoder:readsingle()
   return self.stream:readsingle()
end

--Reads a floting point number of precision 64-bit in 
--IEEE 754 double precision format.
function Decoder:readdouble()
   return self.stream:readdouble()
end

--Reads a boolean value from the stream.
function Decoder:readbit()
   return self.stream:readbit()
end

--Reads a variable integer encoded using the encoding
--employed by google protocol buffers. 
function Decoder:readvarint()
   return self.stream:readvarint()
end

--Reads a variable zigzag encoded integer encoded using the 
-- zigzag encoding employed by google protocol buffers. 
function Decoder:readvarintzz()
   return self.stream:readvarintzz()
end

--Closes the decoder.
--After this operation is performed the decoder can no longer be used.
function Decoder:close()
   self.objects = nil
   self.stream  = nil
   setmetatable(self, nil)
end

--Decodes using the specified mapping.
function Decoder:decode(mapping)
   if self.usemetadata then 
      local meta_types = self:readraw(string.len(mapping.tag))
      assert(meta_types == mapping.tag)
   end 
   
   return mapping:decode(self)
end

--Reads a type from the stream. 
--I am not sure this method should be here. 
--It could be better to have a parse module
--that can extract types from metadata and possibly
--some idl language. It could be the case that this should be a pull parser
--instead of a dom parser. 
function Decoder:readtype()
   local first = self:readraw(1)
   local type  = { tag = first}
   if first == tags.LIST then
      type.element = self:readtype()   
   elseif first == tags.SET then 
      type.element = self:readtype()   
   elseif first == tags.ARRAY then
      type.size    = self:readvarint()
      type.element = self:readtype()
   elseif first == tags.TUPLE then
      type.size = self:readvarint()
      for i=1, type.size do
         type[i] = self:readtype()
      end
   elseif first == tags.UNION then
      type.size = self:readvarint()
      for i=1, type.size do
         type[i] = self:readtype()
      end 
   elseif first == tags.MAP then
      type.key   = self:readtype()
      type.value = self:readtype()
   elseif first == tags.OBJECT then
      type.sub  = self:readtype()
   elseif first == tags.EMBEDDED then
      type.sub  = self:readtype()
   elseif first == tags.SEMANTIC then
      type.id  = self:readstring()
      type.sub = self:readtype()
   elseif first == tags.TYPEREF then
      --This is difficult to deal with
      error("At the moment cannot decode TYPREFS in metatypes.")
   end
   return type
end

--Creates a decoder
function encoding.decoder(inStream, usemetadata)
   local decoder = { stream = format.reader(inStream)}
   setmetatable(decoder, Decoder)
   decoder.objects = { }
   
   if usemetadata == false then 
      decoder.usemetadata = false
   else
      decoder.usemetadata = true
   end
   
   return decoder
end

--Convinience function for decoding a single value.
function encoding.decode(stream, mapping, usemetadata)
   local decoder = encoding.decoder(stream, usemetadata)
   local val     = decoder:decode(mapping)
   decoder:close()
   return val
end

return encoding