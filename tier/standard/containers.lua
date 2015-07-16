local custom 	= require"tier.custom"
local primitive = require"tier.primitive"
local util      = require"tier.util"

--List and Array handler
local TableAsList = { }
function TableAsList:getsize(value) return #value end
function TableAsList:getitem(value, index) return value[index] end
function TableAsList:create(size) return { } end
function TableAsList:setitem(value, index, item) value[index] = item end

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

function TableAsMap:getitems(value)
    return pairs(value)
end

function TableAsMap:create(size)
    return { }
end

function TableAsMap:putitem(value, key, item)    
    value[key] = item;
end

--Tuple handler
local TableAsTuple = { }
TableAsTuple.__index = TableAsTuple
function TableAsTuple:getitem(value, index)
    local key = self.keys[index]
    return value[key]
end

function TableAsTuple:create()
    return { }
end

function TableAsTuple:setitem(value, index, item)
    local key = self.keys[index]
    value[key] = item;
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

--Spacial case union nullable
local Optional = { }
function Optional:select(value)
   if value == nil then
      return 1, nil 
   else
      return 2, value
   end
end

local newlist = custom.list
local function createlist(...)
    return newlist(TableAsList, ...)
end

local newarray = custom.array
local function createarray(...)
    return newarray(TableAsList, ... )
end

local newset = custom.set
local function createset(...)
    return newset(TableAsSet, ...)
end

local newmap = custom.map
local function createmap(...)
    return newmap(TableAsMap, ...)
end

local newtuple = custom.tuple;
local function createtuple(members)
    local keys    = { }
    local mappers = { }

    for i=1, #members, 1 do
        local member = members[i];
        assert(util.ismapping(member.mapping))
        
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

local newunion = custom.union;
local function createunion(kinds, bitsize)
    if bitsize == nil then bitsize = 0 end

    local handler = { }
    setmetatable(handler, TypeUnion)
    handler.kinds = kinds;
                       
                        
    local mappers = { }
    for i, v in ipairs(kinds) do
        assert(util.ismapping(v.mapping))
        mappers[i] = v.mapping
    end
    
    return newunion(handler, mappers, bitsize) 
end	

local function optional(mapper)
	return newunion(Optional, { primitive.null, mapper }, 0)   
end

return function (standard)
    standard.list     = createlist
    standard.array    = createarray
    standard.set      = createset
    standard.map      = createmap
    standard.tuple    = createtuple
    standard.union    = createunion
    standard.optional = optional
end