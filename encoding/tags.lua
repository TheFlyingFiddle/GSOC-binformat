local format   = require"format"
local tags     = { }

--Standard empty
tags.VOID    = 0x00  tags[0x00] = "VOID"
tags.NULL    = 0x01  tags[0x01] = "NULL"

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
tags.ALIGN8    = 0x17   tags[0x17] = "ALIGN8"   -- ALIGN 0x08
tags.ALIGN16   = 0x18   tags[0x18] = "ALIGN16"  -- ALIGN 0x10
tags.ALIGN32   = 0x19   tags[0x19] = "ALIGN32"  -- ALIGN 0x20
tags.ALIGN64   = 0x1A   tags[0x1A] = "ALIGN64"  -- ALIGN 0x40

--Common Aliases
--Boleans
tags.BOOLEAN   = 0x1B   tags[0x1B] = "BOOLEAN" -- ALIGN8 UINT 0x08

--Integers
tags.BYTE      = 0x1C   tags[0x1C] = "BYTE"    -- ALIGN8 UINT 0x08
tags.UINT16    = 0x1D   tags[0x1D] = "UINT16"  -- ALIGN8 UINT 0x10
tags.UINT32    = 0x1E   tags[0x1E] = "UINT32"  -- ALIGN8 UINT 0x20
tags.UINT64    = 0x1F   tags[0x1F] = "UINT64"  -- ALIGN8 UINT 0x40
tags.SINT16    = 0x20   tags[0x20] = "SINT16"  -- ALIGN8 SINT 0x10
tags.SINT32    = 0x21   tags[0x21] = "SINT32"  -- ALIGN8 SINT 0x20
tags.SINT64    = 0x22   tags[0x22] = "SINT64"  -- ALIGN8 SINT 0x40

--Floats
tags.SINGLE    = 0x23   tags[0x23] = "SINGLE"  -- SEMANTIC "floating" ALIGN8 UINT 0x20
tags.DOUBLE    = 0x24   tags[0x24] = "DOUBLE"  -- SEMANTIC "floating" ALIGN8 UINT 0x40
tags.QUAD      = 0x25   tags[0x25] = "QUAD"    -- SEMANTIC "floating" ALIGN8 UINT 0x80

--Strings
tags.STREAM    = 0x26   tags[0x26] = "STREAM"   -- LIST size BYTE
tags.STRING    = 0x27   tags[0x27] = "STRING"   -- LIST size CHAR
tags.WSTRING   = 0x28   tags[0x28] = "WSTRING"  -- LIST size WCHAR



--Standard generator functions
function tags.tagtoluatype(tag)
   if tag == tags.VOID or
      tag == tags.NULL then
		return "nil"
   elseif tag == tags.BOOLEAN then
		return "boolean"       
   elseif tag == tags.BYTE or
          tag == tags.UINT16 or
          tag == tags.SINT16 or
          tag == tags.UINT32 or
          tag == tags.SINT32 or
          tag == tags.UINT64 or
          tag == tags.SINT64 or
          tag == tags.SINGLE or
          tag == tags.DOUBLE or
          tag == tags.QUAD   or
          tag == tags.VARINT or
          tag == tags.VARINTZZ then
		return "number"
    elseif tag == tags.CHAR or
           tag == tags.WCHAR or
           tag == tags.STREAM or
           tag == tags.STRING or
           tag == tags.WSTRING then
		return "string"
    elseif tag == tags.LIST or
           tag == tags.SET  or
           tag == tags.ARRAY or
           tag == tags.TUPLE or
           tag == tags.MAP then
		return "table"    
   else	
		return "unkown"
   end
end


return tags