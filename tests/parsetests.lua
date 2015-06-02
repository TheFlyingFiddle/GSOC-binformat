local parser  	= require"encoding.parser"

local validParseTexts = 
{
	"TUPLE 03 VARINT STRING BIT",
	"MAP LIST OBJECT SET VARINT EMBEDDED LIST STRING",
	"SEMANTIC nanotime UINT64",
	"VOID",
	"MAP DYNAMIC DYNAMIC",
	"UNION 05 VOID BOOLEAN STRING DOUBLE OBJECT MAP TYPEREF 07 TYPEREF 09"
}

local invalidParseTexts = 
{
	--Some invalid parse texts here.
	--"TUPLE 03 VARINT STRING",
	--"MAP TYPEREF 02 TYPEREF 03"
}

local function testValidParses(texts)
	for i, t in ipairs(texts) do
		--Could use some additional validation here
		parser.parsestring(t)
	end
end

local function testInvalidParses(texts)
	for i, t in ipairs(texts) do
		local status, err = pcall(parser.parsestring, t)
		if status then
			error("Should not have parsed " .. err .. " sucessfully!")
		end
	end
end


testValidParses(validParseTexts)
testInvalidParses(invalidParseTexts)