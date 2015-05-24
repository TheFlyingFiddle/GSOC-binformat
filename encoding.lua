local encoding = { } 
local tags     = { }
--Standard tags
tags.VOID     = string.pack("B", 0x00)
tags.NULL     = VOID

tags.BIT	   = string.pack("B", 0x01)
tags.BOOLEAN  = BIT

--NUMBERS
tags.BYTE     = string.pack("B", 0x02)
tags.UINT16   = string.pack("B", 0x03)
tags.SINT16   = string.pack("B", 0x04)
tags.UINT32   = string.pack("B", 0x05)
tags.SINT32   = string.pack("B", 0x06)
tags.UINT64   = string.pack("B", 0x07)
tags.SINT64   = string.pack("B", 0x08)
tags.SINGLE   = string.pack("B", 0x09)
tags.DOUBLE   = string.pack("B", 0x0A)
tags.QUAD	  = string.pack("B", 0x0B)
tags.VARINT   = string.pack("B", 0x0C)
tags.VARINTZZ = string.pack("B", 0x0D)

--CHARS, STREAM and STRINGS
tags.CHAR	   = string.pack("B", 0x0E)
tags.WCHAR    = string.pack("B", 0x0F)
tags.STREAM   = string.pack("B", 0x10)
tags.STRING   = string.pack("B", 0x11)
tags.WSTRING  = string.pack("B", 0x12)

-- Encode changing
tags.DYNAMIC  = string.pack("B", 0x13)
tags.OBJECT   = string.pack("B", 0x14)
tags.EMBEDDED = string.pack("B", 0x15)
tags.SEMANTIC = string.pack("B", 0x16)

--Aggregate types
tags.LIST	   = string.pack("B", 0x17)
tags.SET      = string.pack("B", 0x18)
tags.ARRAY    = string.pack("B", 0x19)
tags.TUPLE    = string.pack("B", 0x1A)
tags.UNION    = string.pack("B", 0x1B)
tags.MAP	   = string.pack("B", 0x1C)

--Time and Date
tags.TIME     = string.pack("B", 0x1D)
tags.DATE     = string.pack("B", 0x1E)

encoding.tags = tags;


local encoderMT = { }
encoderMT.__index = encoderMT;

--Writes the bytes contained in a raw string,
--to the output stream of the encoder.
function encoderMT:writeraw(string)
	self.stream:write(string);
end

--Encodes s string.
function encoderMT:writestring(s)
	local length = string.len(s)
	self:writevarint(length)
	self:writeraw(s)
end

--Encodes an integer that is in the range [0 .. 0xff].
function encoderMT:writebyte(byte)
	local rep = string.pack("B", byte)
	self:writeraw(rep);
end

--Encodes an integer that is in the range [0 .. 0xffff].
function encoderMT:writeuint16(number)
	local rep = string.pack("I2", number)
	self:writeraw(rep);
end

--Encodes an integer that is in the range [0 .. 0xffffffff].
function encoderMT:writeuint32(number)
	local rep = string.pack("I4", number)
	self:writeraw(rep);
end

--Encodes an integer that is in the range [0 .. 0xffffffffffffffff].
function encoderMT:writeuint64(number)
	local rep = string.pack("I8", number)
	self:writeraw(rep);
end

--Encodes an integer that is in the range [-0x8000 .. 0x7fff].
function encoderMT:writeint16(number)
	local rep = string.pack("i2", number)
	self:writeraw(rep)	
end

--Encodesan integer that is in the range [-0x80000000 .. 0x7fffffff].
function encoderMT:writeint32(number)
	local rep = string.pack("i4", number)
	self:writeraw(rep)
end

--Encodes an integer that is in the range [-0x8000000000000000 .. 0x7fffffffffffffff].
function encoderMT:writeint64(number)
	local rep = string.pack("i8", number)
	self:writeraw(rep)
end

--Encodes a float point value with 32-bit precision in IEEE 754 format.
function encoderMT:writesingle(number)
	local rep = string.pack("f", number)
	self:writeraw(rep)
end

--Encodes a float point value with 64-bit precision in IEEE 754 format.
function encoderMT:writedouble(number)
	local rep = string.pack("d", number);
	self:writeraw(rep);
end

--Encodes a boolean value.
function encoderMT:writebit(bit)
	local number = 0;
	if bit then number = 1 end
	local rep = string.pack("B", number)
	self:writeraw(rep)
end

--Encodes a number in the variable integer encoding
--used by google protocol buffers. 
function encoderMT:writevarint(number)
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
function encoderMT:writevarintzz(number)
	--Can also be done via arithmetic shift.
	local bits = 0xFFFFFFFFFFFFFFFF
	if(number >= 0) then
		bits = 0;
	end
	
	local zigzaged = (number << 1) ~ bits
	self:writevarint(zigzaged)
end

--Flushes the underlying stream ensuring that 
--all data has been written.
function encoderMT:flush()
	self.stream:flush()
end

--Finishes any pending operations and closes 
--the encoder. After this operation the encoder can no longer be used.
function encoderMT:close()
	self:flush()
end

--Encodes data using the specified mapping.
function encoderMT:encode(mapping, data)
	self:writestring(mapping.tag)
	mapping:encode(self, data)	
end

--Creates an encoder from an output stream.
function encoding.encoder(outStream)
	local encoder = { stream = outStream }
	setmetatable(encoder, encoderMT)
	return encoder
end

local decoderMT = { }
decoderMT.__index = decoderMT;

--Reads a string of length count from the input stream.
function decoderMT:readraw(count)
	return self.stream:read(count);
end

--Reads a length prefixed string from the input stream.
function decoderMT:readstring()
	local size = self:readvarint()
	return self:readraw(size); 
end

--Reads a byte from the input stream.
function decoderMT:readbyte()
	local rep = self:readraw(1);
	return string.unpack("B", rep);	
end

--Reads a number between [0 .. 0xffff] from the input stream.
function decoderMT:readuint16()
	local rep = self:readraw(2)
	return string.unpack("I2", rep)
end

--Reads a number between [0 .. 0xffffffff] from the input stream.
function decoderMT:readuint32()
	local rep = self:readraw(4)
	return string.unpack("I4", rep)
end

--Reads a number between [0 .. 0xffffffffffff] from the input stream.
function decoderMT:readuint64()
	local rep = self:readraw(8);
	return string.unpack("I8", rep)
end

--Reads a number between [-0x8000 .. 0x7fff] from the input stream.
function decoderMT:readint16()
	local rep = self:readraw(2)
	return string.unpack("i2", rep)
end

--Reads a number between [-0x80000000 .. 0x7fffffff] from the input stream.
function decoderMT:readint32()
	local rep = self:readraw(4)
	return string.unpack("i4", rep)
end

--Reads a number between [-0x8000000000000000 .. 0x7fffffffffffffff]  from the input stream.
function decoderMT:readint64()
	local rep = self:readraw(8);
	return string.unpack("i8", rep)
end

--Reads a floting point number of precision 32-bit in 
--IEEE 754 single precision format.
function decoderMT:readsingle()
	local rep = self:readraw(4)
	return string.unpack("f", rep)
end


--Reads a floting point number of precision 64-bit in 
--IEEE 754 double precision format.
function decoderMT:readdouble()
	local rep = self:readraw(8)
	return string.unpack("d", rep)
end

--Reads a boolean value from the stream.
function decoderMT:readbit()
	local rep = self:readbyte();
	if rep == 0 then 
		return false
	else
		return true
	end
end

--Reads a variable integer encoded using the encoding
--employed by google protocol buffers. 
function decoderMT:readvarint()
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
function decoderMT:readvarintzz()
	local zigzaged = self:readvarint()
	return (zigzaged >> 1) ~ (-(zigzaged & 1)) 
	
end

--Closes the decoder.
--After this operation is performed the decoder can no longer be used.
function decoderMT:close()
	self:flush()
end

--Decodes using the specified mapping.
function decoderMT:decode(mapping)
	local meta_types = self:readstring()
	--We should add some type checking here. 
	return mapping:decode(self)
end

--Creates a decoder
function encoding.decoder(inStream)
	local decoder = { stream = inStream}
	setmetatable(decoder, decoderMT)
	return decoder
end

return encoding