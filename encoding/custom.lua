local format = require"format"
local core   = require"encoding.core"
local tags   = require"encoding.tags"

local pack = format.packvarint

local function writemeta(encoder, mapping) 
    local writer = encoder.writer
    if mapping.tag == tags.TYPEREF then    --Typerefs are special 
        assert(mapping.mapper ~= nil, "incomplete typeref")
        writemeta(encoder, mapping.mapper)
    elseif mapping.encodemeta == nil then  --Simple single or predefined byte mapping.
        assert(mapping.id ~= nil, "invalid mapping")
        writer:raw(mapping.id)
    else
        local index = encoder.types[mapping]
        if index == nil then -- Type is described for the first time
            writer:varint(mapping.tag)
            encoder.types[mapping]  = writer:getposition()
            mapping:encodemeta(encoder)
        else
            writer:varint(tags.TYPEREF)
            writer:varint(writer:getposition() - index)
        end
    end
end



local custom = { }

--Mapper for the ARRAY <T> tag.
local Array = { }
Array.__index = Array
function Array:encode(encoder, value)
    local size = self.size
    assert(self.handler:getsize(value) >= size, "array to small")
    for i=1, size do
        self.mapper:encode(encoder, self.handler:getitem(value, i))
    end
end

function Array:decode(decoder)
    local size = self.size;
    local value = self.handler:create();
    for i=1, size, 1 do
        local item = self.mapper:decode(decoder)
        self.handler:setitem(value, i, item)
    end
    return value
end

function Array:encodemeta(encoder)
    encoder.writer:varint(self.size)
    writemeta(encoder, self.mapper)
end

function custom.array(handler, mapper, size)
    local array = { }
    setmetatable(array, Array)
    array.tag     = tags.ARRAY 
    array.size    = size
    array.handler = handler
    array.mapper  = mapper
    return array    
end

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

--Mapper for the LIST <T> tag.
local List = {  }
List.__index = List;
function List:encode(encoder, value)
    local size = self.handler:getsize(value)
    writesize(encoder.writer, self.sizebits, size)
    
    for i=1,size, 1 do
        self.mapper:encode(encoder, self.handler:getitem(value, i)) 
    end 
end

function List:decode(decoder)
    local size   = readsize(decoder.reader, self.sizebits)
    local value  = self.handler:create(size)
        
    for i=1,size, 1 do
        local item = self.mapper:decode(decoder)
        self.handler:setitem(value, i, item)
    end
    return value;
end

function List:encodemeta(encoder)
    encoder.writer:varint(self.sizebits)
    writemeta(encoder, self.mapper)
end

function custom.list(handler, mapper, sizebits)
    if sizebits == nil then sizebits = 0 end

    local list = {  }
    setmetatable(list, List)
    list.tag        = tags.LIST
    list.sizebits   = sizebits
    list.handler    = handler
    list.mapper     = mapper
    return list;
end

--Mapper for the SET <T> tag.
local Set = {  }
Set.__index = Set;
function Set:encode(encoder, value)
    local size = self.handler:getsize(value)
    writesize(encoder.writer, self.sizebits, size)
    
    for i=1,size, 1 do
        self.mapper:encode(encoder, self.handler:getitem(value, i)) 
    end 
end

function Set:decode(decoder)
    local size  = readsize(decoder.reader, self.sizebits)
    local value  = self.handler:create(size)
    for i=1,size, 1 do
        local item = self.mapper:decode(decoder)
        self.handler:putitem(value, item)
    end
    return value
end

function Set:encodemeta(encoder)
    encoder.writer:varint(self.sizebits)
    writemeta(encoder, self.mapper)
end

function custom.set(handler, mapper, sizebits)
    if sizebits == nil then sizebits = 0 end
    local set = {  }
    setmetatable(set, Set)
    set.tag    = tags.SET
    set.handler = handler
    set.sizebits = sizebits
    set.mapper = mapper
    return set
end


--Mapper for the MAP <K> <V> tag.
local Map = { }
Map.__index = Map
function Map:encode(encoder, value)
    local size = self.handler:getsize(value)
    writesize(encoder.writer, self.sizebits, size)
    for i=1, size, 1 do
        local key, item = self.handler:getitem(value, i);
        self.keymapper:encode(encoder, key)
        self.itemmapper:encode(encoder, item);
    end
end

function Map:encodemeta(encoder)
    encoder.writer:varint(self.sizebits)
    writemeta(encoder, self.keymapper)
    writemeta(encoder, self.itemmapper)
end

function Map:decode(decoder)
    local size  = readsize(decoder.reader, self.sizebits)
    local value = self.handler:create(size)
    for i=1, size, 1 do
        local key  = self.keymapper:decode(decoder)
        local item = self.itemmapper:decode(decoder)
        
        self.handler:putitem(value, key, item)
    end 
    
    return value;
end

function custom.map(handler, keymapper, itemmapper, sizebits)
    if sizebits == nil then sizebits = 0 end
    
    local map = { }
    setmetatable(map, Map)
    map.tag   = tags.MAP
    map.handler    = handler
    map.keymapper  = keymapper
    map.itemmapper = itemmapper
    map.sizebits = sizebits
    return map;
end

--Mapper for the TUPLE N <T1> <T2> ... <TN> tag.
local Tuple = { }
Tuple.__index = Tuple
function Tuple:encode(encoder, value)
    for i=1, #self.mappers, 1 do
        local mapper = self.mappers[i]
        local item   = self.handler:getitem(value, i)
        mapper:encode(encoder, item)
    end
end

function Tuple:decode(decoder)
    local value = self.handler:create();
    for i=1, #self.mappers, 1 do
        local mapper = self.mappers[i] 
        local item   = mapper:decode(decoder)
        self.handler:setitem(value, i, item)
    end
    return value;   
end

function Tuple:encodemeta(encoder)
    local len = #self.mappers
    encoder.writer:varint(len)
    for i=1, len do
        writemeta(encoder, self.mappers[i])
    end
end

function custom.tuple(handler, mappers)
    local tuple = { }
    setmetatable(tuple, Tuple)
    tuple.mappers = mappers
    tuple.handler = handler
    tuple.tag     = tags.TUPLE
    
    return tuple;
end


--Mapper for the UNION N <T1> <T2> ... <TN>
local Union = { }
Union.__index = Union
function Union:encode(encoder, value)
    local kind, encodable = self.handler:select(value)
    local mapper = self.mappers[kind]
    writesize(encoder.writer, self.sizebits, kind)
    mapper:encode(encoder, value)    
end

function Union:decode(decoder)
    local kind    = readsize(decoder.reader, self.sizebits)
    local mapper  = self.mappers[kind]
    return self.handler:create(kind, mapper:decode(decoder))
end

function Union:encodemeta(encoder)
    encoder.writer:varint(self.sizebits)
    local len = #self.mappers
    encoder.writer:varint(len)
    for i=1, len do
        writemeta(encoder, self.mappers[i])
    end
end

function custom.union(handler, mappers, sizebits)
    if sizebits == nil then sizebits = 0 end
    
    
    local union = { }
    setmetatable(union, Union)
    union.tag      = tags.UNION
    union.handler  = handler
    union.mappers  = mappers
    union.sizebits = sizebits
    
    return union
end

--Mapper for the SEMANTING "ID" <T> tag
local Semantic = { }
Semantic.__index = Semantic
function Semantic:encode(encoder, value)
    self.mapper:encode(encoder, value)
end

function Semantic:decode(decoder)
    return self.mapper:decode(decoder)
end

function Semantic:encodemeta(encoder)
    encoder.writer:stream(self.identifier)
    writemeta(encoder, self.mapper)
end

function custom.semantic(id, mapper)
    local semantic = { }
    setmetatable(semantic, Semantic)
    semantic.tag    = tags.SEMANTIC
    semantic.identifier = id
    semantic.mapper = mapper
    return semantic
end

local Object = { }
Object.__index = Object;
function Object:encode(encoder, value)
    local ident = self.handler:identify(value)
    local index = 0
    for i, v in ipairs(encoder.objects) do
        if ident == v then
            index = i
        end
    end   
    
    if index == 0 then 
        index = #encoder.objects;
        encoder.writer:varint(index)
        table.insert(encoder.objects, ident)
        self.mapper:encode(encoder, value)
    else 
        encoder.writer:varint(index - 1)
    end
end

local function fixcyclicrefs(obj, tmp, ref)
    local t = type(obj)
    if t == "table" then
        for k, v in pairs(obj) do
            if k == tmp and v == tmp then
                obj[ref] = ref
            elseif k == tmp then 
                obj[ref] = v
            elseif v == tmp then
                obj[k] = ref     
            end
            
            fixcyclicrefs(k, tmp, ref)
            fixcyclicrefs(v, tmp, ref)        
        end
    end
end

function Object:decode(decoder)
    local index = decoder.reader:varint();
    index = index + 1;
    if index > #decoder.objects then 
        local tmpObj = { }
        table.insert(decoder.objects, tmpObj)
        local obj = self.mapper:decode(decoder)
        fixcyclicrefs(obj, tmpObj, obj) --Can be very slow (on a large graph)
        decoder.objects[index] = obj
        return obj
    else
        return decoder.objects[index]
    end
end 

function Object:encodemeta(encoder)
    writemeta(encoder, self.mapper)
end

function custom.object(handler, mapper)
    local object = { }
    setmetatable(object, Object)
    object.mapper  = mapper
    object.handler = handler
    object.tag = tags.OBJECT
    return object    
end

local Align = { }
Align.__index = Align

function Align:encode(encoder, value)
    encoder.writer:align(self.alignof)
    self.mapper:encode(encoder, value)
end

function Align:decode(decoder)
    decoder.reader:align(self.alignof)
    return self.mapper:decode(decoder)
end

function Align:encodemeta(encoder)
    if self.tag == tags.ALIGN then
        encoder.writer:varint(self.alignof)
    end
    
    writemeta(encoder, self.mapper)    
end

function custom.align(size, mapping)
    local aligner = setmetatable({}, Align)
    aligner.alignof = size
    aligner.mapper = mapping
    
    if size == 1 then
        aligner.tag = tags.ALIGN8    
    elseif size == 2 then
        aligner.tag = tags.ALIGN16
    elseif size == 4 then 
        aligner.tag = tags.ALIGN32
    elseif size == 8 then
        aligner.tag = tags.ALIGN64
    else
        aligner.tag  = tags.ALIGN
    end
    
    return aligner                
end

--Will fix this. It's not hard. 
local Embedded = { }
Embedded.__index = Embedded;
function Embedded:encode(encoder, value)
    local outstream = self.handler:getoutstream()
    local enco = core.encoder(outstream, false)
    self.mapper:encode(enco, value)
    enco:close()
    
    local data    = outstream:getdata()
    print(data)
    encoder.writer:stream(data)
    outstream:close()
end

function Embedded:decode(decoder) 
    local data      = decoder.reader:stream() 
    local instream  = self.handler:getinstream(data)
    local deco      = core.decoder(instream, false)
    local value     = self.mapper:decode(deco) 
        
    deco:close()
    instream:close()
    return value
end

function Embedded:encodemeta(encoder) 
    writemeta(encoder, self.mapper)
end 

function custom.embedded(handler, mapper, dontgenerateid) 
    local embedded = setmetatable({}, Embedded)
    embedded.handler    = handler
    embedded.mapper     = mapper
    embedded.tag        = tags.EMBEDDED
    
    return embedded
end



local Typeref = { }
Typeref.__index = Typeref
function Typeref:encode(encoder, value)
    self.mapper:encode(encoder, value)
end

function Typeref:decode(decoder)
    return self.mapper:decode(decoder)
end

function Typeref:setref(mapper)
    assert(self.mapper == nil, "canot reseed a typeref")
    self.mapper = mapper
end

function custom.typeref()
    local typeref = { }
    setmetatable(typeref, Typeref);
    typeref.tag = tags.TYPEREF
    return typeref;
end

local Type = { }
Type.__index = Type
function Type:encode(encoder, value) --Value would be a tag here.
    encoder.writer:raw(core.getid(value))
end
 
function Type:decode(decoder)
    local tag     = decoder.reader:varint()
    local id      
    if tag == tags.ARRAY or
       tag == tags.LIST  or
       tag == tags.SET   or
       tag == tags.MAP   or
       tag == tags.UNION or
       tag == tags.TUPLE or
       tag == tags.ALIGN or 
       tag == tags.ALIGN8 or
       tag == tags.ALIGN16 or
       tag == tags.ALIGN32 or
       tag == tags.ALIGN64 or
       tag == tags.OBJECT or
       tag == tags.EMBEDDED or
       tag == tags.SEMANTIC then
        local size = decoder.reader:varint()
        id = pack(tag) .. decoder.reader:raw(size)                                   
     elseif tag == tags.UINT or tag == tags.SINT then
        local size = decoder.reader:varint()
        id = pack(tag) .. pack(size)  
     else
        id = pack(tag)
     end
     
    local mapping = self.handler:getmapping(id)
    return mapping     
end

function custom.type(handler)
    local typ       = setmetatable({ }, Type)
    typ.tag         = tags.TYPE
    typ.id          = pack(typ.tag)
    typ.handler     = handler
    return typ               
end

local Dynamic = { }
Dynamic.__index = Dynamic

function Dynamic:encode(encoder, value)
	local mapping   = self.handler:getmappingof(value)
	self.mapper:encode(encoder, mapping)
    mapping:encode(encoder, value)
end

function Dynamic:decode(decoder)
	local mapping  = self.mapper:decode(decoder)
    return mapping:decode(decoder)
end

function custom.dynamic(handler, type_mapping)
    assert(type_mapping.tag == tags.TYPE)

    local dynamic = { }
    setmetatable(dynamic, Dynamic)
    dynamic.handler     = handler
    dynamic.mapper      = type_mapping
    dynamic.tag         = tags.DYNAMIC
    dynamic.id          = pack(tags.DYNAMIC)
    
    return dynamic
end

return custom