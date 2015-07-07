local format    = require"format"
local tags      = require"encoding.tags"
local custom	= require"encoding.custom"
local primitive = require"encoding.primitive"
local util      = require"encoding.util"
local core      = require"encoding.core"

local spack     = string.pack
local sunpack   = string.unpack
local tunpack   = table.unpack

local pack      = format.packvarint
local writemeta = core.writemeta
local function writesize(writer, bits, size)
    if bits == 0 then
       writer:varint(size)
    else
       writer:uint(bits, size) 
    end
end

local function readsize(reader, bits)
    if bits == 0 then
        return reader:varint()
    else
        return reader:uint(bits)
    end
end

local optimal = { }

local NumberList = { }
NumberList.__index = NumberList

function NumberList:encode(encoder, value)
    local size = #value
    writesize(encoder.writer, self.sizebits, size)
    
    local writer    = encoder.writer
    local raw_write = writer.raw
    
    local packed = self.packed
    local count  = self.count
    local singlefmt = self.singlefmt
    local fmtstring = self.fmtstring
    for i=0, size - 1, count do
        for j=1, count do
            packed[j] = value[i + j]
        end
        raw_write(writer, spack(fmtstring, tunpack(packed)))
    end
    
    local left = size - (size % count)
    for i=left, size - 1 do
        raw_write(writer, spack(singlefmt, value[i]))
    end
end

function NumberList:decode(decoder)
    local size  = readsize(decoder.reader, self.sizebits)
    local value = { }
    
    local read_func   = self.read_func
    local fmtstring   = self.fmtstring
    local singlefmt   = self.singlefmt
    local count       = self.count
    local elemsize    = self.elemsize 
    local packsize    = elemsize * count
    
    local reader      = decoder.reader
    local raw_read    = reader.raw
    for i=0, size - 1, count do
        read_func(value, i + 1, sunpack, fmtstring, raw_read, reader, packsize)
    end
    
    local left = size - (size % count)
    for i=left, size - 1 do
        value[i] = sunpack(singlefmt, raw_read(reader, elemsize))
    end
    
    return value
end

function optimal.number_list(fmt, count, sizebits)
    if sizebits == nil then sizebits = 0 end

    local list = setmetatable({ }, NumberList)
    list.tag = tags.LIST
    list.id  = pack(tags.LIST) .. pack(0x02) .. pack(0x00) .. pack(tags.FLOAT)
    list.singlefmt = fmt
    list.sizebits  = sizebits
    
    local fstring = ""
    for i=1, count do
        fstring = fstring .. fmt
    end
    
    list.fmtstring = fstring
    list.elemsize  = string.packsize(fmt)
    list.packed    = { }
    list.count     = count
    --Should be a way to do what I want in Lua...
    local read_values = "local function read_the_values(value, i, sup, fstr, rr, reader, ps) \n\t"
    for i=0, count - 1 do
        read_values = read_values .. " value[i + " .. i .. "]"
        if i ~= count - 1 then
            read_values = read_values .. ", \n\t"
        end
    end
    
    read_values = read_values .. " = sup(fstr, rr(reader, ps)) \nend \nreturn read_the_values"
    list.read_func = load(read_values)()
    
    return list    
end

return optimal