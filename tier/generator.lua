local meta   = require"tier.meta"
local custom = require"tier.custom"

local Generator = { } Generator.__index = Generator
function Generator:generate(type)
    assert(type)
	local id      = meta.getid(type)
	local mapping = self.mappings[id]
	if mapping == nil then 
		local ref = custom.typeref()
		self.mappings[id] = ref 
		
		local generator = self.generators[type.tag]
		if not generator then 
			error("no generator for type")	
		end
		
		mapping = generator(self, type)
		if ref.has_been_used then 
			ref:setref(mapping)		
		end
		
		self.mappings[id] = mapping 								 					
	elseif meta.istyperef(mapping.meta) then 
		mapping.has_been_used = true
	end 
	return mapping	
end 

function Generator:register_mapping(mapping)
	local id = meta.getid(mapping.meta)
	self.mappings[id] = mapping
end 

function Generator:register_generator(tag, generator)
	self.generators[tag] = generator
end

return function()
	local generator = setmetatable({}, Generator)
	generator.mappings   = { }
	generator.generators = { }
	return generator
end 