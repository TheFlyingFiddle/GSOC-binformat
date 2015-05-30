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
   self.stream:write(string)
end

--Encodes s string.
function Encoder:writestring(s)
   local length = string.len(s)
   self:writevarint(length)
   self:writeraw(s)
end

--Encodes an integer that is in the range [0 .. 0xff].
function Encoder:writebyte(byte)
   local rep = string.pack("B", byte)
   self:writeraw(rep);
end

--Encodes an integer that is in the range [0 .. 0xffff].
function Encoder:writeuint16(number)
   local rep = string.pack("I2", number)
   self:writeraw(rep);
end

--Encodes an integer that is in the range [0 .. 0xffffffff].
function Encoder:writeuint32(number)
   local rep = string.pack("I4", number)
   self:writeraw(rep);
end

--Encodes an integer that is in the range [0 .. 0xffffffffffffffff].
function Encoder:writeuint64(number)
   local rep = string.pack("I8", number)
   self:writeraw(rep);
end

--Encodes an integer that is in the range [-0x8000 .. 0x7fff].
function Encoder:writeint16(number)
   local rep = string.pack("i2", number)
   self:writeraw(rep)	
end

--Encodesan integer that is in the range [-0x80000000 .. 0x7fffffff].
function Encoder:writeint32(number)
   local rep = string.pack("i4", number)
   self:writeraw(rep)
end

--Encodes an integer that is in the range [-0x8000000000000000 .. 0x7fffffffffffffff].
function Encoder:writeint64(number)
   local rep = string.pack("i8", number)
   self:writeraw(rep)
end

--Encodes a float point value with 32-bit precision in IEEE 754 format.
function Encoder:writesingle(number)
   local rep = string.pack("f", number)
   self:writeraw(rep)
end

--Encodes a float point value with 64-bit precision in IEEE 754 format.
function Encoder:writedouble(number)
   local rep = string.pack("d", number);
   self:writeraw(rep);
end

--Encodes a boolean value.
function Encoder:writebit(bit)
   local number = 0;
   if bit then number = 1 end
   local rep = string.pack("B", number)
   self:writeraw(rep)
end

--Encodes a number in the variable integer encoding
--used by google protocol buffers. 
function Encoder:writevarint(number)
   while number >= 0x80 or number < 0 do
      local byte = (number | 0x80) & 0x00000000000000FF
      number = number >> 7;
      self:writebyte(byte);
   end
   
   self:writebyte(number)
end

--Encodes a number in zigzag encoded format 
--used for zigzag variable integer encoding used in 
--google protocol buffers. 
function Encoder:writevarintzz(number)
   -- This did not work for negative numbers...
   -- local bits = number >> 63 
   
   --Workaround
   --All bits set to 1
   local bits = 0xFFFFFFFFFFFFFFFF
   if(number >= 0) then
      --All bits set to 0
      bits = 0;
   end
   
   local zigzaged = (number << 1) ~ bits
   self:writevarint(zigzaged)
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
   local encoder = { stream = outStream }
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
   return self.stream:read(count);
end

--Reads a length prefixed string from the input stream.
function Decoder:readstring()
   local size = self:readvarint()
   return self:readraw(size); 
end

--Reads a byte from the input stream.
function Decoder:readbyte()
   local rep = self:readraw(1);
   return string.unpack("B", rep);	
end

--Reads a number between [0 .. 0xffff] from the input stream.
function Decoder:readuint16()
   local rep = self:readraw(2)
   return string.unpack("I2", rep)
end

--Reads a number between [0 .. 0xffffffff] from the input stream.
function Decoder:readuint32()
   local rep = self:readraw(4)
   return string.unpack("I4", rep)
end

--Reads a number between [0 .. 0xffffffffffff] from the input stream.
function Decoder:readuint64()
   local rep = self:readraw(8);
   return string.unpack("I8", rep)
end

--Reads a number between [-0x8000 .. 0x7fff] from the input stream.
function Decoder:readint16()
   local rep = self:readraw(2)
   return string.unpack("i2", rep)
end

--Reads a number between [-0x80000000 .. 0x7fffffff] from the input stream.
function Decoder:readint32()
   local rep = self:readraw(4)
   return string.unpack("i4", rep)
end

--Reads a number between [-0x8000000000000000 .. 0x7fffffffffffffff]  from the input stream.
function Decoder:readint64()
   local rep = self:readraw(8);
   return string.unpack("i8", rep)
end

--Reads a floting point number of precision 32-bit in 
--IEEE 754 single precision format.
function Decoder:readsingle()
   local rep = self:readraw(4)
   return string.unpack("f", rep)
end


--Reads a floting point number of precision 64-bit in 
--IEEE 754 double precision format.
function Decoder:readdouble()
   local rep = self:readraw(8)
   return string.unpack("d", rep)
end

--Reads a boolean value from the stream.
function Decoder:readbit()
   local rep = self:readbyte();
   if rep == 0 then 
      return false
   else
      return true
   end
end

--Reads a variable integer encoded using the encoding
--employed by google protocol buffers. 
function Decoder:readvarint()
   local number = 0;
   local count  = 0;
   while true do
      local byte = self:readbyte()
      number = number | ((byte & 0x7F) << (7 * count))
      if byte < 0x80 then break end
      count = count + 1;

      if count == 10 then
         --Something is wrong the data is corrupt.
         error("Decoded stream is corrupt!");	
      end
   end
   return number;
end

--Reads a variable zigzag encoded integer encoded using the 
-- zigzag encoding employed by google protocol buffers. 
function Decoder:readvarintzz()
   local zigzaged = self:readvarint()
   return (zigzaged >> 1) ~ (-(zigzaged & 1)) 
end

--Closes the decoder.
--After this operation is performed the decoder can no longer be used.
function Decoder:close()
   self.objects = nil
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
   local decoder = { stream = inStream}
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