local tags      = require"encoding.tags"
local custom    = require"encoding.custom"
local format    = require"format"

local encoding = { } 
encoding.tags = tags

local Encoder = { }
Encoder.__index = Encoder;

function encoding.getid(mapping)
    local id = mapping.id
    if id == nil then
        local buffer  = format.memorystream()
        local encoder = encoding.encoder(buffer)
        encoder.types = { }
        encoder.types[mapping] = encoder.writer:getposition()
        mapping:encodemeta(encoder)
        encoder:close()
        local body = buffer:getdata()
        id = format.packvarint(mapping.tag) .. format.packvarint(#body) .. body
    end
    return id
end

function Encoder:getid(mapping)
    return encoding.getid(mapping)
end

--Encodes data using the specified mapping.
function Encoder:encode(mapping, data)
   self.writer:flushbits()
   if self.usemetadata then
      self.writer:raw(encoding.getid(mapping))
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
      local id = encoding.getid(mapping)
      local meta_types = self.reader:raw(#id)
      assert(meta_types == id)
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
    local primitive = { tag = typeTag, id = format.packvarint(typeTag) }
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
local Void = { tag = tags.VOID, id = format.packvarint(tags.VOID) }
function Void:encode(encoder, value) end
function Void:decode(decoder) end
primitive.void = Void

local Null = { tag = tags.NULL, id = format.packvarint(tags.NULL) }
function Null:encode(encoder, value) assert(value == nil, "nil expected") end
function Null:decode(decoder) return nil end
primitive.null = Null

--CHAR should read as a 1 char string.
local Char = { tag = tags.CHAR, id = format.packvarint(tags.CHAR)}
function Char:encode(encoder, value)
    assert(string.len(value) == 1, "invalid character")
    encoder.writer:raw(value)
end
function Char:decode(decoder)
    return decoder.reader:raw(1)
end

primitive.char = Char

local WChar = { tag = tags.WCHAR , id = format.packvarint(tags.WCHAR)}
function WChar:encode(encoder, value)
    assert(string.len(value) == 2, "invalid wide character")
    encoder.writer:raw(value)
end
function WChar:decode(decoder)
    return decoder.reader:raw(2)        
end

primitive.wchar = WChar

local String = { tag = tags.STRING, id = format.packvarint(tags.STRING)}
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
local WString = { tag = tags.WSTRING , id = format.packvarint(tags.WSTRING)}
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

local Flag = { tag = tags.FLAG, id = format.packvarint(tags.FLAG)}
function Flag:encode(encoder, value)
    encoder.writer:uint(1, value and 1 or 0)
end

function Flag:decode(decoder)
    return decoder.reader:uint(1) ~= 0
end
primitive.flag     = Flag

local Sign = { tag = tags.SIGN, id = format.packvarint(tags.SIGN)}
function Sign:encode(encoder, value)
    encoder.writer:uint(1, value < 0 and 1 or 0)
end

function Sign:decode(decoder)
    return decoder.reader:uint(1) ~= 0 and -1 or 1
end
primitive.sign     = Sign

local function createBitInts(tag, name, count)
    for i=1, count do
        if not primitive[name .. i] then
            local mapping = {  }
            mapping.tag = tag 
            mapping.bitsize = i
            mapping.id  = format.packvarint(tag) .. format.packvarint(i)
            
            function mapping:encode(encoder, value)
                local writer = encoder.writer;
                writer[name](writer, i, value)
            end
            
            function mapping:decode(decoder)
                local reader = decoder.reader
                return reader[name](reader, i)            
            end
            
            primitive[name .. i] = mapping
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

local newlist = custom.list;
function standard.list(...)
    return newlist(TableAsList, ...)
end

local newarray = custom.array;
function standard.array(...)
    return newarray(TableAsList, ...)
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

local newset = custom.set
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

local newmap = custom.map;
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

local newtuple = custom.tuple;
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
    
    return newtuple(handler, mappers)             
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

local newunion = custom.union;
function standard.union(kinds, bitsize)
    if bitsize == nil then bitsize = 0 end

    local handler = { }
    setmetatable(handler, TypeUnion)
    handler.kinds = kinds;
        
    local mappers = { }
    for i, v in ipairs(kinds) do
        table.insert(mappers, v.mapping)
    end
    
    return newunion(handler, mappers, bitsize) 
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

function Nullable:create(kind, ...)
   return ...
end

function standard.nullable(mapper)
   return newunion(Nullable, { primitive.null, mapper }, 0)   
end

--Object handler
local LuaValueAsObject = { }
function LuaValueAsObject:identify(value)
    --This enables any lua type to be used as an object.
    return value; 
end

local newobject = custom.object
function standard.object(mapper)
    return newobject(LuaValueAsObject, mapper)
end

--Generation of mappings.
local TypeRepoHandler = { }
function TypeRepoHandler:getmapping(tag)
    return self.generator:frommeta(tag)
end

standard.type = custom.type(TypeRepoHandler)


local lua2tag = 
{
    ["nil"]      = primitive.null,
    ["boolean"]  = primitive.boolean,
    ["number"]   = primitive.fpdouble,
    ["string"]   = primitive.string,
    ["function"] = nil,
    ["thread"]   = nil,
    ["userdata"] = nil,
 }
 
 function lua2tag:getmappingof(value)
    return self[type(value)] or error("no mapping for value " .. type(value))
 end
 
 standard.dynamic = custom.dynamic(lua2tag, standard.type)
 lua2tag["table"] = standard.object(standard.map(standard.dynamic, standard.dynamic))

--Basic generator functions that are needed for standard.type and by extension standard.dynamic.
--Generator helping functions
local function findnode(node, sindex)
	if node.sindex == sindex then 
        return node 
    end
    
	local index = 1
	while true do
		local snode = node[index]
		if snode then
			local correct_node = findnode(snode, sindex)
			if correct_node then
				return correct_node
			end	
		else
			break
		end
		index = index + 1
	end
	return nil
end

local function nodetoluatype(generator, node)
	local type = tags.tagtoluatype(node.tag)
	if type == "unkown" then
		if node.tag == tags.UNION then
			return "unkown"
		else        
            if node.tag == tags.TYPEREF then
            	local sindex 	= node.sindex - node.offset
	            local refnode   = findnode(generator.root, sindex)
                return nodetoluatype(generator, refnode) 
            else       
            	return nodetoluatype(generator, node[1])
            end
		end
	end
	
	return type
end

--Generator functions
local function gentuple(generator, node)
    local tuple = { }
	for i=1, node.size do
		tuple[i] = { mapping = generator:generate(node[i]) }
	end
	return standard.tuple(tuple)
end

local function genunion(generator, node)
	local union = { }
	for i=1, node.size do
		local sub = node[i]        
        
        local ltype = nodetoluatype(generator, sub)
		union[i] = { type = ltype, mapping = generator:generate(sub) }	
	end
		
	return standard.union(union, node.bitsize)
end

local function genlist(generator, node)
	return standard.list(generator:generate(node[1]), node.bitsize)
end

local function genset(generator, node)
	return standard.set(generator:generate(node[1]),  node.bitsize)
end

local function genarray(generator, node)
	return standard.array(generator:generate(node[1]), node.size)
end

local function genmap(generator, node)
	return standard.map(generator:generate(node[1]),
                        generator:generate(node[2]), node.bitsize)
end

local function genobject(generator, node)
	return standard.object(generator:generate(node[1]))
end

local function gensemantic(generator, node)
	return custom.semantic(node.identifier, generator:generate(node[1]))
end

local function genembedded(generator, node)
	return custom.embedded(generator:generate(node[1]))
end

local function genaligned(generator, node)
    local size
    if      node.tag == tags.ALIGN8  then size = 1
    elseif  node.tag == tags.ALIGN16 then size = 2
    elseif  node.tag == tags.ALIGN32 then size = 4
    elseif  node.tag == tags.ALIGN64 then size = 8
    else    size = node.size end
    
    return custom.align(size, generator:generate(node[1]))
end

local function gentyperef(generator, node)
	local sindex 	= node.sindex - node.offset
	local refnode   = findnode(generator.root, sindex)
	assert(refnode, "Typeref failed")
	    
    local ref = generator.typerefs[refnode]
    if not ref then
        ref = custom.typeref()
        generator.typerefs[refnode] = ref
    end
	return ref
end

local standardTags  = 
{
    tags.TUPLE,
    tags.UNION,
    tags.LIST,
    tags.SET,
    tags.MAP,
    tags.ARRAY,
    tags.OBJECT,
    tags.SEMANTIC,
    tags.EMBEDDED,
    tags.TYPEREF,
    
    tags.ALIGN,
    tags.ALIGN8,
    tags.ALIGN16,
    tags.ALIGN32,
    tags.ALIGN64
}

local standardGenerators = 
{
    gentuple,
    genunion,
    genlist,
    genset,
    genmap,
    genarray,
    genobject,
    gensemantic,
    genembedded,
    gentyperef,
    genaligned,
    genaligned,
    genaligned,
    genaligned,
    genaligned
}

local generating = require"encoding.generating"
standard.generator = generating.generator(standardTags, standardGenerators, primitive)
TypeRepoHandler.generator = standard.generator
standard.generator.mappings[format.packvarint(tags.TYPE)]    = standard.type
standard.generator.mappings[format.packvarint(tags.DYNAMIC)] = standard.dynamic

encoding.primitive = primitive
encoding.standard  = standard
return encoding