
local tags     = { }

--Standard empty
tags.VOID    = string.pack("B", 0x00) 
tags.NULL    = string.pack("B", 0x01) 

--Terminated Multi-Byte (ALIGN 0x08)
tags.VARINT    = string.pack("B",  0x03)
tags.VARINTZZ  = string.pack("B",  0x04)

--Characters (ALIGN 0x08)
tags.CHAR      = string.pack("B", 0x05)
tags.WCHAR     = string.pack("B", 0x06)

--Types (ALIGN 0x08)
tags.TYPE      = string.pack("B", 0x07)
tags.TYPEREF   = string.pack("B", 0x08)
tags.DYNAMIC   = string.pack("B", 0x09)

--Sub-Byte
tags.UINT      = string.pack("B", 0x0A)
tags.SINT      = string.pack("B", 0x0B)

--Composition (Variable alignment)
tags.ARRAY     = string.pack("B", 0x0C)
tags.TUPLE     = string.pack("B", 0x0D)

--Counted Compositions (Variable alignment)
tags.UNION     = string.pack("B", 0x0E)
tags.LIST      = string.pack("B", 0x0F)
tags.SET       = string.pack("B", 0x10)
tags.MAP       = string.pack("B", 0x11)

--Structure modifiers
tags.ALIGN     = string.pack("B", 0x12)
tags.OBJECT    = string.pack("B", 0x13)
tags.EMBEDDED  = string.pack("B", 0x14)
tags.SEMANTIC  = string.pack("B", 0x15)

--Aliases Bits
tags.FLAG      = string.pack("B", 0x16) -- UINT 0x00 
tags.SIGN      = string.pack("B", 0x17) -- SINT 0x00

--Aliases Alignments
tags.ALIGN8    = string.pack("B", 0x18) -- ALIGN 0x08
tags.ALIGN16   = string.pack("B", 0x19) -- ALIGN 0x10
tags.ALIGN32   = string.pack("B", 0x1A) -- ALIGN 0x20
tags.ALIGN64   = string.pack("B", 0x1B) -- ALIGN 0x40

--Common Aliases

--Boleans
tags.BOOLEAN   = string.pack("B", 0x1C) -- ALIGN0 FLAG ALIGN 0x08 So we can use this inside a byte but that byte is then aligned to 8bits

--Integers
tags.BYTE      = string.pack("B", 0x1D) -- ALIGN8 UINT 0x08
tags.UINT16    = string.pack("B", 0x1F) -- ALIGN8 UINT 0x10
tags.UINT32    = string.pack("B", 0x20) -- ALIGN8 UINT 0x20
tags.UINT64    = string.pack("B", 0x21) -- ALIGN8 UINT 0x40
tags.SINT16    = string.pack("B", 0x22) -- ALIGN8 SINT 0x10
tags.SINT32    = string.pack("B", 0x23) -- ALIGN8 SINT 0x20
tags.SINT64    = string.pack("B", 0x24) -- ALIGN8 SINT 0x40

--Floats
tags.SINGLE    = string.pack("B", 0x25) -- SEMANTIC "floating" ALIGN8 UINT 0x20
tags.DOUBLE    = string.pack("B", 0x26) -- SEMANTIC "floating" ALIGN8 UINT 0x40
tags.QUAD      = string.pack("B", 0x27) -- SEMANTIC "floating" ALIGN8 UINT 0x80

--Strings
tags.STREAM    = string.pack("B", 0x28) -- LIST size BYTE
tags.STRING    = string.pack("B", 0x29) -- LIST size CHAR
tags.WSTRING   = string.pack("B", 0x2A) -- LIST size WCHAR


function tags.tagstring(tag)
   for k,v in pairs(tags) do
      if v == tag then
         return k
      end
   end
   
   return "Tag not found"
end


--Standard generator functions
function tags.tagtoluatype(tag)
   if tag == tags.VOID or
      tag == tags.NULL then
		return "nil"
   elseif tag == tags.BIT or
          tag == tags.BOOLEAN then
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