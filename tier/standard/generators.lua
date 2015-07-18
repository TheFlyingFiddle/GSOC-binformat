local generator  = require"tier.generator"
local primitive  = require"tier.primitive"
local util       = require"tier.util"
local tags       = require"tier.tags"
local custom     = require"tier.custom"

local tagToLua = {
    [tags.UINT]     = "number",
    [tags.UINT8]    = "number",
    [tags.UINT16]   = "number",
    [tags.UINT32]   = "number",
    [tags.UINT64]   = "number",
    [tags.SINT]     = "number",
    [tags.SINT8]    = "number",
    [tags.SINT16]   = "number",
    [tags.SINT32]   = "number",
    [tags.SINT64]   = "number",
    [tags.HALF]     = "number",
    [tags.FLOAT]    = "number",
    [tags.DOUBLE]   = "number",
    [tags.QUAD]     = "number",
    [tags.SIGN]     = "number",
    [tags.VARINT]   = "number",
    [tags.VARINTZZ] = "number",
    
    [tags.CHAR]    = "string",
    [tags.WCHAR]   = "string",
    [tags.STREAM]  = "string",
    [tags.STRING]  = "string",
    [tags.WSTRING] = "string",
        
    [tags.FLAG]    = "boolean",
    [tags.BOOLEAN] = "boolean",
    
    [tags.VOID] = "nil",
    [tags.NULL] = "nil",

    [tags.LIST]  = "table",
    [tags.SET]   = "table",
    [tags.ARRAY] = "table",
    [tags.TUPLE] = "table",
    [tags.MAP]   = "table"
}

--Standard generator functions
local function metatypetoluatype(g, metatype)
	local lua_type = tagToLua[metatype.tag] or "unknown"
	if lua_type == "unkown" then
        return metatypetoluatype(generator, metatype[1])
	end
	return lua_type
end
   
return function(standard)

    --Generator functions
    local function gentuple(g, metatype)
        local tuple = { }
    	for i=1, #metatype do
    		tuple[i] = { mapping = g:generate(metatype[i]) }
    	end
    	return standard.tuple(tuple)
    end
    
    local function genunion(g, metatype)
    	local union = { }
    	for i=1, #metatype do
    		local sub = metatype[i]        
            local ltype = metatypetoluatype(g, sub)
    		union[i] = { type = ltype, mapping = g:generate(sub) }	
    	end
    		
    	return standard.union(union, metatype.sizebits)
    end
    
    local function genlist(g, metatype)
    	return standard.list(g:generate(metatype[1]), metatype.sizebits)
    end
    
    local function genset(g, metatype)
    	return standard.set(g:generate(metatype[1]),  metatype.sizebits)
    end
    
    local function genarray(g, metatype)
    	return standard.array(g:generate(metatype[1]), metatype.size)
    end
    
    local function genmap(g, metatype)
    	return standard.map(g:generate(metatype[1]),
                            g:generate(metatype[2]), metatype.sizebits)
    end
    
    local function genobject(g, metatype)
    	return standard.object(g:generate(metatype[1]))
    end
    
    local function genint(g, metatype)
        return custom.int(metatype.bits)
    end 
    
    local function genuint(g, metatype)
        return custom.uint(metatype.bits)
    end 
    
    local semantic_generators = { }
    local function gensemantic(g, metatype)
        if semantic_generators[metatype.identifier] then
            return semantic_generators[metatype.identifier](generator, metatype[1])
        else 
            error("Cannot create a mapping for unrecognized semantic type " .. metatype.identifier)
        end
    end
    
    local function genembedded(generator, metatype)
    	return standard.embedded(generator:generate(metatype[1]))
    end
    
    local function genaligned(generator, metatype)
        return custom.align(metatype.alignof, generator:generate(metatype[1]))
    end
        

    local g = generator()
    g:register_generator(tags.TUPLE,      gentuple)
    g:register_generator(tags.UNION,      genunion)
    g:register_generator(tags.LIST,       genlist)
    g:register_generator(tags.SET,        genset)
    g:register_generator(tags.MAP,        genmap)
    g:register_generator(tags.ARRAY,      genarray)
    g:register_generator(tags.OBJECT,     genobject)
    g:register_generator(tags.EMBEDDED,   genembedded)
    g:register_generator(tags.ALIGN,      genaligned)
    g:register_generator(tags.ALIGN1,     genaligned)
    g:register_generator(tags.ALIGN2,     genaligned)
    g:register_generator(tags.ALIGN4,     genaligned)
    g:register_generator(tags.ALIGN8,     genaligned)
    g:register_generator(tags.UINT,       genuint)
    g:register_generator(tags.SINT,        genint)
    
    --We add all the mappings in the 
    --primitive module to the generator
    for k, v in pairs(primitive) do
        if util.ismapping(v) then 
            g:register_mapping(v) 
        end
    end    
      
    standard.generator = g
end