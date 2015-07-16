local format = require"format"
local core   = require"tier.core"
local tags   = require"tier.tags"
local util   = require"tier.util"

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
    int.id      = pack(tags.SINT) .. pack(numbits)
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
    uint.id      = pack(tags.UINT) .. pack(numbits)
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
    decoder:setobject(value)
    
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
    decoder:setobject(value)

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
    decoder:setobject(value)

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
    decoder:setobject(value)
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
    decoder:setobject(value)
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
    local kind = readsize(decoder.reader, self.sizebits)
    return self.mappers[kind]:decode(decoder)
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
    local identity = self.handler:identify(value)
    local writer = encoder.writer
    local map = encoder:getobjectmap(self)
    local pos = map[identity]
    if pos == nil then 
        map[identity] = writer:getposition()
        writer:varint(0)
        self.mapper:encode(encoder, value)
    else 
        writer:varint(writer:getposition() - pos)
    end
end

function Object:decode(decoder)
    local reader = decoder.reader
    local pos = reader:getposition()
    local shift = reader:varint()
    local index = pos - shift
    local found, value = decoder:getobject(self, index)
    if not found then
        value = decoder:endobject(self, value, index, self.mapper:decode(decoder))
    end
    return value
end 

function Object:encodemeta(encoder)
    writemeta(encoder, self.mapper)
end

function custom.object(handler, mapper)
    assert(util.ismapping(mapper))
    
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
    self.mapping:encodemeta(encoder)
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
    transform.id      = mapping.id
    return transform
end


return custom