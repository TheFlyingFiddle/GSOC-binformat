local encoding = require"encoding"
local primitives = { }

--Most primitives have a one to one mapping to encoding functions 
--The method reduces some boilerplate.
local function createMapper(typeTag, encodeFunc, decodeFunc)
	local primitive = { tag = typeTag }
	function primitive:encode(encoder, value)
		encoder[encodeFunc](encoder, value)
	end
	
	function primitive:decode(decoder)
		local val = decoder[decodeFunc](decoder)
		return val
	end
	
	return primitive
end

local tags = encoding.tags;

local Void = { tag = tags.VOID }
function Void:encode(encoder, value) end
function Void:decode(decoder) return nil end

primitives.void = Void
primitives.null = Void
primitives.bit 		= createMapper(tags.BIT, 	"writebit", "readbit")
primitives.boolean 	= createMapper(tags.BIT, 	"writebit", "readbit")
primitives.byte     = createMapper(tags.BYTE, 	"writebyte", "readbyte")
primitives.varint   = createMapper(tags.VARINT,	"writevarint", "readvarint")
primitives.varintzz = createMapper(tags.VARINTZZ,"writevarintzz", "readvarintzz")
primitives.uint16   = createMapper(tags.UINT16, 	"writeuint16", "readuint16")
primitives.uint32   = createMapper(tags.UINT32, 	"writeuint32", "readuint32")
primitives.uint64   = createMapper(tags.UINT64,  "writeuint64", "readuint64")
primitives.int16	= createMapper(tags.SINT16, 	"writeint16", "readint16")
primitives.int32    = createMapper(tags.SINT32, 	"writeint32", "readint32")
primitives.int64	= createMapper(tags.SINT64,	"writeint64", "readint64")
primitives.fpsimple = createMapper(tags.SINGLE,  "writesingle", "readsingle")
primitives.fpdouble = createMapper(tags.DOUBLE,	"writedouble", "readdouble")

--Not yet implemented primitives.fpquad = createMapper(QUAD, "writequad", "readquad");
primitives.char  	= createMapper(tags.CHAR, "writebyte", "readbyte")
primitives.wchar 	= createMapper(tags.WCHAR, "writeint16", "readint16")
primitives.stream 	= createMapper(tags.STREAM, "writestring", "readstring")
primitives.string   = createMapper(tags.STRING, "writestring", "readstring")

local WString = { tag = tags.WSTRING }
function WString:encode(encoder, value)
	local length = string.len(value)
	encoder:writevarint(length)
	for i=1, length, 1 do
		local char = string.byte(value, i)
		encoder:writeint16(char)
	end
end

function WString:decode(decoder)
	local length = decoder:readvarint();
	local array  = { }
	for i=1,length,1 do
		local char = decoder:readint16()
		array[i] = string.char(char);
	end	
	
	return table.concat(array)	
end

primitives.wstring = WString;

return primitives