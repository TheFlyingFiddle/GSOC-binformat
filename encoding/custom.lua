local format = require"format"
local core   = require"encoding.core"
local tags   = require"encoding.tags"
local util   = require"encoding.util"

local pack      = format.packvarint
local writemeta = core.writemeta

local custom = { }

local Int = { } 
Int.__index = Int
function Int:encode(encoder, value)
    encoder.writer:int(self.bits, value)
end

function Int:decode(decoder)
    return encoder.reader:int(self.bits)
end

function custom.int(numbits)
    local int = setmetatable({ bits = numbits}, Int)
    int.tag     = tags.SINT
    int.id      = format.packvarint(tags.SINT) .. format.packvarint(numbits)
    return int
end

local Uint = { } 
Uint.__index = Uint
function Int:encode(encoder, value)
    encoder.writer:uint(self.bits, value)
end

function Int:decode(decoder)
    return encoder.reader:uint(self.bits)
end

function custom.uint(numbits)
    local uint   = setmetatable({ bits = numbits}, Int)
    uint.tag     = tags.UINT
    uint.id      = format.packvarint(tags.UINT) .. format.packvarint(numbits)
    return uint
end

--Mapper for the ARRAY <T> tag.
local Array = { }
Array.__index = Array
function Array:encode(encoder, value)
    local size = self.size
    assert(self.handler:getsize(value) >= size, "array to small")
    
    local mapping = self.mapper
    local encode  = mapping.encode
    local handler = self.handler
    local getitem = handler.getitem
        
    for i=1, size do
        encode(mapping, encoder, getitem(handler, value, i))
    end
end

function Array:decode(decoder)
    local size = self.size
    local value = self.handler:create()
    
    local mapping = self.mapper
    local decode  = mapping.decode
    local handler = self.handler
    local setitem = handler.setitem
    
    for i=1, size, 1 do
        setitem(handler, value, i, decode(mapping, decoder))
    end
    return value
end

function Array:encodemeta(encoder)
    encoder.writer:varint(self.size)
    writemeta(encoder, self.mapper)
end

function custom.array(handler, mapper, size)
    assert(util.ismapping(mapper))
    assert(handler.getsize, "Array handler missing function getsize")
    assert(handler.create,  "Array handler missing function create")
    assert(handler.setitem, "Array handler missing function setitem")
    assert(handler.getitem, "Array handler missing function getitem")

    local array = { }
    setmetatable(array, Array)
    array.tag     = tags.ARRAY --pri
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
    
    local mapping = self.mapper
    local encode  = mapping.encode
    local handler = self.handler
    local getitem = handler.getitem
    
    for i=1, size do
        encode(mapping, encoder, getitem(handler, value, i))
    end 
end

function List:decode(decoder)
    local size   = readsize(decoder.reader, self.sizebits)
    local value  = self.handler:create(size)

    local mapping = self.mapper
    local decode  = mapping.decode
    local handler = self.handler
    local setitem = handler.setitem
        
    for i=1,size, 1 do
        setitem(handler, value, i, decode(mapping, decoder))
    end
    return value;
end

function List:encodemeta(encoder)
    encoder.writer:varint(self.sizebits)
    writemeta(encoder, self.mapper)
end

function custom.list(handler, mapper, sizebits)
    assert(util.ismapping(mapper))
    assert(handler.getsize, "List handler missing function getsize")
    assert(handler.create,  "List handler missing function create")
    assert(handler.setitem, "List handler missing function setitem")
    assert(handler.getitem, "List handler missing function getitem")
    
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
    
    local mapping = self.mapper 
    local encode  = mapping.encode
    local handler = self.handler
    local getitem = handler.getitem
    
    for i=1,size, 1 do
        encode(mapping, encoder, getitem(handler, value, i))
    end 
end

function Set:decode(decoder)
    local size  = readsize(decoder.reader, self.sizebits)
    local value  = self.handler:create(size)

    local mapping = self.mapper
    local decode  = mapping.decode
    local handler = self.handler
    local putitem = handler.putitem

    for i=1,size, 1 do
        putitem(handler, value, decode(mapping, decoder))
    end
        
    return value
end

function Set:encodemeta(encoder)
    encoder.writer:varint(self.sizebits)
    writemeta(encoder, self.mapper)
end

function custom.set(handler, mapper, sizebits)
    assert(util.ismapping(mapper))
    assert(handler.getsize, "Set handler missing function getsize")
    assert(handler.create,  "Set handler missing function create")
    assert(handler.putitem, "Set handler missing function setitem")
    assert(handler.getitem, "Set handler missing function getitem")

    
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
    for k, v in self.handler:getitems(value) do
        self.keymapper:encode(encoder, k)
        self.itemmapper:encode(encoder, v);
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
    assert(util.ismapping(keymapper))
    assert(util.ismapping(itemmapper))
    
    assert(handler.getsize,  "Map handler missing function getsize")
    assert(handler.create,   "Map handler missing function create")
    assert(handler.putitem,  "Map handler missing function putitem")
    assert(handler.getitems, "Map handler missing function getitems")
    
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
    for i=1, #mappers do
        assert(util.ismapping(mappers[i]))
    end
    
    assert(handler.create,  "Tuple handler missing function create")
    assert(handler.getitem, "Tuple handler missing function getitem")
    assert(handler.setitem, "Tuple handler missing function setitem")

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
    
    for i=1, #mappers do
        assert(util.ismapping(mappers[i]))
    end

    assert(handler.create,  "Union handler missing function create")
    assert(handler.select, "Union handler missing function select")
    
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
    assert(util.ismapping(mapper))

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
        if self.hastyperef then
            local tmpObj = { } --Cycles in all honor but we mostly dont need em
            table.insert(decoder.objects, tmpObj)
            local obj = self.mapper:decode(decoder)
            fixcyclicrefs(obj, tmpObj, obj)
            decoder.objects[index] = obj
            return obj
        else
            local obj = self.mapper:decode(decoder)
            decoder.objects[index] = obj
            return obj
        end
    else
        return decoder.objects[index]
    end
end 

function Object:encodemeta(encoder)
    writemeta(encoder, self.mapper)
end

local function hastyperef(mapping)
    if util.ismapping(mapping) and 
       (mapping.tag == tags.TYPEREF or mapping.tag == tags.DYNAMIC) then
        --Dynamic tags can contain implicit typerefs.
        return true
    end
   
    for k, v in pairs(mapping) do
        if type(v) == "table" then
            if hastyperef(v) then
                return true
            end
        end
    end
    return false
end

function custom.object(handler, mapper)
    assert(util.ismapping(mapper))
    
    local object = { }
    setmetatable(object, Object)
    object.mapper  = mapper
    object.handler = handler
    object.tag = tags.OBJECT
    object.hastyperef = hastyperef(mapper)
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
    util.ismapping(mapping)
    
    local aligner = setmetatable({}, Align)
    aligner.alignof = size
    aligner.mapper = mapping
    
    if size == 1 then
        aligner.tag = tags.ALIGN1    
    elseif size == 2 then
        aligner.tag = tags.ALIGN2
    elseif size == 4 then 
        aligner.tag = tags.ALIGN4
    elseif size == 8 then
        aligner.tag = tags.ALIGN8
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
    local enco = core.encoder(format.writer(outstream), false)
    self.mapper:encode(enco, value)
    enco:close()
    
    local data    = outstream:getdata()
    encoder.writer:stream(data)
    outstream:close()
end

function Embedded:decode(decoder) 
    local data      = decoder.reader:stream() 
    local instream  = self.handler:getinstream(data)
    local deco      = core.decoder(format.reader(instream), false)
    local value     = self.mapper:decode(deco) 
        
    deco:close()
    instream:close()
    return value
end

function Embedded:encodemeta(encoder) 
    writemeta(encoder, self.mapper)
end 

function custom.embedded(handler, mapper, dontgenerateid) 
    assert(util.ismapping(mapper))
    
    local embedded = setmetatable({}, Embedded)
    embedded.handler    = handler
    embedded.mapper     = mapper
    embedded.tag        = tags.EMBEDDED
    
    return embedded
end

local Typeref = { }
Typeref.__index = Typeref
function Typeref:encode(encoder, value)
    error("typeref not yet initialized")
end

function Typeref:decode(decoder)
    error("typeref not yet initialized")
end

function Typeref:setref(mapper)
    assert(self.mapper == nil, "canot reseed a typeref")
    self.mapper = mapper
    
    local mencode = mapper.encode
    function encode(tr, encoder, value)
        mencode(mapper, encoder, value)
    end
    
    local mdecode = mapper.decode
    function decode(tr, decoder)
       return mdecode(mapper, decoder)
    end
    
    self.encode = encode
    self.decode = decode    
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
 
local typeWithSizeLookup =
{
    [tags.ARRAY] = true,
    [tags.LIST]  = true,
    [tags.SET]   = true,
    [tags.MAP]   = true,
    [tags.UNION] = true,
    [tags.TUPLE] = true,
    [tags.ALIGN] = true,
    [tags.ALIGN1] = true,
    [tags.ALIGN2] = true,
    [tags.ALIGN4] = true,
    [tags.ALIGN8] = true,
    [tags.OBJECT] = true,
    [tags.EMBEDDED] = true,
    [tags.SEMANTIC] = true,
    [tags.UINT]     = true,
    [tags.SINT]      = true
 }
 
function Type:decode(decoder)
    local tag     = decoder.reader:varint()
    local id      
    if not typeWithSizeLookup[tag] then
        id = pack(tag)
    elseif tag == tags.UINT or tag == tags.SINT then
        local size = decoder.reader:varint()
        id = pack(tag) .. pack(size)  
    else
        local size = decoder.reader:varint()
        id = pack(tag) .. decoder.reader:raw(size)     
    end
    
    local mapping = self.handler:getmapping(id)
    return mapping     
end

function custom.type(handler)
    assert(handler, "expected a type handler")
    assert(handler.getmapping, "Type handler missing function getmapping")

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
    assert(handler.getmappingof, "Dynamic handler missing function getmappingof")

    local dynamic = { }
    setmetatable(dynamic, Dynamic)
    dynamic.handler     = handler
    dynamic.mapper      = type_mapping
    dynamic.tag         = tags.DYNAMIC
    dynamic.id          = pack(tags.DYNAMIC)
    return dynamic
end

--Should this be here?
local Transform = { }
Transform.__index = Transform
function Transform:encode(encoder, value)
    local val = self.handler:to(value)
    self.mapping:encode(encoder, val)
end

function Transform:decode(decoder)
    local val = self.mapping:decode(decoder)
    return self.handler:from(val)
end

function Transform:encodemeta(encoder)
    writemeta(encoder, self.mapping)
end

function custom.transform(handler, mapping)
    assert(handler, "expected transform handler")
    assert(util.ismapping(mapping))
    
    assert(handler.to, "Transform handler missing function to")
    assert(handler.from, "Transform handler missing function from")
    
    local transform = { }
    setmetatable(transform, Transform)
    transform.handler = handler
    transform.mapping = mapping
    transform.tag     = mapping.tag
    return transform
end


return custom