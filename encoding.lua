local format = require"format"

local encoding = { } 
local tags     = { }

--Standard empty
tags.VOID    = string.pack("B", 0x00) 
tags.NULL    = string.pack("B", 0x01) 

--Terminated Multi-Byte (ALIGN 0x08)
tags.VARINT    = string.pack("B",  0x03)
tags.VARINTZZ  = string.pack("B",  0x04)

--Characters (ALIGN 0x08)
tags.CHAR      = string.pack("B", 0x05)
tags.WCHAR     = string.pack("B", 0x06)

--Types (ALIGN 0x08)
tags.TYPE      = string.pack("B", 0x07)
tags.TYPEREF   = string.pack("B", 0x08)
tags.DYNAMIC   = string.pack("B", 0x09)

--Sub-Byte
tags.UINT      = string.pack("B", 0x0A)
tags.SINT      = string.pack("B", 0x0B)

--Composition (Variable alignment)
tags.ARRAY     = string.pack("B", 0x0C)
tags.TUPLE     = string.pack("B", 0x0D)

--Counted Compositions (Variable alignment)
tags.UNION     = string.pack("B", 0x0E)
tags.LIST      = string.pack("B", 0x0F)
tags.SET       = string.pack("B", 0x10)
tags.MAP       = string.pack("B", 0x11)

--Structure modifiers
tags.ALIGN     = string.pack("B", 0x12)
tags.OBJECT    = string.pack("B", 0x13)
tags.EMBEDDED  = string.pack("B", 0x14)
tags.SEMANTIC  = string.pack("B", 0x15)

--Aliases Bits
tags.FLAG      = string.pack("B", 0x16) -- UINT 0x00 
tags.SIGN      = string.pack("B", 0x17) -- SINT 0x00

--Aliases Alignments
tags.ALIGN8    = string.pack("B", 0x18) -- ALIGN 0x08
tags.ALIGN16   = string.pack("B", 0x19) -- ALIGN 0x10
tags.ALIGN32   = string.pack("B", 0x1A) -- ALIGN 0x20
tags.ALIGN64   = string.pack("B", 0x1B) -- ALIGN 0x40

--Common Aliases

--Boleans
tags.BOOLEAN   = string.pack("B", 0x1C) -- ALIGN0 FLAG ALIGN 0x08 So we can use this inside a byte but that byte is then aligned to 8bits

--Integers
tags.BYTE      = string.pack("B", 0x1D) -- ALIGN8 UINT 0x08
tags.UINT16    = string.pack("B", 0x1F) -- ALIGN8 UINT 0x10
tags.UINT32    = string.pack("B", 0x20) -- ALIGN8 UINT 0x20
tags.UINT64    = string.pack("B", 0x21) -- ALIGN8 UINT 0x40
tags.SINT16    = string.pack("B", 0x22) -- ALIGN8 SINT 0x10
tags.SINT32    = string.pack("B", 0x23) -- ALIGN8 SINT 0x20
tags.SINT64    = string.pack("B", 0x24) -- ALIGN8 SINT 0x40

--Floats
tags.SINGLE    = string.pack("B", 0x25) -- SEMANTIC "floating" ALIGN8 UINT 0x20
tags.DOUBLE    = string.pack("B", 0x26) -- SEMANTIC "floating" ALIGN8 UINT 0x40
tags.QUAD      = string.pack("B", 0x27) -- SEMANTIC "floating" ALIGN8 UINT 0x80

--Strings
tags.STREAM    = string.pack("B", 0x28) -- LIST size BYTE
tags.STRING    = string.pack("B", 0x29) -- LIST size CHAR
tags.WSTRING   = string.pack("B", 0x2A) -- LIST size WCHAR

encoding.tags = tags;

function encoding.tagstring(tag)
   for k,v in pairs(tags) do
      if v == tag then
         return k
      end
   end
   
   return "Tag not found"
end


--Standard generator functions
function encoding.tagtoluatype(tag)
   if tag == tags.VOID or
      tag == tags.NULL then
		return "nil"
   elseif tag == tags.BIT or
          tag == tags.BOOLEAN then
		return "boolean"       
   elseif tag == tags.BYTE or
          tag == tags.UINT16 or
          tag == tags.SINT16 or
          tag == tags.UINT32 or
          tag == tags.SINT32 or
          tag == tags.UINT64 or
          tag == tags.SINT64 or
          tag == tags.SINGLE or
          tag == tags.DOUBLE or
          tag == tags.QUAD   or
          tag == tags.VARINT or
          tag == tags.VARINTZZ then
		return "number"
    elseif tag == tags.CHAR or
           tag == tags.WCHAR or
           tag == tags.STREAM or
           tag == tags.STRING or
           tag == tags.WSTRING then
		return "string"
    elseif tag == tags.LIST or
           tag == tags.SET  or
           tag == tags.ARRAY or
           tag == tags.TUPLE or
           tag == tags.MAP then
		return "table"    
   else	
		return "unkown"
   end
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

--Encodes a boolean value.  
--All write functions if that is the case. 
function Encoder:writebool(bool)
   if bool then bool = 1 else bool = 0 end
   self.stream:writebyte(bool)
end

--Encodes a signed integer of (size) bits
function Encoder:writeint(size, number)
   self.stream:writeint(size, number)
end

--Encodes an unsigned integer of (size) bits
function Encoder:writeuint(size, number)
   self.stream:writeuint(size, number)
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
   self.stream:flushbits()
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

--Reads a boolean value
function Decoder:readbool()
   local value = self.stream:readbyte()
   if value == 1 then
      value = true
   else
      value = false
   end
   return value
end

--Alignes the stream to the specified size
function Decoder:align(size)
   self.stream:align(size)
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

function Decoder:readuint(size)
   return self.stream:readuint(size)
end

function Decoder:readint(size)
   return self.stream:readint(size)
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
   self.stream:discardbits()   
   if self.usemetadata then 
      local meta_types = self:readraw(string.len(mapping.tag))
      assert(meta_types == mapping.tag)
   end 
   
   return mapping:decode(self)
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