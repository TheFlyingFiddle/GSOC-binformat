local format = require"format"
local custom = require"encoding.custom"

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

local newobject = custom.object
local function createobject(mapper)
    return newobject(LuaValueAsObject, mapper)
end

local newsemantic = custom.semantic
local function createsemantic(id, mapper)
   return newsemantic(id, mapper)
end

local newembedded = custom.embedded
local function createembedded(mapper)
    return newembedded(EmbeddedHandler, mapper)
end

local newtyperef = custom.typeref
local function selfref(func)
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

return function(standard)
    assert(standard.generator, "Must have a generator!")
    TypeRepoHandler.generator = standard.generator
    
    local type = custom.type(TypeRepoHandler)
    standard.generator:idmapping(type)

    standard.type     = type
    standard.object   = createobject
	standard.semantic = createsemantic
	standard.embedded = createembedded
    
    --Should standard include typeref?
    standard.typeref  = newtyperef
	standard.selfref  = selfref
end