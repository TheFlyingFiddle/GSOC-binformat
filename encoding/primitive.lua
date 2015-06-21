local tags   = require"encoding.tags"
local format = require"format"

local primitive = { }

local pack = format.packvarint

--Most primitive have a one to one mapping to encoding functions 
--The method reduces some boilerplate.
--It creates a basic encode/decode object that simply forwards to
--the encoder/decoder.
local function createMapper(typeTag, func)
    local primitive = { tag = typeTag, id = pack(typeTag) }
    function primitive:encode(encoder, value)
        local writer = encoder.writer
        writer[func](writer, value)
    end
    
    function primitive:decode(decoder)
        local reader = decoder.reader
        return reader[func](reader)
    end
    return primitive
end

--Need to enforce alignment restrictions here
primitive.byte     = createMapper(tags.BYTE,      "uint8")
primitive.varint   = createMapper(tags.VARINT,    "varint")
primitive.varintzz = createMapper(tags.VARINTZZ,  "varintzz")
primitive.uint16   = createMapper(tags.UINT16,    "uint16")
primitive.uint32   = createMapper(tags.UINT32,    "uint32")
primitive.uint64   = createMapper(tags.UINT64,    "uint64")
primitive.int16    = createMapper(tags.SINT16,    "int16")
primitive.int32    = createMapper(tags.SINT32,    "int32")
primitive.int64    = createMapper(tags.SINT64,    "int64")
primitive.fpsingle = createMapper(tags.SINGLE,    "float")
primitive.fpdouble = createMapper(tags.DOUBLE,    "double")

--Not yet implemented primitive.fpquad = createMapper(QUAD, "writequad", "readquad");
primitive.stream   = createMapper(tags.STREAM, "stream")

--Void should be interpreted as NO VALUE
local Void = { tag = tags.VOID, id = pack(tags.VOID) }
function Void:encode(encoder, value) end
function Void:decode(decoder) end

--Null should be interpreted as nil value. 
local Null = { tag = tags.NULL, id = pack(tags.NULL) }
function Null:encode(encoder, value) assert(value == nil, "nil expected") end
function Null:decode(decoder) return nil end

local Bool = { tag = tags.BOOLEAN, id = pack(tags.BOOLEAN) }
function Bool:encode(encoder, value)
    if value then
        encoder.writer:uint8(1)     
    else 
        encoder.writer:uint8(0)
    end
end

function Bool:decode(decoder)
    local val = decoder.reader:uint8();
    if val == 1 then 
        return true
    else
        return false
    end
end


--CHAR should read as a 1 char string.
local Char = { tag = tags.CHAR, id = pack(tags.CHAR)}
function Char:encode(encoder, value)
    assert(string.len(value) == 1, "invalid character")
    encoder.writer:raw(value)
end

function Char:decode(decoder)
    return decoder.reader:raw(1)
end

--WCHAR is interpreted as a 2 bytes long string.
local WChar = { tag = tags.WCHAR , id = pack(tags.WCHAR)}
function WChar:encode(encoder, value)
    assert(string.len(value) == 2, "invalid wide character")
    encoder.writer:raw(value)
end
function WChar:decode(decoder)
    return decoder.reader:raw(2)        
end

--All strings are null terminated. Thus they cannot use the standard 
--reader:stream() or writer:stream(str)
local String = { tag = tags.STRING, id = pack(tags.STRING)}
function String:encode(encoder, value)
    local len = string.len(value) + 1
    encoder.writer:varint(len)
    encoder.writer:raw(value)
    encoder.writer:raw("\0") --Add null terminator
end

function String:decode(decoder)
    local len = decoder.reader:varint()
    local val = decoder.reader:raw(len - 1)
    decoder.reader:raw(1) --Discard null terminator
    return val
end

--The wstring does not have a one-to-one mapping with an encoding/decoding function.
--Thus we need to create the mapper manually.
local WString = { tag = tags.WSTRING , id = pack(tags.WSTRING)}
function WString:encode(encoder, value)
    local length = string.len(value)
    assert(length %2 == 0, "invalid wide string")
    encoder.writer:varint(length / 2 + 1)
    encoder.writer:raw(value)
    encoder.writer:raw('\000\000') --Add null terminator
end

function WString:decode(decoder)
    local length = decoder.reader:varint() * 2
    local string = decoder.reader:raw(length - 2)
    decoder.reader:raw(2) --Discard null terminator
    return string
end

--Flag maps to true/false and behavies like boolean. 
local Flag = { tag = tags.FLAG, id = pack(tags.FLAG)}
function Flag:encode(encoder, value)
    encoder.writer:uint(1, value and 1 or 0)
end

function Flag:decode(decoder)
    return decoder.reader:uint(1) ~= 0
end

--Sign maps from a number to -1 or 1.
local Sign = { tag = tags.SIGN, id = pack(tags.SIGN)}
function Sign:encode(encoder, value)
    encoder.writer:uint(1, value < 0 and 1 or 0)
end

function Sign:decode(decoder)
    return decoder.reader:uint(1) ~= 0 and -1 or 1
end

primitive.void 		= Void
primitive.null 		= Null
primitive.boolean   = Bool
primitive.char 		= Char
primitive.wchar 	= WChar
primitive.string 	= String
primitive.wstring	= WString
primitive.flag		= Flag
primitive.sign		= Sign

local function createBitInts(tag, name, count)
    for i=1, count do
        if not primitive[name .. i] then
            local mapping = {  }
            mapping.tag = tag 
            mapping.bitsize = i
            mapping.id  = pack(tag) .. pack(i)
            function mapping:encode(encoder, value)
                local writer = encoder.writer;
                writer[name](writer, i, value)
            end
            
            function mapping:decode(decoder)
                local reader = decoder.reader
                return reader[name](reader, i)            
            end
            
            primitive[name .. i] = mapping
        end
    end
end

createBitInts(tags.UINT, "uint", 64)
createBitInts(tags.SINT, "int",  64)

return primitive