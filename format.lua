local format = { }

local Writer = { }
Writer.__index = Writer;

function Writer:writeraw(string)
   self.inner:write(string)
   self.position = self.position + #string
end

function Writer:writestring(s)
   local length = string.len(s)
   self:writevarint(length)
   self:writeraw(s)
end

function Writer:writebyte(byte)
   local rep = string.pack("B", byte)
   self:writeraw(rep);
end

function Writer:writeuint16(number)
   local rep = string.pack("I2", number)
   self:writeraw(rep);
end

function Writer:writeuint32(number)
   local rep = string.pack("I4", number)
   self:writeraw(rep);
end

function Writer:writeuint64(number)
   local rep = string.pack("I8", number)
   self:writeraw(rep);
end

function Writer:writeint16(number)
   local rep = string.pack("i2", number)
   self:writeraw(rep)	
end

function Writer:writeint32(number)
   local rep = string.pack("i4", number)
   self:writeraw(rep)
end

function Writer:writeint64(number)
   local rep = string.pack("i8", number)
   self:writeraw(rep)
end

function Writer:writesingle(number)
   local rep = string.pack("f", number)
   self:writeraw(rep)
end

function Writer:writedouble(number)
   local rep = string.pack("d", number);
   self:writeraw(rep);
end

function Writer:writevarint(number)
   while number >= 0x80 or number < 0 do
      local byte = (number | 0x80) & 0x00000000000000FF
      number = number >> 7;
      self:writebyte(byte);
   end
   
   self:writebyte(number)
end

function Writer:writevarintzz(number)
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

function Writer:writebits(size, value)
   local count = self.bit_count
	local bits = self.bit_buffer
	bits = bits | value << count
	count = count + size
	while count >= 8 do
		count = count - 8
		value = value >> (size-count)
		size = count
		self:writebyte(bits & 0xFF)
		bits = value
	end
	self.bit_count = count
	self.bit_buffer = bits & ~(-1 << count)
end

function Writer:writeuint(size, value)
   self:writebits(size, value)
end

function Writer:writeint(size, value)
   local sign
   if value < 0 then sign = 1 else sign = 0 end
       
   local signbit = (sign << (size - 1))
   local val     = value | signbit     --I think this is correct
   self:writebits(size, val)
end

function Writer:flushbits()
   local count = self.bit_count
	if count > 0 then
		self:writebyte(self.bit_buffer & 0xFF)
		self.bit_count = 0
		self.bit_buffer = 0
	end
end

local alignbytes = 
{  
   string.pack("I1", 0), string.pack("I2", 0),   
   string.pack("I3", 0), string.pack("I4", 0),
   string.pack("I5", 0), string.pack("I6", 0),  
   string.pack("I7", 0), string.pack("I8", 0) 
}

function Writer:align(to)
   local extra = self.position % to
   
   self:flushbits()
   if extra ~= 0 then
      self:writeraw(alignbytes[to - extra + 1])   
   end
end

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

--These functions assume that the stream is byte aligned. 
function Reader:readraw(count)
   self.position = self.position + count;
   return self.inner:read(count);
end

function Reader:readstring()
   local size = self:readvarint()
   return self:readraw(size); 
end

function Reader:readbyte()
   self:align(1)
   local rep = self:readraw(1);
   return string.unpack("B", rep);	
end

function Reader:readuint16()
   local rep = self:readraw(2)
   return string.unpack("I2", rep)
end

function Reader:readuint32()
   local rep = self:readraw(4)
   return string.unpack("I4", rep)
end

function Reader:readuint64()
   local rep = self:readraw(8);
   return string.unpack("I8", rep)
end

function Reader:readint16()
   local rep = self:readraw(2)
   return string.unpack("i2", rep)
end

function Reader:readint32()
   local rep = self:readraw(4)
   return string.unpack("i4", rep)
end

function Reader:readint64()
   local rep = self:readraw(8);
   return string.unpack("i8", rep)
end

function Reader:readsingle()
   local rep = self:readraw(4)
   return string.unpack("f", rep)
end

function Reader:readdouble()
   local rep = self:readraw(8)
   return string.unpack("d", rep)
end

function Reader:readvarint()
   local number = 0;
   local count  = 0;
   while true do
      local byte = self:readbyte()
      number = number | ((byte & 0x7F) << (7 * count))
      if byte < 0x80 then break end
      count = count + 1;

      if count == 10 then
         --Something is wrong the data is corrupt.
         error("stream is corrupt!");	
      end
   end
   
   self.position = self.position + count + 1      
   return number;
end

function Reader:readvarintzz()
   local zigzaged = self:readvarint()
   return (zigzaged >> 1) ~ (-(zigzaged & 1)) 
end

function Reader:readbits(size)
   local count = self.bit_count
   local bits  = self.bit_buffer
   
   local value = 0
   local ready = 0
   while count < size - ready do
      value = value | (bits << ready)
      ready = ready + count
      bits  = self:readbyte()
      count = 8
   end
   
   size = size - ready
   self.bit_count  = count - size
   self.bit_buffer = bits >> size
   return value | ((bits & ~(-1 << size)) << ready)
end

function Reader:readuint(size)
   return self:readbits(size)
end

function Reader:readint(size)
   --We need to fix the value
   local value    = self:readbits(size)
   local sign     = value >> (size - 1)
   local signmask = ~(sign << (size - 1))
   value = (sign << 63) | (signmask & value)
   return value
end

function Reader:align(to) --Can only align to bytes
   local extra = self.position % to
     
   self:discardbits()
   if extra ~= 0 then
      local toremove = to - extra
      self:readraw(toremove)
   end
end

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


function format.packvarint(number)
   local s = ""   
   while number >= 0x80 or number < 0 do
      local byte = (number | 0x80) & 0x00000000000000FF
      number = number >> 7;
      s = s .. string.pack("B", byte)
   end
      
   s = s .. string.pack("B", number)
   return s;     
end

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


return format