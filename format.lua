local format = { }

local Writer = { }
Writer.__index = Writer;

function Writer:writeraw(string)
   self.inner:write(string)
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

function Writer:writebit(bit)
   local number = 0;
   if bit then number = 1 end
   local rep = string.pack("B", number)
   self:writeraw(rep)
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


function Writer:flush()
   self.inner:flush()
end

function format.writer(innerstream)
   local writer = { inner = innerstream }
   setmetatable(writer, Writer)
   return writer
end

local Reader = { }
Reader.__index = Reader

function Reader:readraw(count)
   return self.inner:read(count);
end

function Reader:readstring()
   local size = self:readvarint()
   return self:readraw(size); 
end

function Reader:readbyte()
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

function Reader:readbit()
   local rep = self:readbyte();
   if rep == 0 then 
      return false
   else
      return true
   end
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
   return number;
end

function Reader:readvarintzz()
   local zigzaged = self:readvarint()
   return (zigzaged >> 1) ~ (-(zigzaged & 1)) 
end

function format.reader(innerstream)
   local reader = { inner = innerstream }
   setmetatable(reader, Reader)
   return reader
end


return format