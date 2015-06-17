local format = require"c.cformat"

local writer = format.writer();
writer:int8(10);
writer:int16(20);
writer:int32(30);
writer:int64(40);
writer:uint8(50);
writer:uint16(60);
writer:uint32(70);
writer:uint64(80);
writer:float(90.0);
writer:double(100.0);
writer:varint(110);
writer:varintzz(120);
writer:close();

local reader = format.reader();
assert(reader:int8()  == 10);
assert(reader:int16()  == 20);
assert(reader:int32()  == 30);
assert(reader:int64()  == 40);
assert(reader:uint8()	 == 50);
assert(reader:uint16() == 60);
assert(reader:uint32() == 70);
assert(reader:uint64() == 80);
assert(reader:float()  == 90.0);
assert(reader:double() == 100.0);
assert(reader:varint() == 110);
assert(reader:varintzz() == 120);
