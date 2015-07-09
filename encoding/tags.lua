local format   = require"format"
local tags     = { }

--Standard empty
tags.VOID      = 0x00   tags[0x00] = "VOID"
tags.NULL      = 0x01   tags[0x01] = "NULL"

--Terminated Multi-Byte (ALIGN 0x08)
tags.VARINT    = 0x02   tags[0x02] = "VARINT"
tags.VARINTZZ  = 0x03   tags[0x03] = "VARINTZZ"

--Characters (ALIGN 0x08)
tags.CHAR      = 0x04   tags[0x04] = "CHAR" 
tags.WCHAR     = 0x05   tags[0x05] = "WCHAR"

--Types (ALIGN 0x08)
tags.TYPE      = 0x06   tags[0x06] = "TYPE"
tags.TYPEREF   = 0x07   tags[0x07] = "TYPEREF"
tags.DYNAMIC   = 0x08   tags[0x08] = "DYNAMIC"

--Sub-Byte
tags.UINT      = 0x09   tags[0x09] = "UINT"
tags.SINT      = 0x0A   tags[0x0A] = "SINT"

--Composition (Variable alignment)
tags.ARRAY     = 0x0B   tags[0x0B] = "ARRAY"
tags.TUPLE     = 0x0C   tags[0x0C] = "TUPLE"

--Counted Compositions (Variable alignment)
tags.UNION     = 0x0D   tags[0x0D] = "UNION"
tags.LIST      = 0x0E   tags[0x0E] = "LIST"
tags.SET       = 0x0F   tags[0x0F] = "SET"
tags.MAP       = 0x10   tags[0x10] = "MAP"

--Structure modifiers
tags.ALIGN     = 0x11   tags[0x11] = "ALIGN"
tags.OBJECT    = 0x12   tags[0x12] = "OBJECT"
tags.EMBEDDED  = 0x13   tags[0x13] = "EMBEDDED"
tags.SEMANTIC  = 0x14   tags[0x14] = "SEMANTIC"

--Aliases Bits
tags.FLAG      = 0x15   tags[0x15] = "FLAG" -- UINT 0x00 
tags.SIGN      = 0x16   tags[0x16] = "SIGN" -- SINT 0x00

--Aliases Alignments
tags.ALIGN1   = 0x17   tags[0x17]  = "ALIGN1"  -- ALIGN 0x08
tags.ALIGN2   = 0x18   tags[0x18]  = "ALIGN2"  -- ALIGN 0x10
tags.ALIGN4   = 0x19   tags[0x19]  = "ALIGN4"  -- ALIGN 0x20
tags.ALIGN8   = 0x1A   tags[0x1A]  = "ALIGN8"  -- ALIGN 0x40

--Common Aliases
--Boleans
tags.BOOLEAN   = 0x1B   tags[0x1B] = "BOOLEAN" -- ALIGN1 UINT 0x08

--Unsigned Integers
tags.UINT8     = 0x1C   tags[0x1C] = "UINT8"   -- ALIGN1 UINT 0x08
tags.UINT16    = 0x1D   tags[0x1D] = "UINT16"  -- ALIGN1 UINT 0x10
tags.UINT32    = 0x1E   tags[0x1E] = "UINT32"  -- ALIGN1 UINT 0x20
tags.UINT64    = 0x1F   tags[0x1F] = "UINT64"  -- ALIGN1 UINT 0x40

--Signed Integers
tags.SINT8     = 0x20   tags[0x20] = "SINT8"   -- ALIGN1 UINT 0x08
tags.SINT16    = 0x21   tags[0x21] = "SINT16"  -- ALIGN1 SINT 0x10
tags.SINT32    = 0x22   tags[0x22] = "SINT32"  -- ALIGN1 SINT 0x20
tags.SINT64    = 0x23   tags[0x23] = "SINT64"  -- ALIGN1 SINT 0x40

--Floats
tags.HALF      = 0x24   tags[0x24] = "HALF"    -- SEMANTIC "floating" ALIGN1 UINT 0x10
tags.FLOAT     = 0x25   tags[0x25] = "FLOAT"   -- SEMANTIC "floating" ALIGN1 UINT 0x20
tags.DOUBLE    = 0x26   tags[0x26] = "DOUBLE"  -- SEMANTIC "floating" ALIGN1 UINT 0x40
tags.QUAD      = 0x27   tags[0x27] = "QUAD"    -- SEMANTIC "floating" ALIGN1 UINT 0x80

--Strings
tags.STREAM    = 0x28   tags[0x28] = "STREAM"   -- LIST size BYTE
tags.STRING    = 0x29   tags[0x29] = "STRING"   -- LIST size + 1 CHAR
tags.WSTRING   = 0x2a   tags[0x2a] = "WSTRING"  -- LIST size + 1 WCHAR


local tagToLua =
{
    [tags.UINT]       = "number",
    [tags.UINT8]      = "number",
    [tags.UINT16]     = "number",
    [tags.UINT32]     = "number",
    [tags.UINT64]     = "number",
    [tags.SINT]       = "number",
    [tags.SINT8]      = "number",
    [tags.SINT16]     = "number",
    [tags.SINT32]     = "number",
    [tags.SINT64]     = "number",
    [tags.HALF]       = "number",
    [tags.FLOAT]      = "number",
    [tags.DOUBLE]     = "number",
    [tags.QUAD]       = "number",
    [tags.SIGN]       = "number",
    [tags.VARINT]     = "number",
    [tags.VARINTZZ]   = "number",
    
    [tags.CHAR]    = "string",
    [tags.WCHAR]   = "string",
    [tags.STREAM]  = "string",
    [tags.STRING]  = "string",
    [tags.WSTRING] = "string",
        
    [tags.FLAG]    = "boolean",
    [tags.BOOLEAN] = "boolean",
    
    [tags.VOID] = "nil",
    [tags.NULL] = "nil",

    [tags.LIST]  = "table",
    [tags.SET]   = "table",
    [tags.ARRAY] = "table",
    [tags.TUPLE] = "table",
    [tags.MAP]   = "table"
}

--Standard generator functions
function tags.tagtoluatype(tag)
   local t = tagToLua[tag]
   if t ~= nil then 
      return t;
   else
      return "unkown"
   end
end

return tags