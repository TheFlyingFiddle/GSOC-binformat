local format    = require"format"
local tags      = require"tier.tags"
local custom	= require"tier.custom"
local primitive = require"tier.primitive"
local util      = require"tier.util"
local core      = require"tier.core"

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
    
    local writer     = encoder.writer
    local raw_write  = writer.raw
    local write_func = self.write_func
    local count  = self.count
    local singlefmt = self.singlefmt
    local fmtstring = self.fmtstring
    if size >= count then
        for i=0, size - 1, count do
            write_func(value, i + 1, spack, fmtstring, raw_write, writer)
        end
    end
    
    local left = size - (size % count)
    for i=left, size - 1 do
        raw_write(writer, spack(singlefmt, value[i + 1]))
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
    
    if size >= count then
        for i=0, size - 1, count do
            read_func(value, i + 1, sunpack, fmtstring, raw_read, reader, packsize)
        end
    end
    
    local left = size - (size % count)
    for i=left, size - 1 do
        value[i] = sunpack(singlefmt, raw_read(reader, elemsize))
    end
    
    return value
end

function NumberList:encodemeta(encoder)
    encoder.writer:varint(self.sizebits)
    encoder.writer:varint(self.numbertag)
end

function optimal.internal_number_list(fmt, count, mapping, sizebits)
    if sizebits == nil then sizebits = 0 end

    local list = setmetatable({ }, NumberList)
    list.tag = tags.LIST
    list.numbertag = mapping.tag
    list.singlefmt = fmt
    list.sizebits  = sizebits
    
    local fstring = ""
    for i=1, count do
        fstring = fstring .. fmt
    end
    
    list.fmtstring = fstring
    list.elemsize  = string.packsize(fmt)
    list.count     = count
    
    local write_values = 
        "local function write_the_values(v, i, pack, fstr, rw, writer)\n" ..
        "    rw(writer, pack(fstr"
        
    for i=0, count - 1 do
        write_values = write_values .. ", v[i + " .. i .. "]"
    end 
    write_values = write_values .. "))\n\tend return write_the_values"
    list.write_func = load(write_values)()
    
    --Should be a way to do what I want in Lua...
    local read_values = "local function read_the_values(v, i, sup, fstr, rr, reader, ps) \n\t"
    for i=0, count - 1 do
        read_values = read_values .. " v[i + " .. i .. "]"
        if i ~= count - 1 then
            read_values = read_values .. ", \n\t"
        end
    end
    
    read_values = read_values .. " = sup(fstr, rr(reader, ps)) \nend \nreturn read_the_values"
    list.read_func = load(read_values)()
    
    return list    
end

local good_size = 100
local prim_to_list = 
{
    [primitive.uint8]   = optimal.internal_number_list("B",  good_size, primitive.uint8),
    [primitive.uint16]  = optimal.internal_number_list("I2", good_size, primitive.uint16),
    [primitive.uint32]  = optimal.internal_number_list("I4", good_size, primitive.uint32),
    [primitive.uint64]  = optimal.internal_number_list("I8", good_size, primitive.uint64),
    [primitive.int8]    = optimal.internal_number_list("b",  good_size, primitive.int8),
    [primitive.int16]   = optimal.internal_number_list("i2", good_size, primitive.int16),
    [primitive.int32]   = optimal.internal_number_list("i4", good_size, primitive.int32),
    [primitive.int64]   = optimal.internal_number_list("i8", good_size, primitive.int64),
    [primitive.float]   = optimal.internal_number_list("f",  good_size, primitive.float),
    [primitive.double]  = optimal.internal_number_list("d",  good_size, primitive.double),
}

prim_to_list[primitive.byte] = prim_to_list[primitive.uint8]

function optimal.number_list(number_mapping)
    return prim_to_list[number_mapping] or error("unrecognized number mapping " .. number_mapping)
end

return optimal