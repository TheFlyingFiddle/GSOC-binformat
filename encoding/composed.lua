local encoding = require"encoding"

local composed = { }

--Mapper for the ARRAY <T> tag.
local Array = { }
Array.__index = Array
function Array:encode(encoder, value)
    encoder:writevarint(self.size)
    for i=1,size,1 do
        encoder:encode(self.mapper, self.handler:getitem(value, i))
    end
end

function Array:decode(decoder)
    local size = self.size;
    local value = self.handler:create();
    for i=1, size, 1 do
        local item = decoder:decode(self.mapper)
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
        encoder:encode(self.mapper, self.handler:getitem(value, i)) 
    end 
end

function List:decode(decoder)
    local size = decoder:readvarint()
    local value  = self.handler:create(size)
    for i=1,size, 1 do
        local item = decoder:decode(self.mapper)
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
        encoder:encode(self.mapper, self.handler:getitem(value, i)) 
    end 
end

function Set:decode(decoder)
    local size = decoder:readvarint()
    local value  = self.handler:create(size)
    for i=1,size, 1 do
        local item = decoder:decode(self.mapper)
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
        encoder:encode(self.keymapper, key)
        encoder:encode(self.itemmapper, item);
    end
end

function Map:decode(decoder)
    local size  = decoder:readvarint();
    local value = self.handler:create(size)
    for i=1, size, 1 do
        local key  = decoder:decode(self.keymapper)
        local item = decoder:decode(self.itemmapper)
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
        encoder:encode(mapper, item);
    end
end

function Tuple:decode(decoder)
    local value = self.handler:create();
    for i=1, #self.mappers, 1 do
        local mapper = self.mappers[i] 
        local item   = decoder:decode(mapper)
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
    encoder:writevarint(kind)
    encoder:encode(self.mappers[kind], value)
end

function Union:decode(decoder)
    local kind    = decoder:readvarint();
    local decoded = decoder:decode(self.mappers[kind])
    return self.handler:create(kind, encoded)
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
    encoder:encode(self.mapper, value)
end

function Semantic:decode(decoder)
    return decoder:decode(self.mapper)
end

function composed.semantic(id, mapper)
    local semantic = { }
    setmetatable(semantic, Semantic)
    
    semantic.tag    = encoding.tags.SEMANTIC .. id .. mapper.tag
    semantic.mapper = mapper
    return semantic
end

--Left to implement is
-- object, embedded
-- and typeref 

return composed