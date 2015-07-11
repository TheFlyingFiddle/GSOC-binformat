local generating = require"encoding.generating"
local primitive  = require"encoding.primitive"
local util       = require"encoding.util"
local tags       = require"encoding.tags"

return function(standard)
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
    
    local semantic_generators = { }
    
    local function gensemantic(generator, node)
        if semantic_generators[node.identifier] then
            return semantic_generators[node.identifier](generator, node[1])
        else 
            error("Cannot create a mapping for unrecognized semantic type " .. node.identifier)
        end
    end
    
    local function genembedded(generator, node)
    	return standard.embedded(generator:generate(node[1]))
    end
    
    local function genaligned(generator, node)
        local size
        if      node.tag == tags.ALIGN1 then size = 1
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
    
    local g = generating.generator()
    g:taggenerator(tags.TUPLE,      gentuple)
    g:taggenerator(tags.UNION,      genunion)
    g:taggenerator(tags.LIST,       genlist)
    g:taggenerator(tags.SET,        genset)
    g:taggenerator(tags.MAP,        genmap)
    g:taggenerator(tags.ARRAY,      genarray)
    g:taggenerator(tags.OBJECT,     genobject)
    g:taggenerator(tags.EMBEDDED,   genembedded)
    g:taggenerator(tags.TYPEREF,    gentyperef)
    g:taggenerator(tags.ALIGN,      genaligned)
    g:taggenerator(tags.ALIGN1,     genaligned)
    g:taggenerator(tags.ALIGN2,     genaligned)
    g:taggenerator(tags.ALIGN4,     genaligned)
    g:taggenerator(tags.ALIGN8,     genaligned)
    
    --We add all the mappings in the 
    --primitive module to the generator
    for k, v in pairs(primitive) do
        if util.ismapping(v) then 
            g:idmapping(v) 
        end
    end
      
    standard.generator = g
end