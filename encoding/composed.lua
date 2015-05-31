local encoding = require"encoding"

local composed = { }

--Mapper for the ARRAY <T> tag.
local Array = { }
Array.__index = Array
function Array:encode(encoder, value)
    encoder:writevarint(self.size)
    for i=1,size,1 do
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
end

function composed.array(handler, mapper, size)
    local array = { }
    setmetatable(array, Array)
    array.tag     = encoding.tags.ARRAY .. mapper.tag
    array.size    = size
    array.handler = handler
    array.mapper  = mapper
    return array    
end

--Mapper for the LIST <T> tag.
local List = {  }
List.__index = List;
function List:encode(encoder, value)
    local size = self.handler:getsize(value)
    encoder:writevarint(size)
    for i=1,size, 1 do
        self.mapper:encode(encoder, self.handler:getitem(value, i)) 
    end 
end

function List:decode(decoder)
    local size = decoder:readvarint()
    local value  = self.handler:create(size)
    for i=1,size, 1 do
        local item = self.mapper:decode(decoder)
        self.handler:setitem(value, i, item)
    end
    return value;
end

function composed.list(handler, mapper)
    local list = {  }
    setmetatable(list, List)
    list.tag    = encoding.tags.LIST .. mapper.tag;
    list.handler = handler;
    list.mapper  = mapper;
    return list;
end

--Mapper for the SET <T> tag.
local Set = {  }
Set.__index = Set;
function Set:encode(encoder, value)
    local size = self.handler:getsize(value)
    encoder:writevarint(size)
    for i=1,size, 1 do
        self.mapper:encode(encoder, self.handler:getitem(value, i)) 
    end 
end

function Set:decode(decoder)
    local size = decoder:readvarint()
    local value  = self.handler:create(size)
    for i=1,size, 1 do
        local item = self.mapper:decode(decoder)
        self.handler:putitem(value, item)
    end
    return value;
end

function composed.set(handler, mapper)
    local list = {  }
    setmetatable(list, Set)
    list.tag    = encoding.tags.SET .. mapper.tag;
    list.handler = handler;
    list.mapper  = mapper;
    return list;
end


--Mapper for the MAP <K> <V> tag.
local Map = { }
Map.__index = Map
function Map:encode(encoder, value)
    local size = self.handler:getsize(value)
    encoder:writevarint(size)
    for i=1, size, 1 do
        local key, item = self.handler:getitem(value, i);
        self.keymapper:encode(encoder, key)
        self.itemmapper:encode(encoder, item);
    end
end

function Map:decode(decoder)
    local size  = decoder:readvarint();
    
    local value = self.handler:create(size)
    for i=1, size, 1 do
        local key  = self.keymapper:decode(decoder)
        local item = self.itemmapper:decode(decoder)
        
        self.handler:putitem(value, key, item)
    end 
    
    return value;
end

function composed.map(handler, keymapper, itemmapper)
    local map = { }
    setmetatable(map, Map)
    map.tag   = encoding.tags.MAP .. keymapper.tag .. itemmapper.tag    
    map.handler    = handler
    map.keymapper  = keymapper
    map.itemmapper = itemmapper
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

function composed.tuple(handler, ...)
    local tuple = { }
    setmetatable(tuple, Tuple)
    tuple.mappers = { ... }
    tuple.handler = handler
    
    local tag = encoding.tags.TUPLE .. string.pack("B", #tuple.mappers)
    for i=1, #tuple.mappers, 1 do
        tag = tag .. tuple.mappers[i].tag
    end
    tuple.tag = tag
    
    return tuple;
end

--Mapper for the UNION N <T1> <T2> ... <TN>
local Union = { }
Union.__index = Union
function Union:encode(encoder, value)
    local kind, encodable = self.handler:select(value)
    local mapper = self.mappers[kind]
    encoder:writevarint(kind)
    mapper:encode(encoder, value)    
end

function Union:decode(decoder)
    local kind    = decoder:readvarint();
    local mapper  = self.mappers[kind]
    
    local decoded = mapper:decode(decoder)
    return self.handler:create(kind, decoded)
end

function composed.union(handler, ...)
    local union = { }
    setmetatable(union, Union)
    union.handler = handler
    union.mappers = { ... }
    
    local tag = encoding.tags.UNION .. string.pack("B", #union.mappers)
    for i=1, #union.mappers, 1 do
        tag = tag .. union.mappers[i].tag
    end
    union.tag = tag
    
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

function composed.semantic(id, mapper)
    local semantic = { }
    setmetatable(semantic, Semantic)
    
    semantic.tag    = encoding.tags.SEMANTIC .. id .. mapper.tag
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
        encoder:writevarint(index)
        table.insert(encoder.objects, ident)
        self.mapper:encode(encoder, value)
    else 
        encoder:writevarint(index - 1)
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
    local index = decoder:readvarint();
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

function composed.object(handler, mapper)
    local object = { }
    setmetatable(object, Object)
    object.mapper  = mapper
    object.handler = handler
    object.tag = encoding.tags.OBJECT .. mapper.tag; 
    return object    
end



local Dynamic = { }
Dynamic.__index = Dynamic

function Dynamic:encode(encoder, value)
	local mapper   = self.handler:getvaluemapping(value)
	local metatype = mapper.tag
	encoder:writeraw(metatype)
	mapper:encode(encoder, value)
end

function Dynamic:decode(decoder)
	local metatype = decoder:readtype()
	local mapping  = self.handler:getmetamapping(metatype)
	return mapping:decode(decoder)	
end

function composed.dynamic(handler)
    local dynamic = { }
    setmetatable(dynamic, Dynamic)
    dynamic.handler     = handler
    dynamic.tag         = encoding.tags.DYNAMIC
    
    return dynamic
end


--Need to create a memory buffer before we write it to
--the stream. 
local Embedded = { }
Embedded.__index = Embedded;

function Embedded:encode(encoder, value)
end

function Embedded:decode(encoder, value)
end

function composed.embeded(mapper)
end

local Typeref = { }
Typeref.__index = Typeref
function Typeref:encode(encoder, value)
    self.mapper:encode(encoder, value)
end

function Typeref:decode(decoder)
    local val = self.mapper:decode(decoder)
    return val
    
end

function Typeref:setref(mapper)
    if self.mapper then
        error("This type reference already refers to a complete type")
    end
    
    --We need to figure out the index we should refer back to.
    self.mapper = mapper
    local tmptag = self.tag
    local index  = 1
    while true do
        local i = string.find(mapper.tag, tmptag, index)
        if not i then return end
        index = i + 1
                                                                
        local offset = i - 1
        local reftag = encoding.tags.TYPEREF .. string.pack("B", offset)
        mapper.tag = string.gsub(mapper.tag, tmptag, reftag, 1)                
    end
end

--Used to identify the mapper.
local typrefCounter = 0;
function composed.typeref()
    local typeref = { }
    setmetatable(typeref, Typeref);
    typeref.tag = "incomplete_typeref" .. typrefCounter; --Sort of A hack I guess...
    typrefCounter = typrefCounter + 1;
    
    return typeref;
end

return composed