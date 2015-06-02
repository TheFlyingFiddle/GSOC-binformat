local encoding  = require"encoding"
local composed  = require"encoding.composed"
local primitive = require"encoding.primitive" 

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
   if value then 
      return 2, value;
   else
      return 1, nil;
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

--Dynamic handler
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


return standard