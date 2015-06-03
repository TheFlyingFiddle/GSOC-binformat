local tags      = require"encoding.tags"
local composed  = require"encoding.custom"
local format    = require"format"

local encoding = { } 
encoding.tags = tags

local Encoder = { }
Encoder.__index = Encoder;

--Encodes data using the specified mapping.
function Encoder:encode(mapping, data)
   self.writer:flushbits()
   if self.usemetadata then 
      self.writer:raw(mapping.tag)
   end
   
   mapping:encode(self, data)	
end

--Finishes any pending operations and closes 
--the encoder. After this operation the encoder can no longer be used.
function Encoder:close()
   self.writer:flush()
   self.objects = nil;
   self.writer  = nil;
   setmetatable(self, nil);
end


--Creates an encoder from an output stream.
--Defaults to output metadata.
function encoding.encoder(outStream, usemetadata)
   local encoder = { writer = format.writer(outStream) }
   setmetatable(encoder, Encoder)
   encoder.objects = { }
   
   if usemetadata == false then 
      encoder.usemetadata = false
   else 
      encoder.usemetadata = true;
   end
   
   return encoder
end

function encoding.encode(outStream, value, mapping, usemetadata)
   local encoder = encoding.encoder(outStream, usemetadata)
   encoder:encode(mapping, value)
   encoder:close()   
end

local Decoder = { }
Decoder.__index = Decoder;

--Closes the decoder.
--After this operation is performed the decoder can no longer be used.
function Decoder:close()
   self.objects = nil
   self.reader  = nil
   setmetatable(self, nil)
end

--Decodes using the specified mapping.
function Decoder:decode(mapping)
   self.reader:discardbits()   
   if self.usemetadata then 
      local meta_types = self.reader:raw(string.len(mapping.tag))
      assert(meta_types == mapping.tag)
   end 
   
   return mapping:decode(self)
end

--Creates a decoder
function encoding.decoder(inStream, usemetadata)
   local decoder = { reader = format.reader(inStream)}
   setmetatable(decoder, Decoder)
   decoder.objects = { }
   
   if usemetadata == false then 
      decoder.usemetadata = false
   else
      decoder.usemetadata = true
   end
   
   return decoder
end

--Convinience function for decoding a single value.
function encoding.decode(stream, mapping, usemetadata)
   local decoder = encoding.decoder(stream, usemetadata)
   local val     = decoder:decode(mapping)
   decoder:close()
   return val
end


local primitive = { }

--Most primitive have a one to one mapping to encoding functions 
--The method reduces some boilerplate.
--It creates a basic encode/decode object that simply forwards to
--the encoder/decoder.
local function createMapper(typeTag, func)
    local primitive = { tag = typeTag }
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

local tags = encoding.tags;

--Need to enforce alignment restrictions here
primitive.boolean  = createMapper(tags.BOOLEAN,   "bool")
primitive.byte     = createMapper(tags.BYTE,      "byte")
primitive.varint   = createMapper(tags.VARINT,    "varint")
primitive.varintzz = createMapper(tags.VARINTZZ,  "varintzz")
primitive.uint16   = createMapper(tags.UINT16,    "uint16")
primitive.uint32   = createMapper(tags.UINT32,    "uint32")
primitive.uint64   = createMapper(tags.UINT64,    "uint64")
primitive.int16    = createMapper(tags.SINT16,    "int16")
primitive.int32    = createMapper(tags.SINT32,    "int32")
primitive.int64    = createMapper(tags.SINT64,    "int64")
primitive.fpsingle = createMapper(tags.SINGLE,    "single")
primitive.fpdouble = createMapper(tags.DOUBLE,    "double")

--Not yet implemented primitive.fpquad = createMapper(QUAD, "writequad", "readquad");
primitive.stream   = createMapper(tags.STREAM, "stream")


--Void and null does not do anything so they do not have a one to one
--mapping thus we need to create the mapper manually. 
local Void = { tag = tags.VOID }
function Void:encode(encoder, value) end
function Void:decode(decoder) end
primitive.void = Void

local Null = { tag = tags.NULL }
function Null:encode(encoder, value) end
function Null:decode(decoder) end
primitive.null = Null

--CHAR should read as a 1 char string.
local Char = { tag = tags.CHAR }
function Char:encode(encoder, value)
    assert(string.len(value) == 1, "invalid character")
    encoder.writer:raw(value)
end
function Char:decode(decoder)
    return decoder.reader:raw(1)
end

primitive.char = Char

local WChar = { tag = tags.WCHAR }
function WChar:encode(encoder, value)
    assert(string.len(value) == 2, "invalid wide character")
    encoder.writer:raw(value)
end
function WChar:decode(decoder)
    return decoder.reader:raw(2)        
end

primitive.wchar = WChar

local String = { tag = tags.STRING }
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

primitive.string = String

--The wstring does not have a one-to-one mapping with an encoding/decoding function.
--Thus we need to create the mapper manually.
local WString = { tag = tags.WSTRING }
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
primitive.wstring = WString;


local Flag = { tag = tags.FLAG }
function Flag:encode(encoder, value)
    if value == 1 or value == true then
        encoder.writer:uint(1, 1)
    elseif value == 0 or value == false then
        encoder.writer:uint(1, 0)
    else
        error("Expected bool or number that is 0 or 1")
    end 
end

function Flag:decode(decoder)
    return decoder.reader:uint(1)
end
primitive.flag     = Flag

local Sign = { tag = tags.SIGN }
function Sign:encode(encoder, value)
    if value == 1 or value == true then
        encoder.writer:uint(1, 1)
    elseif value == -1 or value == false then
        encoder.writer:uint(1, 0)
    else
        error("Expected bool or number that is -1 or 1")
    end
end

function Sign:decode(decoder)
    local sign = decoder.reader:uint(1)
    if sign == 1 then
        return 1
    else
        return -1
    end
end
primitive.sign     = Sign

local function createBitInts(tag, name, count)
    for i=1, count do
        local name = name .. i
        if not primitive[name] then
            local mapping = {  }
            mapping.tag = tag .. string.pack("B", i)
            
            function mapping:encode(encoder, value)
                local writer = encoder.writer;
                writer[name](writer, i, value)
            end
            
            function mapping:decode(decoder)
                local reader = decoder.reader
                return reader[name](reader, i)            
            end
            
            primitive[name] = mapping
        end
    end
end

createBitInts(tags.UINT, "uint", 64)
createBitInts(tags.SINT, "int",  64)


local standard = { }

--List and Array handler
local TableAsList = { }
function TableAsList:getsize(value) return #value end
function TableAsList:getitem(value, index) return value[index] end
function TableAsList:create(size) return { } end
function TableAsList:setitem(value, index, item) value[index] = item end

local newlist = composed.list;
function standard.list(...)
    return newlist(TableAsList, ...)
end

local newarray = composed.array;
function standard.array(...)
    return newlist(TableAsList, ...)
end

--Set handler
local TableAsSet = { }
function TableAsSet:getsize(value)
    local counter = 0;
    for _ in pairs(value) do
        counter = counter + 1
    end
    return counter
end

function TableAsSet:getitem(value, i)
    local counter = 1;
    for k, v in pairs(value) do 
        if counter == i then
            return k, v;
        end
        counter = counter + 1;
    end
    return nil;
end

function TableAsSet:create(size)
    return { }
end

function TableAsSet:putitem(value, item)
    value[item] = true
end

local newset = composed.set
function standard.set(...)
    return newset(TableAsSet, ...)
end

--Map handler
local TableAsMap = { }
function TableAsMap:getsize(value) 
    local counter = 0;
    for _ in pairs(value) do
        counter = counter + 1
    end
    
    return counter
end

function TableAsMap:getitem(value, i)
    local counter = 1;
    for k, v in pairs(value) do 
        if counter == i then
            return k, v;
        end
        counter = counter + 1;
    end
    
    return nil;
end

function TableAsMap:create(size)
    return { }
end

function TableAsMap:putitem(value, key, item)    
    value[key] = item;
end

local newmap = composed.map;
function standard.map(...)
    return newmap(TableAsMap, ...)
end

--Tuple handler
local TableAsTuple = { }
TableAsTuple.__index = TableAsTuple
function TableAsTuple:getitem(value, index)
    local key = self.keys[index]
    return value[key];
end

function TableAsTuple:create()
    return { }
end

function TableAsTuple:setitem(value, index, item)
    local key = self.keys[index]
    value[key] = item;
end

local newtuple = composed.tuple;
function standard.tuple(members)
    local keys    = { }
    local mappers = { }

    for i=1, #members, 1 do
        local member = members[i];
        assert(member.mapping);
            
        mappers[i] = member.mapping;
        if member.key then
            keys[i] = member.key
        else
            keys[i] = i;
        end 
    end

    local handler = { }
    setmetatable(handler, TableAsTuple)
    handler.keys = keys;
    
    return newtuple(handler, table.unpack(mappers))             
end

--Union handler
local TypeUnion = { }
TypeUnion.__index = TypeUnion;
function TypeUnion:select(value)
    local typeof = type(value)
    local counter = 1
    for i ,v in ipairs(self.kinds) do
        if v.type == typeof then 
            return counter, v;
        end
        counter = counter + 1
    end 
        
    error(string.format("Cannot encode type: %s", typeof))
end

function TypeUnion:create(kind, value)
    return value;
end

local newunion = composed.union;
function standard.union(kinds)
    local handler = { }
    setmetatable(handler, TypeUnion)
    handler.kinds = kinds;
        
    local mappers = { }
    for i, v in ipairs(kinds) do
        table.insert(mappers, v.mapping)
    end
    
    return newunion(handler, table.unpack(mappers)) 
end

--Spacial case union nullable
local Nullable = { }
function Nullable:select(value)
   if value == nil then
      return 1, nil 
   else
      return 2, value
   end
end

function Nullable:create(kind, value)
   return value;
end

function standard.nullable(mapper)
   return newunion(Nullable, primitive.null, mapper)   
end

--Object handler
local LuaValueAsObject = { }
function LuaValueAsObject:identify(value)
    --This enables any lua type to be used as an object.
    return value; 
end

local newobject = composed.object
function standard.object(mapper)
    return newobject(LuaValueAsObject, mapper)
end

--[[Dynamic handler
local ErrorMapper = { }
ErrorMapper.__index = ErrorMapper
function ErrorMapper:encode(encoder, value)
    error("The dynamic mapper cannot encode values of type " .. self.typeof .. ".")
end

local function errormapper(typeof)
    local em = { }
    setmetatable(em, ErrorMapper)
    em.typeof = typeof
    return em
end

local DynamicHandler = { }
DynamicHandler.__index = DynamicHandler
function DynamicHandler:getvaluemapping(value)
	local typeof = type(value)
	return self.encodemapping[typeof];	
end

local tags = encoding.tags
function DynamicHandler:getmetamapping(typestring)
    return self.generator:frommeta(typestring)
end

local newdynamic = composed.dynamic
function standard.dynamic(generator)
    local handler = { }
    handler.generator = generator
     
    setmetatable(handler, DynamicHandler)
    local dynamic = newdynamic(handler)
    local DynEncode = { }
    DynEncode["nil"]  = primitive.null
    DynEncode.number  = primitive.fpdouble
    DynEncode.string  = primitive.stream
    DynEncode.boolean = primitive.boolean
    DynEncode.table   = standard.object(standard.map(dynamic, dynamic))
    DynEncode["function"] = errormapper("function")
    DynEncode.userdata    = errormapper("userdata")
    DynEncode.thread      = errormapper("thread")
        
    handler.encodemapping = DynEncode
    return dynamic
end	
--]]

encoding.primitive = primitive
encoding.standard  = standard

return encoding