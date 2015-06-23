local format = { }

local Writer = { }
Writer.__index = Writer;

local spack   = string.pack
local sunpack = string.unpack
local tunpack = table.unpack

function Writer:getposition()
   return self.position
end

local function writeraw(writer, string)
      writer.inner:write(string)
      writer.position = writer.position + #string
end

local tmpByteStorage  = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } 
local bytesPack       = { "B", "BB", "BBB", "BBBB", "BBBBB",
                          "BBBBBB", "BBBBBBB", "BBBBBBBB",
                          "BBBBBBBBB", "BBBBBBBBBB" }

local function writevarint(writer, number)
   assert(type(number) == "number", "number expected")
   
   local count = 1
   while number >= 0x80 or number < 0 do
      local byte = (number | 0x80) & 0x00000000000000FF
      number = number >> 7;
      tmpByteStorage[count] = byte
      count = count + 1
   end
   
   tmpByteStorage[count] = number
   writer.inner:write(spack(bytesPack[count], tunpack(tmpByteStorage)))
   writer.position = writer.position + count
end


--Writes the bytes contained in a raw string,
--to the output stream.
function Writer:raw(string)
   self.inner:write(string)
   self.position = self.position + #string
end

--Writes a length delimted stream of bytes
function Writer:stream(s)
   assert(type(s) == "string", "string expected")

   local length = #s
   writevarint(self, length)

   self.inner:write(s)
   self.position = self.position + length
end

--Encodes an integer that is in the range [0 .. 0xff].
function Writer:uint8(byte)
   self.inner:write(spack("B", byte))
   self.position = self.position + 1
end

--Writes an integer that is in the range [0 .. 0xffff].
function Writer:uint16(number)
   self.inner:write(spack("I2", number))
   self.position = self.position + 2
end

--Writes an integer that is in the range [0 .. 0xffffffff].
function Writer:uint32(number)
   self.inner:write(spack("I4", number)  )
   self.position = self.position + 4
end

--Writes an integer that is in the range [0 .. 0xffffffffffffffff].
function Writer:uint64(number)   
   self.inner:write(spack("I8", number))
   self.position = self.position + 8
end

--Writes an integer  that is in the range [-0x80 .. 0x7F]
function Writer:int8(byte)   
   self.inner:write(spack("b", byte))
   self.position = self.position + 1
end


--Writes an integer that is in the range [-0x8000 .. 0x7fff].
function Writer:int16(number)
   self.inner:write(spack("i2", number))
   self.position = self.position + 2
end

--Writes integer that is in the range [-0x80000000 .. 0x7fffffff].
function Writer:int32(number)   
   self.inner:write(spack("i4", number))
   self.position = self.position + 4
end

--Writes an integer that is in the range [-0x8000000000000000 .. 0x7fffffffffffffff].
function Writer:int64(number)
   self.inner:write(spack("i8", number))
   self.position = self.position + 8
end

--Writes a float point value with 32-bit precision in IEEE 754 format.
function Writer:float(number)
   self.inner:write(spack("f", number))
   self.position = self.position + 4
end

--Writes a float point value with 64-bit precision in IEEE 754 format.
function Writer:double(number)
   self.inner:write(spack("d", number))
   self.position = self.position + 8
end

--Writes a number in the variable integer encoding
--used by google protocol buffers. 
Writer.varint = writevarint

--Writes a number in zigzag encoded format 
--used for zigzag variable integer encoding used in 
--google protocol buffers. 
function Writer:varintzz(number)
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
   writevarint(self, zigzaged)
end

--Writes a boolean value.   
function Writer:bool(bool)
   if bool then bool = 1 else bool = 0 end
   self.inner:write(spack("B", bool))
   self.position = self.position + 1
end


--Writes the first size bits in value
function Writer:bits(size, value)
      local count = self.bit_count
	local bits = self.bit_buffer
	local nbytes = 0
      
      bits = bits | (value << count)
	count = count + size
	while count >= 8 do
		count = count - 8
		value = value >> (size-count)
		size = count
            
		nbytes = nbytes + 1
            tmpByteStorage[nbytes] = bits & 0xFF
            
            bits = value
	end
      
	self.bit_count = count
	self.bit_buffer = bits & ~(-1 << count)
      
      if nbytes ~= 0 then 
            writeraw(self, spack(bytesPack[nbytes], tunpack(tmpByteStorage)))
      end
end

--Writes an unsigned integer of (size) bits
function Writer:uint(size, value)
   local max = (1 << size) - 1
   assert(type(value) == "number", "number expected")
   assert(math.type(value) == "integer", "has no integer representation")
   assert((value >= 0 and value <= max) or size == 64, "unsigned overflow ")
   self:bits(size, value)
end

--Writes a signed integer of (size) bits
function Writer:int(size, value)
   assert(type(value) == "number", "number expected")
   assert(math.type(value) == "integer", "has no integer representation")
   local half = 1 << (size - 1)
   
   if value < 0 then
      assert(-half <= value or size == 64, "integer overflow")
      local offset = (1 << size)
      local nval   = offset + value
      self:bits(size, nval)   
   else
      assert(half > value or size == 64, "integer overflow")
      self:bits(size, value)
   end
end

--Flushes any remaining bits in the bitbuffer to the 
--output.
function Writer:flushbits()
   local count = self.bit_count
	if count > 0 then
            writeraw(self, spack("B", self.bit_buffer & 0xFF))
		self.bit_count = 0
		self.bit_buffer = 0
	end
end

local alignbytes = 
{  
   spack("I1", 0), spack("I2", 0),   
   spack("I3", 0), spack("I4", 0),
   spack("I5", 0), spack("I6", 0),  
   spack("I7", 0), spack("I8", 0) 
}

--Alignes the output to the specified number of bytes.
function Writer:align(to)
   local pos     = self.position
   local aligned = pos + (to - 1) & ~(to - 1)
   if aligned > 0 then
      self:flushbits()
      self:raw(alignbytes[aligned - pos])   
   end
end

--Flushes the underlying stream and any bits not yet written.
function Writer:flush()
   self:flushbits()
   self.inner:flush()
end

function format.writer(innerstream)
   local writer = { inner = innerstream }
   writer.position   = 0
   writer.bit_count  = 0
   writer.bit_buffer = 0
   setmetatable(writer, Writer)
   return writer
end

local Reader = { }
Reader.__index = Reader

function Reader:getposition()
   return self.position
end

local function readraw(reader, count)
   reader.position = reader.position + count
   return reader.inner:read(count)
end   

--Reads a string of length count from the input stream.
function Reader:raw(count)
   self:discardbits()
   return readraw(self, count)
end

--Reads a length prefixed stream of bytes from the input stream.
function Reader:stream()
   local size = self:varint()
   self.position = self.position + size
   return self.inner:read(size)
end

--Reads a byte from the input stream.
function Reader:uint8()
   self.position = self.position + 1
   return sunpack("B", self.inner:read(1));	
end

--Reads a number between [0 .. 0xffff] from the input stream.
function Reader:uint16()
   self.position = self.position + 2
   return sunpack("I2", self.inner:read(2))
end

--Reads a number between [0 .. 0xffffffff] from the input stream.
function Reader:uint32()
   self.position = self.position + 4
   return sunpack("I4", self.inner:read(4))
end

--Reads a number between [0 .. 0xffffffffffff] from the input stream.
function Reader:uint64()
   self.position = self.position + 8
   return sunpack("I8", self.inner:read(8))
end

--Reads a signed byte from the input stream.
function Reader:int8()
   self.position = self.position + 1
   return sunpack("b", self.inner:read(1));	
end


--Reads a number between [-0x8000 .. 0x7fff] from the input stream.
function Reader:int16()
   self.position = self.position + 2
   return sunpack("i2", self.inner:read(2))
end

--Reads a number between [-0x80000000 .. 0x7fffffff] from the input stream.
function Reader:int32()
   self.position = self.position + 4
   return sunpack("i4", self.inner:read(4))
end

--Reads a number between [-0x8000000000000000 .. 0x7fffffffffffffff]  from the input stream.
function Reader:int64()
   self.position = self.position + 8
   return sunpack("i8", self.inner:read(8))
end

--Reads a floting point number of precision 32-bit in 
--IEEE 754 single precision format.
function Reader:float()
   self.position = self.position + 4
   return sunpack("f", self.inner:read(4))
end

--Reads a floting point number of precision 64-bit in 
--IEEE 754 double precision format.
function Reader:double()
   self.position = self.position + 8
   return sunpack("d", self.inner:read(8))
end

--Reads a boolean value
function Reader:bool()
   local value = self:byte()
   if value == 1 then
      value = true
   else
      value = false
   end
   return value
end

--Reads a variable integer encoded using the encoding
--employed by google protocol buffers. 
function Reader:varint()
   local number = 0;
   local count  = 0;

   self:discardbits()
   while true do
      local byte = sunpack("B", readraw(self, 1))
      number = number | ((byte & 0x7F) << (7 * count))
      if byte < 0x80 then break end
      count = count + 1;

      if count == 10 then
         --Something is wrong the data is corrupt.
         error("stream is corrupt!");	
      end
   end
    
   return number;
end


--Reads a variable zigzag encoded integer encoded using the 
-- zigzag encoding employed by google protocol buffers. 
function Reader:varintzz()
   local zigzaged = self:varint()
   return (zigzaged >> 1) ~ (-(zigzaged & 1)) 
end

--Reads size bits from the stream.
function Reader:bits(size)
   local count = self.bit_count
   local bits  = self.bit_buffer
   
   local value = 0
   local ready = 0
   while count < size - ready do
      value = value | (bits << ready)
      ready = ready + count
      bits  = sunpack("B", readraw(self, 1))
      count = 8
   end
   
   size = size - ready
   self.bit_count  = count - size
   self.bit_buffer = bits >> size
   return value | ((bits & ~(-1 << size)) << ready)
end

-- Reads an unsigned integer of size bits
function Reader:uint(size)
   return self:bits(size)
end

-- Reads a signed integer of size bits
function Reader:int(size)
   --We need to fix the value
     
   local value    = self:bits(size)
   local sign     = (value >> (size - 1))
   if sign == 1 then
      local max = (1 << size)
      value = -(max - value)
   end
   
   return value
end

--Alignes the stream to the specified byte size
function Reader:align(to) 
   local pos = self.position
   local aligned = pos + (to - 1) & ~(to - 1)
   if extra ~= 0 then
      local toremove = aligned - pos
      self:raw(toremove)
   end
end

--Discards any remaining bits in the bitbuffer.
function Reader:discardbits()
   self.bit_count  = 0
   self.bit_buffer = 0
end

function format.reader(innerstream)
   local reader = { inner = innerstream }
   reader.position   = 0
   reader.bit_count  = 0
   reader.bit_buffer = 0 
   setmetatable(reader, Reader)
   return reader
end

--Packs a number into a string using the varint format.
function format.packvarint(number)
   local s = ""   
   while number >= 0x80 or number < 0 do
      local byte = (number | 0x80) & 0x00000000000000FF
      number = number >> 7;
      s = s .. spack("B", byte)
   end
      
   s = s .. spack("B", number)
   return s;     
end

--Unpacks a number from a string with the varint format.
function format.unpackvarint(str)
   local number = 0;
   local count  = 0;
   while true do
      local byte = string.byte(str, count + 1)
      number = number | ((byte & 0x7F) << (7 * count))
      if byte < 0x80 then break end
      count = count + 1;

      if count == 10 then
         --Something is wrong the data is corrupt.
         error("stream is corrupt!");	
      end
   end
   
   return number, count + 1    
end


local MemoryOutStream = {}
MemoryOutStream.__index = MemoryOutStream

local insert = table.insert
function MemoryOutStream:write(string)
   insert(self.buffer, string)
end

function MemoryOutStream:flush() end

function MemoryOutStream:close() end

local concat = table.concat
function MemoryOutStream:getdata()
   return concat(self.buffer)
end
function format.outmemorystream()
   return setmetatable( { buffer = { } }, MemoryOutStream )
end

local MemoryInStream = { }
MemoryInStream.__index = MemoryInStream
function MemoryInStream:read(count)
      local pos = self.position
      self.position = pos + count
      return string.sub(self.buffer, pos, self.position - 1)
end

function MemoryInStream:close() end

function format.inmemorystream(buffer)
    local stream = setmetatable({}, MemoryInStream)
    stream.buffer   = buffer
    stream.position = 1
    return stream
end

return format