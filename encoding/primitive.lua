local encoding = require"encoding"
local primitives = { }

--Most primitives have a one to one mapping to encoding functions 
--The method reduces some boilerplate.
--It creates a basic encode/decode object that simply forwards to
--the encoder/decoder.
local function createMapper(typeTag, encodeFunc, decodeFunc)
    local primitive = { tag = typeTag }
    function primitive:encode(encoder, value)
        encoder[encodeFunc](encoder, value)
    end
    
    function primitive:decode(decoder)
        return decoder[decodeFunc](decoder)
    end
    return primitive
end

local tags = encoding.tags;

primitives.bit      = createMapper(tags.BIT,       "writebit",       "readbit")
primitives.boolean  = createMapper(tags.BIT,       "writebit",       "readbit")
primitives.byte     = createMapper(tags.BYTE,      "writebyte",      "readbyte")
primitives.varint   = createMapper(tags.VARINT,    "writevarint",    "readvarint")
primitives.varintzz = createMapper(tags.VARINTZZ,  "writevarintzz",  "readvarintzz")
primitives.uint16   = createMapper(tags.UINT16,    "writeuint16",    "readuint16")
primitives.uint32   = createMapper(tags.UINT32,    "writeuint32",    "readuint32")
primitives.uint64   = createMapper(tags.UINT64,    "writeuint64",    "readuint64")
primitives.int16    = createMapper(tags.SINT16,    "writeint16",     "readint16")
primitives.int32    = createMapper(tags.SINT32,    "writeint32",     "readint32")
primitives.int64    = createMapper(tags.SINT64,    "writeint64",     "readint64")
primitives.fpsingle = createMapper(tags.SINGLE,    "writesingle",    "readsingle")
primitives.fpdouble = createMapper(tags.DOUBLE,    "writedouble",    "readdouble")

--Not yet implemented primitives.fpquad = createMapper(QUAD, "writequad", "readquad");
primitives.stream   = createMapper(tags.STREAM, "writestring", "readstring")
primitives.string   = createMapper(tags.STRING, "writestring", "readstring")


--Void and null does not do anything so they do not have a one to one
--mapping thus we need to create the mapper manually. 
local Void = { tag = tags.VOID }
function Void:encode(encoder, value) end
function Void:decode(decoder) return nil end
primitives.void = Void

local Null = { tag = tags.NULL }
function Null:encode(encoder, value) end
function Null:decode(decoder) return nil end

primitives.null = Null

--CHAR should read as a 1 char string.
local Char = { tag = tags.CHAR }
function Char:encode(encoder, value)
    assert(string.len(value) == 1, "invalid character")
    encoder:writeraw(value)
end
function Char:decode(decoder)
    return decoder:readraw(1)
end

primitives.char = Char

local WChar = { tag = tags.WCHAR }
function WChar:encode(encoder, value)
    assert(string.len(value) == 2, "invalid wide character")
    encoder:writeraw(value)
end

function WChar:decode(decoder)
    return decoder:readraw(2)        
end

primitives.wchar = WChar

--The wstring does not have a onetoone mapping with an encoding/decoding function.
--Thus we need to create the mapper manually.
local WString = { tag = tags.WSTRING }
function WString:encode(encoder, value)
    local length = string.len(value)
    assert(length %2 == 0, "invalid wide string")
    encoder:writevarint(length)
    encoder:writeraw(value)
end

function WString:decode(decoder)
    local length = decoder:readvarint()
    return decoder:readraw(length)
end
primitives.wstring = WString;

--TIME and DATE would be nice to have. 
--Initialy i am thinking of time as long nanoseconds from 1970
--and DATE to be some int type i guess. 


return primitives