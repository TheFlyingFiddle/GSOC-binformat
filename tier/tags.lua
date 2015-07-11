local tags = {
	--Standard empty
	VOID     = 0x00,
	NULL     = 0x01,
	--Terminated Multi-Byte (ALIGN 0x08)
	VARINT   = 0x02,
	VARINTZZ = 0x03,
	--Characters (ALIGN 0x08)
	CHAR     = 0x04, 
	WCHAR    = 0x05,
	--Types (ALIGN 0x08)
	TYPE     = 0x06,
	TYPEREF  = 0x07,
	DYNAMIC  = 0x08,
	--Sub-Byte
	UINT     = 0x09,
	SINT     = 0x0a,
	--Composition (Variable alignment)
	ARRAY    = 0x0b,
	TUPLE    = 0x0c,
	UNION    = 0x0d,
	--Counted Compositions (Variable alignment)
	LIST     = 0x0e,
	SET      = 0x0f,
	MAP      = 0x10,
	--Structure modifiers
	ALIGN    = 0x11,
	OBJECT   = 0x12,
	EMBEDDED = 0x13,
	SEMANTIC = 0x14,
	--Aliases Bits
	FLAG     = 0x15, -- UINT 0x00 
	SIGN     = 0x16, -- SINT 0x00
	--Aliases Alignments
	ALIGN1   = 0x17, -- ALIGN 0x08
	ALIGN2   = 0x18, -- ALIGN 0x10
	ALIGN4   = 0x19, -- ALIGN 0x20
	ALIGN8   = 0x1a, -- ALIGN 0x40
	--Common Aliases
	--Boleans
	BOOLEAN  = 0x1b, -- ALIGN1 UINT 0x08
	--Unsigned Integers
	UINT8    = 0x1c, -- ALIGN1 UINT 0x08
	UINT16   = 0x1d, -- ALIGN1 UINT 0x10
	UINT32   = 0x1e, -- ALIGN1 UINT 0x20
	UINT64   = 0x1f, -- ALIGN1 UINT 0x40
	--Signed Integers
	SINT8    = 0x20, -- ALIGN1 UINT 0x08
	SINT16   = 0x21, -- ALIGN1 SINT 0x10
	SINT32   = 0x22, -- ALIGN1 SINT 0x20
	SINT64   = 0x23, -- ALIGN1 SINT 0x40
	--Floats
	HALF     = 0x24, -- SEMANTIC "floating" ALIGN1 UINT 0x10
	FLOAT    = 0x25, -- SEMANTIC "floating" ALIGN1 UINT 0x20
	DOUBLE   = 0x26, -- SEMANTIC "floating" ALIGN1 UINT 0x40
	QUAD     = 0x27, -- SEMANTIC "floating" ALIGN1 UINT 0x80
	--Strings
	STREAM   = 0x28, -- LIST size BYTE
	STRING   = 0x29, -- LIST size + 1 CHAR
	WSTRING  = 0x2a, -- LIST size + 1 WCHAR
}

local temp = {}
for name, code in pairs(tags) do
	temp[code] = name
end
for code, name in pairs(temp) do
	tags[code] = name
end

return tags
