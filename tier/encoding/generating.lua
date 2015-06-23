local format    = require"format"
local tags		= require"encoding.tags"
local parser	= require"encoding.parser"

local generating = { }

local Generator = { }
Generator.__index = Generator

function Generator:generate(node) --rep is the entire type.
	local id      = string.sub(self.rep, node.sindex, node.eindex)
	local mapping = self.mappings[id] or self.tempmappings[node.sindex]
	if not mapping then
		local gen	= self.generators[node.tag]
		mapping 	= gen(self, node)
		self.tempmappings[node.sindex] = mapping
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
		print("Fixing type ref")
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

function generating.generator(tags, generators, mappings)
	local gen = { }
	setmetatable(gen, Generator)
	gen.generators = { }
	gen.mappings   = { }
	
	for _, v in pairs(mappings) do
		gen.mappings[v.id] = v
	end
	
	for i=1, #tags do
		gen.generators[tags[i]] = generators[i]
	end
	return gen
end


return generating