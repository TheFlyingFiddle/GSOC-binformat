local tier  = require"tier"
local primitive = tier.primitive

local file = io.open("Numbers.dat")
tier:encode(file, primitive.byte, 0)
tier:encode(file, primitive.int16, 1)  
tier:encode(file, primitive.int32, 2)
tier:encode(file, primitive.int64, 3)
tier:encode(file, primitive.uin16, 4)
tier:encode(file, primitive.uint32, 5)
tier:encode(file, primitive.uint64, 6)
tier:encode(file, primitive.float, 7)
tier:encode(file, primitive.double, 8)
tier:encode(file, primitive.varint, 9)
tier:encode(file, primitive.varintzz, 10)
file:close()

local file = io.open("Characters.dat")
tier:encode(file, primitive.char, "A")
tier:encode(file, primitive.wchar, "\255a")
file:close()

local file =  io.open("Strings.dat")

tier:encode(file, primitive.stream, "This is a stream")
tier:encode(file, primitive.string, "This is a string")
--Wide chars are not that useful from a pure Lua stand point
--But can be very useful if communicating with languages
--whose string types are based on UTF-16.
tier:encode(file, primitive.wchar, "\255a\255p\255a")
file:close()

local file = io.open("Numbers.dat")
tier:encode(file, primitive.null, nil)
tier:encode(file, primitive.void) 
file:close()

local file = io.open("Booleans.dat")
tier:encode(file, primitive.boolean, true)
file:close()


local file = io.open("Bits.dat")
tier:encode(file, primitive.flag, true)
tier:encode(file, primitive.sign, 1)

tier:encode(file, primitive.uint3, 2)
tier:encode(file, primitive.uint7, 100)
tier:encode(file, primitive.uint13, 1056)

tier:encode(file, primitive.int3,  -1)
tier:encode(file, primitive.int7,   -45)
tier:encode(file, primitive.int13,  -1000)

file:close()