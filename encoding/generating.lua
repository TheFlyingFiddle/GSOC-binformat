local encoding  = require"encoding"
local format    = require"format"

local primitive = require"encoding.primitive"
local composed  = require"encoding.composed"
local standard  = require"encoding.standard"
local parser	= require"encoding.parser"
local tags = encoding.tags;

local generating = { }

local Generator = { }
Generator.__index = Generator


local function gentuple(generator, node)
	local tuple = { }
	for i=1, node.size do
		tuple[i] = { mapping = generator:generate(node[i]) }
	end
	return standard.tuple(tuple)
end

local function nodetoluatype(node)
	local type = encoding.tagtoluatype(node.tag)
	if type == "unkown" then
		if node.tag == tags.UNION then
			return "unkown"
		else
			return nodetoluatype(node[1])
		end
	end
	
	return type
end

local function genunion(generator, node)
	local union = { }
	for i=1, node.size do
		local sub = node[i]
		local ltype = nodetoluatype(sub)
		union[i] = { type = ltype, mapping = generator:generate(sub) }	
	end
		
	return standard.union(union)
end

local function genlist(generator, node)
	return standard.list(generator:generate(node[1]))
end

local function genset(generator, node)
	return standard.set(generator:generate(node[1]))
end

local function genarray(generator, node)
	return standard.array(generator:generate(node[1]), node.size)
end

local function genmap(generator, node)
	return standard.map(generator:generate(node[1]),
					    generator:generate(node[2]))
end


local function findnode(node, sindex)
	if node.sindex == sindex then return node end
	local index = 1
	while true do
		local snode = node[index]
		if snode then
			local correctNode = findnode(snode)
			if correctnode then
				return correctnode
			end	
		else
			break
		end
		index = index + 1
	end
	return nil
end

local function gentyperef(generator, node)
	local sindex 	= node.sindex - node.offset
	local refnode   = findnode(generator.root, sindex)
	assert(refnode, "Typeref failed")
	
	local ref = composed.typeref()
	table.insert(generator.typerefs, ref)
	table.insert(generator.typerefnodes, refnode)
	return ref
end

local function genobject(generator, node)
	return standard.object(generator:generate(node[1]))
end

local function gensemantic(generator, node)
	return composed.semantic(node.id, generator:generate(node[1]))
end

local function genembedded(generator, node)
	return composed.embedded(generator:generate(node[1]))
end

function Generator:generate(node) --rep is the entire type.
	local id      = string.sub(self.rep, node.sindex, node.eindex)
	local mapping = self.mappings[id]
	if not mapping then
		mapping 	= self.generators[node.tag](self, node)
		self.mappings[id] = mapping
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
	self.typerefnodes = { }
	
	local mapping = self:generate(parsetree.root)

	--Fix typerefs	
	local len = #self.typerefs
	for i=1, len do
		local ref  = self.typerefs[i]
		local node = self.typerefnodes[i]
		local id   = string.sub(self.rep, node.sindex, node.eindex)
		ref:setref(self.mappings[id])
	end

	self.ref  = nil
	self.root = nil
	self.typerefs = nil
	self.typerefnodex = nil
		
	mapping.tag = parsetree.rep
	return mapping	
end

function Generator:frommeta(metastring)
	local mapping = self.mappings[metastring]
	if not mapping then
		local pt = parser.parsemetatype(metastring)
		return self:fromtype(parsetree)
	else
		return mapping
	end
end

function Generator:fromstring(str)
	local parsetree = parser.parsestring(str)
	return self:fromtype(parsetree)
end

function Generator:setgenerator(tag, generator)
	self.generators[tag] = generator
end

function generating.generator()
	local gen = { }
	setmetatable(gen, Generator)
	gen.mappings 	= { }
	for _, v in pairs(primitive) do
		gen.mappings[v.tag] = v		
	end
		
	--NEED to fix dynamic tag for this aswell. 
	--gen.mappings[tags.DYNAMIC] = standard.dynamic(gen)
	
	local generators = { }
	generators[tags.TUPLE]  	= gentuple
	generators[tags.UNION]  	= genunion
	generators[tags.SET]    	= genset
	generators[tags.ARRAY]  	= genarray
	generators[tags.MAP]   		= genmap
	generators[tags.OBJECT] 	= genobject
	generators[tags.SEMANTIC]	= gensemantic
	generators[tags.EMBEDDED]   = genembedded
	generators[tags.TYPEREF]    = gentyperef
	gen.generators = generators
	
	return gen
end

function generating.fromstring(str)
	local typetree   = parser.parsestring(str)
	local generator = generating.generator()
	return generator:fromtype(typetree)	
end

return generating