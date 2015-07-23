local format = require"format"
local custom = require"tier.custom"

--Object handler
local NIL = {}
local LuaValueAsObject = { }
function LuaValueAsObject:identify(value)
    --This enables any lua type to be used as an object.
    if value == nil then return NIL end
    return value
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
function TypeRepoHandler:getmapping(metatype)
    return self.generator:generate(metatype)
end

return function(standard)
    assert(standard.generator, "Must have a generator!")
    TypeRepoHandler.generator = standard.generator
    
    local type = custom.type(TypeRepoHandler)
    standard.generator:register_mapping(type)

    standard.type     = type
    standard.object   = createobject
	standard.semantic = createsemantic
	standard.embedded = createembedded
    standard.opaque   = custom.opaque
    
    --Should standard include typeref?
    standard.typeref  = newtyperef
	standard.selfref  = selfref
end