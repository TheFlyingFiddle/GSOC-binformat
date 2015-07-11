local format    = require"format"
local tags		= require"tier.tags"
local parser	= require"tier.parser"
local core		= require"tier.core"

local generating = { }

local Generator = { }
Generator.__index = Generator

function Generator:generate(node) --rep is the entire type.
	local id      = string.sub(self.rep, node.sindex, node.eindex)
	local mapping = self.mappings[id] or self.tempmappings[node.sindex]
	if not mapping then
		local gen	= self.generators[node.tag]
		if gen then 
			mapping 	= gen(self, node)
			self.tempmappings[node.sindex] = mapping
		elseif node.tag == tags.SEMANTIC then 
			gen = self.semantic_generators[node.identifier]
			if gen then 
				mapping = gen(self, node[1])
				self.tempmappings[node.sindex] = mapping
			else
				error("No semantic generator for identifier " .. node.identifier )
			end
		else 
			error("No generator for tag " .. tags[node.tag] .. "(" .. node.tag .. ")")
		end
	end					
	return mapping
end

function Generator:fromtype(parsetree)
	if self.mappings[parsetree.rep] then
		return self.mappings[parsetree.rep]
	end

	--Setup variables for mapping generation.
	self.rep  = parsetree.rep
	self.root = parsetree.root
	self.typerefs 	  = { }
	self.tempmappings = { }
	
	local mapping = self:generate(parsetree.root)
	self.mappings[self.rep] = mapping

	--Fix typerefs	
	local len = #self.typerefs
	for node, ref in pairs(self.typerefs) do
		ref:setref(self.tempmappings[node.sindex])
	end

	self.rep  = nil
	self.root = nil
	self.typerefs = nil
	self.tempmappings = nil
	return mapping	
end

function Generator:frommeta(metastring)
	local mapping = self.mappings[metastring]
	if not mapping then
		local parsetree = parser.parsemetatype(metastring)
		return self:fromtype(parsetree)
	else
		return mapping
	end
end

function Generator:fromstring(str)
	local parsetree = parser.parsestring(str)
	return self:fromtype(parsetree)
end

function Generator:idmapping(mapping)
	local id = mapping.id 
	if not id then
		local eid = core.getid(mapping)
		id = string.sub(eid, 1, 1) .. string.sub(eid, 3)
	end
	self.mappings[id] = mapping
end

function Generator:taggenerator(tag, generator)
	self.generators[tag] = generator
end

function Generator:semanticgenerator(id, generator)
	self.semantic_generators[id] = generator
end

function generating.generator(generators, mappings)
	local gen = { }
	setmetatable(gen, Generator)
	gen.generators			= { }
	gen.semantic_generators = { }
	gen.mappings			= { }
	return gen
end

return generating