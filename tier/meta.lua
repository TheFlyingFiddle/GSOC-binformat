local tags   = require"tier.tags"
local core   = require"tier.core"
local format = require"format"

local pack 	 = format.packvarint
local unpack = format.unpackvarint

local meta = { }
local meta_types = { }

local function newmetatype(tag)
	assert(tag)
	local mt = {} mt.__index = mt
	mt.tag = tag
	meta_types[tag] = mt
	
	return mt
end 

local simple_metatypes = 
{
	[tags.VOID] 	= true,
	[tags.NULL] 	= true,
	[tags.VARINT] 	= true,
	[tags.VARINTZZ] = true,
	[tags.CHAR]		= true,
	[tags.WCHAR]	= true,
	[tags.TYPE]		= true,
	[tags.DYNAMIC]	= true,
	[tags.FLAG]		= true,
	[tags.SIGN]		= true,
	[tags.BOOLEAN]	= true,
	[tags.UINT8]	= true,
	[tags.UINT16]	= true,
	[tags.UINT32]	= true,
	[tags.UINT64]	= true,
	[tags.SINT8]	= true,
	[tags.SINT16]	= true,
	[tags.SINT32]	= true,
	[tags.SINT64]	= true,
	[tags.HALF]		= true,
	[tags.FLOAT]	= true,
	[tags.DOUBLE]	= true,
	[tags.QUAD]		= true,
	[tags.STREAM]	= true,
	[tags.STRING]	= true,
	[tags.WSTRING]	= true
}

for entry, _ in pairs(simple_metatypes) do 
	meta[tags[entry]:lower()] = { tag = entry, id = pack(entry) }
end

local function metafromtag(tag)
	return meta[tags[tag]:lower()]
end 

local memoized_types = setmetatable({}, { __mode = "v"})
local function canmemoize(type)
	if type.recursive_protection then return true end 

	local isok = true
	if type.tag == tags.TYPEREF then 
		isok   = false		
	else
		type.recursive_protection = true
		for i=1, #type do 
			if not canmemoize(type[i]) then 
				isok = false
				break; 
			end 	
		end 
		type.recursive_protection = nil
	end 
	return isok
end 


local function memoize_type(type)
	if canmemoize(type) then 
		local id = meta.getid(type)
		if memoized_types[id] then 
			return memoized_types[id]
		else 
			memoized_types[id] = type
		end 
	end 
	return type
end

local function encodeid(encoder, type)
	local writer = encoder.writer
	if simple_metatypes[type.tag] then
		writer:writef("V", type.tag)
	elseif type.tag == tags.TYPEREF then
		assert(type[1] ~= nil, "incomplete typeref") 
		encodeid(encoder, type[1])
	else 
		local index = encoder.types[type]
		if index == nil then 
			encoder.types[type] = writer:getposition()
			writer:writef("V", type.tag)
		 	type:encode(encoder)			
		else
			local offset = writer:getposition() - index
			writer:writef("V", tags.TYPEREF)
			writer:writef("V", offset)
		end 
	end 
end

local outstream  = format.outmemorystream
local newwriter  = format.writer 
local newencoder = core.encoder 

function meta.getid(type)
	if not type.id then
		local buffer  = outstream()
		encoder       = newencoder(newwriter(buffer))
		encoder.types = { }
		encodeid(encoder, type)
		encoder:close()		
		type.id    = buffer:getdata()
	end 
	return type.id 
end 

function meta.encodetype(encoder, type)
	meta.getid(type)
	local id 
	--This is the encoded version of an id. 	
	if #type.id > 1 then 
		local head = string.sub(type.id, 1,  1)  
		local body = string.sub(type.id, 2, -1)	
		id 	= head .. pack(#body) .. body
	else
		id = type.id 
	end 

	encoder:writef("r", id)	
end 

local function decodeid(decoder)
	local reader = decoder.reader
	local pos  = reader:getposition()

	local tag  = reader:readf("V")
	if simple_metatypes[tag] then
		return metafromtag(tag)
	elseif tag == tags.TYPEREF then 
		local typeref = pos - reader:readf("V")
		return decoder.types[typeref]
	else 
		local type = setmetatable({}, meta_types[tag])
		decoder.types[pos] = type
		type:decode(decoder)
		
		local endpos 	= reader:getposition()
		local id        = string.sub(decoder.idbuffer, pos + 1, endpos + 1)
		if memoized_types[id] then 
			type = memoized_types[id]
		else
			memoized_types[id] = type
			type.id 		   = id
		end 
		return type
	end	
end 


local instream  = format.inmemorystream
local newreader  = format.reader
local newdecoder = core.decoder
function meta.decodetype(decoder)
	local tag = decoder:readf("V")
	if simple_metatypes[tag] then 
		return metafromtag(tag)
	else 
		local data    	 = pack(tag) .. decoder:readf("s")
		if memoized_types[data] then 
			return memoized_types[data]
		end 
				
		local decoder 	   = newdecoder(newreader(instream(data)))
		decoder.types 	   = { }
		decoder.idbuffer   = data
		return decodeid(decoder)			
	end  
end

do 
	local Array = newmetatype(tags.ARRAY)
	function Array:encode(encoder)
		encoder:writef("V", self.size)
		encodeid(encoder, self[1])
	end
	
	function Array:decode(decoder)
		self.size = decoder:readf("V")
		self[1]	  = decodeid(decoder)
	end
	
	function meta.array(element_type, size)
		local array = setmetatable({ }, Array)
		array[1]  = element_type
		array.size = size 
		return memoize_type(array)
	end
end 

do 
	local List = newmetatype(tags.LIST) 
	function List:encode(encoder)
		encoder:writef("V", self.sizebits)
		encodeid(encoder, self[1])
	end
	
	function List:decode(decoder)
		self.sizebits	  = decoder:readf("V")
		self[1]			  = decodeid(decoder)
	end

	function meta.list(element_type, sizebits)
		if sizebits == nil then sizebits = 0 end
		local list 	  = setmetatable({ }, List)
		list[1] 	  = element_type
		list.sizebits 	  = sizebits
		return memoize_type(list)
	end
end 

do 
	local Set = newmetatype(tags.SET) 
	function Set:encode(encoder)
		encoder:writef("V", self.sizebits)
		encodeid(encoder, self[1])
	end
	
	function Set:decode(decoder)
		self.sizebits 	= decoder:readf("V")
		self[1]			= decodeid(decoder)
	end
	
	function meta.set(element_type, sizebits)
		if sizebits == nil then sizebits = 0 end
		local set = setmetatable({}, Set)
		set[1]	  = element_type
		set.sizebits  = sizebits 
		set.tag   = tags.SET
		return memoize_type(set)
	end
end 

do
	local Map 	= newmetatype(tags.MAP)
	function Map:encode(encoder)
		encoder:writef("V", self.sizebits)
		encodeid(encoder, self[1])
		encodeid(encoder, self[2])
	end
	
	function Map:decode(decoder)
		self.sizebits = decoder:readf("V")
		self[1]		  = decodeid(decoder)
		self[2]		  = decodeid(decoder)
	end
	
	function meta.map(key_type, value_type, sizebits)
		if sizebits == nil then sizebits = 0 end
		
		local map = setmetatable({ }, Map)
		map[1]    = key_type
		map[2]	  = value_type
		map.sizebits  = sizebits
		return memoize_type(map)
	end
end 

do
	local Tuple = newmetatype(tags.TUPLE)
	function Tuple:encode(encoder)
		encoder:writef("V", #self)
		for i=1, #self do 
			encodeid(encoder, self[i])	
		end
	end
	
	function Tuple:decode(decoder)
		local size  = decoder:readf("V")
		for i=1, size do 
			self[i] = decodeid(decoder)
		end 
	end
	
	function meta.tuple(types)
		local tuple = setmetatable({}, Tuple)
		for i=1, #types do 
			tuple[i] = types[i]
		end 
		
		return memoize_type(tuple)
	end
end 

do 
	local Union = newmetatype(tags.UNION)
	function Union:encode(encoder)
		encoder:writef("V", self.sizebits)
		encoder:writef("V", #self)
		
		for i=1, #self do 
			encodeid(encoder, self[i])
		end 
	end
	
	function Union:decode(decoder)
		self.sizebits = decoder:readf("V")
		local size    = decoder:readf("V")

		for i=1, size do 
			self[i] = decodeid(decoder)
		end 
	end 
	 
	function meta.union(types, sizebits)
		if sizebits == nil then sizebits = 0 end		 
		local union = setmetatable({}, Union)
		for i=1, #types do 
			union[i] = types[i]
		end 
		
		union.sizebits = sizebits 
		return memoize_type(union)
	end
end 

do
	local Object = newmetatype(tags.OBJECT)
	function Object:encode(encoder)
		encodeid(encoder, self[1])
	end
	
	function Object:decode(decoder)
		self[1]		= decodeid(decoder)
	end
	
	function meta.object(element_type)
		local obj = setmetatable({}, Object)
		obj[1]	  = element_type
		return memoize_type(obj)
	end
end 

do 
	local Embedded = newmetatype(tags.EMBEDDED)
	function Embedded:encode(encoder)
		encodeid(encoder, self[1])
	end 
	
	function Embedded:decode(decoder)
		self[1] = decodeid(decoder)
	end
	
	function Embedded:typecheck(other)
		return other[1] == meta.void or 
		       self[1]  == meta.void or
			   meta.typecheck(other[1], self[1]) 
	end 
	
	function meta.embedded(element_type)
		local emb = setmetatable({}, Embedded)
		emb[1]	  = element_type
		return memoize_type(emb)
	end
end 

do 
	local Semantic = newmetatype(tags.SEMANTIC)
	function Semantic:encode(encoder)
		encoder:writef("s", self.identifier)
		encodeid(encoder, self[1])
	end
	
	function Semantic:decode(decoder)
		self.identifier = decoder:readf("s")
		self[1] = decodeid(decoder)
	end 
	 
	function meta.semantic(id, element_type)
		local semantic 		= setmetatable({}, Semantic)
		semantic[1]	   		= element_type
		semantic.identifier = id 
		return memoize_type(semantic)
	end
end 

do 
	local Align   = newmetatype(tags.ALIGN)
	function Align:encode(encoder)
		encoder:writef("V", self.alignof)
		encodeid(encoder, self[1])
	end  
	
	function Align:decode(decoder)
		self.alignof = decoder:readf("V")
		self[1]   = decodeid(decoder)
	end
	
	local function fixedalignencode(self, encoder)
		encodeid(encoder, self[1])
	end
	
	local function fixedaligndecode(self, decoder)
		self.alignof = self.fixedalignof
		self[1] = decodeid(decoder)
	end 
	
	local function newaligntype(tag, alignof)
		local type = newmetatype(tag)
		type.fixedalignof = alignof 
		type.encode = fixedalignencode
		type.decode = fixedaligndecode
		return type 
	end 
	
	local align_tables = 
	{
		[1] = newaligntype(tags.ALIGN1, 1),
		[2] = newaligntype(tags.ALIGN2, 2),
		[4] = newaligntype(tags.ALIGN4, 4),
		[8] = newaligntype(tags.ALIGN8, 8)
	}
	
	function meta.align(element_type, alignof)
		local align = { }
		align[1]       = element_type
		align.alignof  = alignof 
		if align_tables[alignof] == nil then 
			setmetatable(align, Align)
		else 
			setmetatable(align, align_tables[alignof])
		end
		
		return memoize_type(align)
	end
end 

do 
	local Uint = newmetatype(tags.UINT)
	function Uint:encode(encoder)
		encoder:writef("V", self.bits)
	end
	
	function Uint:decode(decoder)
		self.bits = decoder:readf("V")
	end 
	
	function meta.uint(bits)
		return memoize_type(setmetatable( { bits = bits}, Uint))
	end 
end

do  
	local Sint = newmetatype(tags.SINT)
	function Sint:encode(encoder)
		encoder:writef("V", self.bits)
	end
	
	function Sint:decode(decoder)
		self.bits = decoder:readf("V")
	end 
	
	function meta.int(bits)
		return memoize_type(setmetatable({ bits = bits}, Sint))
	end
end 

do 
	local Typeref = { } Typeref.__index = Typeref 
	
	--We can do this since we know the layout of the 
	--meta types. 
	local function fixrefs(meta, ref, value)
		if meta.typeref_fixing then return 0 end 

		--Fixing cyclic references 
		meta.typeref_fixing = true
		local count = 0
		for i=1, #meta do 		
			if meta[i] == ref then
				meta[i] = value
				count = count + 1
			end  
			
			count = count + fixrefs(meta[i], ref, value)								
		end 
		
		meta.typeref_fixing = nil
		return count
	end
	
	function Typeref:encode() error("uninitialized typeref") end 
	function Typeref:decode() error("uninitialized typeref") end 
	
	function Typeref:setref(meta)
		local numfixed = fixrefs(meta, self, meta)
		if numfixed == 0 then 
			--IF we did not fix any references we are setting 
			--the typeref to something that is not a graph.
			--This would indicate inproper useage of typerefs
			--or that there is a structural problem with metatypes. 
			error("only use typerefs when constructing graphs! otherwize use normal types")
		end
				
		return memoize_type(meta) 	
	end
	
	function meta.typeref()
		return setmetatable({tag = tags.TYPEREF}, Typeref)
	end
	
	function meta.istyperef(type)
		return type.tag == tags.TYPEREF
	end   	
end 

function meta.tostring(type, level)
	if level == nil then level = 0 end 
	type.is_writing_to_string = true

	local s = string.rep(" ", level) .. tags[type.tag] .. "\n"
	for i=1, #type do 
		if not type[i].is_writing_to_string then 
			s = s .. meta.tostring(type[i], level + 1)	
		end 
	
	end 
	
	type.is_writing_to_string = false
	return s or ""
end 

--Checks if two types are compatible. 
function meta.typecheck(typeA, typeB)
	if typeA == typeB then return true end 
	
	local mtA = getmetatable(typeA)
	local mtB = getmetatable(typeB)
	
	if mtA == mtB then 
		local typecheck = mtA.typecheck
		if typecheck then 
			return typecheck(typeA, typeB)
		end 
		
		if #typeA == #typeB then 
			local success = true
			for i=1, #typeA do 
				if not meta.typecheck(typeA[i], typeB[i]) then 
					success = false
					break
				end
			end
			return success 
		else 
			return false
		end 
	else 
		return false
	end 
end 

return meta