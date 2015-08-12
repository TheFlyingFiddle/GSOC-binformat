local meta   = require"tier.meta"
local format = require"format"

local primitive = { }

local pack = format.packvarint

--Most primitive have a one to one mapping to tier functions 
--The method reduces some boilerplate.
--It creates a basic encode/decode object that simply forwards to
--the encoder/decoder.
local function createMapper(meta, fmt)
    local primitive = { meta = meta }
    function primitive:encode(encoder, value)
        encoder.writer:writef(fmt, value)
    end
    function primitive:decode(decoder)
        return decoder.reader:readf(fmt)
    end
    return primitive
end


--Void should be interpreted as NO VALUE
local Void = { meta = meta.void }
function Void:encode(encoder, value) end
function Void:decode(decoder) end

--Null should be interpreted as nil value. 
local Null = { meta = meta.null }
function Null:encode(encoder, value) assert(value == nil, "nil expected") end
function Null:decode(decoder) return nil end

--Boolean maps true/false.
local Bool = { meta = meta.boolean }
function Bool:encode(encoder, value)
    encoder:writef("B", value and 1 or 0)
end
function Bool:decode(decoder)
    return decoder:readf("B") ~= 0
end

--Flag maps to true/false and behavies like boolean. 
local Flag = { meta = meta.flag }
function Flag:encode(encoder, value)
    encoder:writef("P", 1, value and 1 or 0)
end

function Flag:decode(decoder)
    return decoder:readf("P", 1) ~= 0
end

--Sign maps from a number to -1 or 1.
local Sign = { meta = meta.sign }
function Sign:encode(encoder, value)
    encoder:writef("P", 1, value < 0 and 1 or 0)
end

function Sign:decode(decoder)
    return decoder:readf("P", 1) ~= 0 and -1 or 1
end

--CHAR should read as a 1 char string.
local Char = { meta = meta.char }
function Char:encode(encoder, value)
    assert(string.len(value) == 1, "invalid character")
    encoder:writef("r", value)
end
function Char:decode(decoder)
    return decoder:readf("r", 1)
end

--WCHAR is interpreted as a 2 bytes long string.
local WChar = { meta = meta.wchar }
function WChar:encode(encoder, value)
    assert(string.len(value) == 2, "invalid wide character")
    encoder:writef("r", value)
end

function WChar:decode(decoder)
    return decoder:readf("r", 2)
end

--All strings are null terminated. Thus they cannot use the standard 
--reader:stream() or writer:stream(str)
local String = { meta = meta.string }
function String:encode(encoder, value)
    encoder:writef("V", string.len(value) + 1)
    encoder:writef("r", value)
    encoder:writef("r", "\0")
end

function String:decode(decoder)
    local len = decoder:readf("V")
    local val = decoder:readf("r", len - 1)
    decoder:readf("r", 1)
    return val
end

--The wstring does not have a one-to-one mapping with an tier/decoding function.
--Thus we need to create the mapper manually.
local WString = { meta = meta.wstring}
function WString:encode(encoder, value)
    local length = string.len(value)
    assert(length %2 == 0, "invalid wide string")

    encoder:writef("V", length / 2 + 1)
    encoder:writef("r", value)
    encoder:writef("r", '\000\000') --Add null terminator
end

function WString:decode(decoder)
    local length = decoder:readf("V") * 2
    local string = decoder:readf("r", length - 2)
    decoder:readf("r", 2) --Discard null terminator
    return string
end

local Dynamic = { meta = meta.dynamic }

function Dynamic:encode(encoder, value, mapping)
    meta.encodetype(encoder, mapping.meta)
    mapping:encode(encoder, value)
end 

function Dynamic:decode(decoder, mapping)
    local decoded_meta = meta.decodetype(decoder)
    assert(meta.typecheck(decoded_meta, mapping.meta))
    return mapping:decode(decoder)
end 

primitive.varint   = createMapper(meta.varint,   "V")
primitive.varintzz = createMapper(meta.varintzz, "v")
primitive.uint8    = createMapper(meta.uint8,    "B")
primitive.uint16   = createMapper(meta.uint16,   "H")
primitive.uint32   = createMapper(meta.uint32,   "I")
primitive.uint64   = createMapper(meta.uint64,   "L")
primitive.int8     = createMapper(meta.sint8,    "b")
primitive.int16    = createMapper(meta.sint16,   "h")
primitive.int32    = createMapper(meta.sint32,   "i")
primitive.int64    = createMapper(meta.sint64,   "l")
primitive.float    = createMapper(meta.float,    "f")
primitive.double   = createMapper(meta.double,   "d")
primitive.stream   = createMapper(meta.stream,   "s")

--Not yet implemented primitive.half = createMapper(tags.HALF, "half")
--Not yet implemented primitive.quad = createMapper(tags.QUAD, "quad");


primitive.void 		= Void
primitive.null 		= Null
primitive.boolean   = Bool
primitive.flag      = Flag
primitive.sign      = Sign
primitive.char 		= Char
primitive.wchar 	= WChar
primitive.string 	= String
primitive.wstring	= WString
primitive.dynamic   = Dynamic

return primitive
