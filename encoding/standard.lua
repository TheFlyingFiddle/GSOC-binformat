local format    = require"format"
local tags      = require"encoding.tags"
local custom	= require"encoding.custom"
local primitive = require"encoding.primitive"
local util      = require"encoding.util"

local standard = { }

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

function TypeUnion:create(kind, value)
    return value;
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

function Optional:create(kind, ...)
   return ...
end

--Object handler
local LuaValueAsObject = { }
function LuaValueAsObject:identify(value)
    --This enables any lua type to be used as an object.
    return value; 
end

local EmbeddedHandler = { }
local newinstream  = format.inmemorystream
local newoutstream = format.outmemorystream

function EmbeddedHandler:getinstream(data)
    return newinstream(data)
end

function EmbeddedHandler:getoutstream()
    return newoutstream()
end

--Creators
local newlist = custom.list;
function standard.list(...)
    return newlist(TableAsList, ...)
end

local newarray = custom.array;
function standard.array(...)
    return newarray(TableAsList, ...)
end

local newset = custom.set
function standard.set(...)
    return newset(TableAsSet, ...)
end

local newmap = custom.map;
function standard.map(...)
    return newmap(TableAsMap, ...)
end

local newtuple = custom.tuple;
function standard.tuple(members)
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
function standard.union(kinds, bitsize)
    if bitsize == nil then bitsize = 0 end

    local handler = { }
    setmetatable(handler, TypeUnion)
    handler.kinds = kinds;
                       
                        
    local mappers = { }
    for i, v in ipairs(kinds) do
        assert(util.ismapping(v.mapping))
        table.insert(mappers, v.mapping)
    end
    
    return newunion(handler, mappers, bitsize) 
end

function standard.optional(mapper)
   return newunion(Optional, { primitive.null, mapper }, 0)   
end

local newobject = custom.object
function standard.object(mapper)
    return newobject(LuaValueAsObject, mapper)
end

local newsemantic = custom.semantic
function standard.semantic(id, mapper)
   return newsemantic(id, mapper)
end

local newembedded = custom.embedded
function standard.embedded(mapper)
    return newembedded(EmbeddedHandler, mapper)
end

local newtyperef = custom.typeref
standard.typeref = newtyperef;
function standard.selfref(func)
   local ref     = newtyperef()
   local mapping = func(ref)
   ref:setref(mapping)
   return mapping
end



--Generators-types and dynamics

--Generation of mappings.
local TypeRepoHandler = { }
function TypeRepoHandler:getmapping(tag)
    return self.generator:frommeta(tag)
end

standard.type = custom.type(TypeRepoHandler)


do
    local lua2tag = 
    {
        ["nil"]      = primitive.null,
        ["boolean"]  = primitive.boolean,
        ["number"]   = primitive.double,
        ["string"]   = primitive.string,
        ["function"] = nil,
        ["thread"]   = nil,
        ["userdata"] = nil,
    }
 
    function lua2tag:getmappingof(value)
        return self[type(value)] or error("no mapping for value of type " .. type(value))
    end
 
    standard.dynamic = custom.dynamic(lua2tag, standard.type)
    lua2tag["table"] = standard.object(standard.map(standard.dynamic, standard.dynamic)) 
end

do --Generator scoping block
    
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
    	return standard.embedded(generator:generate(node[1]))
    end
    
    local function genaligned(generator, node)
        local size
        if      node.tag == tags.ALIGN1  then size = 1
        elseif  node.tag == tags.ALIGN2 then size = 2
        elseif  node.tag == tags.ALIGN4 then size = 4
        elseif  node.tag == tags.ALIGN8 then size = 8
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
    
    local generators  = 
    {
        [tags.TUPLE]    = gentuple,
        [tags.UNION]    = genunion,
        [tags.LIST]     = genlist,
        [tags.SET]      = genset,
        [tags.MAP]      = genmap,
        [tags.ARRAY]    = genarray,
        [tags.OBJECT]   = genobject,
        [tags.SEMANTIC] = gensemantic,
        [tags.EMBEDDED] = genembedded,
        [tags.TYPEREF]  = gentyperef,
        
        [tags.ALIGN]  = genaligned,
        [tags.ALIGN1] = genaligned,
        [tags.ALIGN2] = genaligned,
        [tags.ALIGN4] = genaligned,
        [tags.ALIGN8] = genaligned
    }
    
    local generating = require"encoding.generating"
    standard.generator = generating.generator(generators, primitive)
    TypeRepoHandler.generator = standard.generator
    standard.generator.mappings[format.packvarint(tags.TYPE)]    = standard.type
    standard.generator.mappings[format.packvarint(tags.DYNAMIC)] = standard.dynamic
end

return standard