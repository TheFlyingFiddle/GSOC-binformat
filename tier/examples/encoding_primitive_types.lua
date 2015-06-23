local encoding  = require"encoding"
local primitive = encoding.primitive

local file = io.open("Numbers.dat")
encoding:encode(file, primitive.byte, 0)
encoding:encode(file, primitive.int16, 1)  
encoding:encode(file, primitive.int32, 2)
encoding:encode(file, primitive.int64, 3)
encoding:encode(file, primitive.uin16, 4)
encoding:encode(file, primitive.uint32, 5)
encoding:encode(file, primitive.uint64, 6)
encoding:encode(file, primitive.float, 7)
encoding:encode(file, primitive.double, 8)
encoding:encode(file, primitive.varint, 9)
encoding:encode(file, primitive.varintzz, 10)
file:close()

local file = io.open("Characters.dat")
encoding:encode(file, primitive.char, "A")
encoding:encode(file, primitive.wchar, "\255a")
file:close()

local file =  io.open("Strings.dat")

encoding:encode(file, primitive.stream, "This is a stream")
encoding:encode(file, primitive.string, "This is a string")
--Wide chars are not that useful from a pure Lua stand point
--But can be very useful if communicating with languages
--whose string types are based on UTF-16.
encoding:encode(file, primitive.wchar, "\255a\255p\255a")
file:close()

local file = io.open("Numbers.dat")
encoding:encode(file, primitive.null, nil)
encoding:encode(file, primitive.void) 
file:close()

local file = io.open("Numbers.dat")
encoding:encode(file, primitive.boolean, true)
file:close()


local file = io.open("Numbers.dat")
encoding:encode(file, primitive.flag, true)
encoding:encode(file, primitive.sign, 1)

encoding:encode(file, primitive.uint3, 2)
encoding:encode(file, primitive.uint7, 100)
encoding:encode(file, primitive.uint13, 1056)

encoding:encode(file, primitive.int3,  -1)
encoding:encode(file, primitive.int7,   -45)
encoding:encode(file, primitive.int13,  -1000)

file:close()