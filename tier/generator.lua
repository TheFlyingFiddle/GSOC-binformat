local meta   = require"tier.meta"
local custom = require"tier.custom"

local Generator = { } Generator.__index = Generator

function Generator:generate(type)
	local mapping = self.mappings[type] or self.generated[type]
	if mapping == nil then 
		local ref = custom.typeref()
		self.generated[type] = ref 
		
		local generator = self.generators[type.tag]
		if not generator then 
			error("no generator for type")	
		end
		
		mapping = generator(self, type)
		if ref.has_been_used then 
			ref:setref(mapping)		
		end
		
		self.generated[type] = mapping 								 					
	elseif meta.istyperef(mapping.meta) then 
		mapping.has_been_used = true
	end 
	return mapping	
end 

function Generator:register_mapping(mapping)
	self.mappings[mapping.meta] = mapping
end 

function Generator:register_generator(tag, generator)
	self.generators[tag] = generator
end

return function()
	local generator = setmetatable({}, Generator)
	generator.mappings   = { }
	generator.generated  = setmetatable({}, { __mode = "kv" })
	generator.generators = { }
	return generator
end 