local encoding = require"encoding"

local composed = { }

local ArrayMT = { }
ArrayMT.__index = ArrayMT
function ArrayMT:encode(encoder, value)
	encoder:writevarint(self.size)
	for i=1,size,1 do
		encoder:encode(self.mapper, self.handler:getitem(value, i))
	end
end

function ArrayMT:decode(decoder)
	local size = self.size;
	local value = self.handler:create();
	for i=1, size, 1 do
		local item = decoder:decode(self.mapper)
		self.handler:setitem(value, i, item)
	end
end

function composed.array(handler, mapper, size)
	local array = { }
	setmetatable(array, ArrayMT)
	array.tag	  = encoding.tags.ARRAY .. mapper.tag
	array.size    = size
	array.handler = handler
	array.mapper  = mapper
	return array	
end

local ListMT = {  }
ListMT.__index = ListMT;
function ListMT:encode(encoder, value)
	local size = self.handler:getsize(value)
	encoder:writevarint(size)
	for i=1,size, 1 do
		encoder:encode(self.mapper, self.handler:getitem(value, i))	
	end	
end

function ListMT:decode(decoder)
	local size = decoder:readvarint()
	local value  = self.handler:create(size)
	for i=1,size, 1 do
		local item = decoder:decode(self.mapper)
		self.handler:setitem(value, i, item)
	end
	return value;
end

function composed.list(handler, mapper)
	local list = { 	}
	setmetatable(list, ListMT)
	list.tag	= encoding.tags.LIST .. mapper.tag;
	list.handler = handler;
	list.mapper	 = mapper;
	return list;
end

local SetMT = {  }
SetMT.__index = SetMT;
function SetMT:encode(encoder, value)
	local size = self.handler:getsize(value)
	encoder:writevarint(size)
	for i=1,size, 1 do
		encoder:encode(self.mapper, self.handler:getitem(value, i))	
	end	
end

function SetMT:decode(decoder)
	local size = decoder:readvarint()
	local value  = self.handler:create(size)
	for i=1,size, 1 do
		local item = decoder:decode(self.mapper)
		self.handler:putitem(value, item)
	end
	return value;
end

function composed.set(handler, mapper)
	local list = { 	}
	setmetatable(list, SetMT)
	list.tag	= encoding.tags.SET .. mapper.tag;
	list.handler = handler;
	list.mapper	 = mapper;
	return list;
end


local MapMT = { }
MapMT.__index = MapMT
function MapMT:encode(encoder, value)
	print("called")
	local size = self.handler:getsize(value)
	encoder:writevarint(size)
	for i=1, size, 1 do
		local key, item = self.handler:getitem(value, i);
		encoder:encode(self.keymapper, key)
		encoder:encode(self.itemmapper, item);
	end
end

function MapMT:decode(decoder)
	local size  = decoder:readvarint();
	local value = self.handler:create(size)
	for i=1, size, 1 do
		local key  = decoder:decode(self.keymapper)
		local item = decoder:decode(self.itemmapper)
		self.handler:putitem(value, key, item)
	end 
	
	return value;
end

function composed.map(handler, keymapper, itemmapper)
	local map = { }
	setmetatable(map, MapMT)
	map.tag	  = encoding.tags.MAP .. keymapper.tag .. itemmapper.tag	
	map.handler    = handler
	map.keymapper  = keymapper
	map.itemmapper = itemmapper
	return map;
end

local TupleMT = { }
TupleMT.__index = TupleMT
function TupleMT:encode(encoder, value)
	for i=1, #self.mappers, 1 do
		local mapper = self.mappers[i]
		local item   = self.handler:getitem(value, i)
		encoder:encode(mapper, item);
	end
end

function TupleMT:decode(decoder)
	local value = self.handler:create();
	for i=1, #self.mappers, 1 do
		local mapper = self.mappers[i] 
		local item 	 = decoder:decode(mapper)
		self.handler:setitem(value, i, item)
	end
	return value;	
end

function composed.tuple(handler, ...)
	local tuple = { }
	setmetatable(tuple, TupleMT)
	tuple.mappers = { ... }
	tuple.handler = handler
	
	local tag = encoding.tags.TUPLE .. string.pack("B", #tuple.mappers)
	for i=1, #tuple.mappers, 1 do
		tag = tag .. tuple.mappers[i].tag
	end
	tuple.tag = tag
	
	return tuple;
end

local UnionMT = { }
UnionMT.__index = UnionMT
function UnionMT:encode(encoder, value)
	local kind, encodable = self.handler:select(value)
	encoder:writevarint(kind)
	encoder:encode(self.mappers[kind], value)
end

function UnionMT:decode(decoder)
	local kind    = decoder:readvarint();
	local decoded = decoder:decode(self.mappers[kind])
	return self.handler:create(kind, encoded)
end

function composed.union(handler, ...)
	local union = { }
	setmetatable(union, UnionMT)
	union.handler = handler
	union.mappers = { ... }
	
	local tag = encoding.tags.UNION .. string.pack("B", #union.mappers)
	for i=1, #union.mappers, 1 do
		tag = tag .. union.mappers[i].tag
	end
	union.tag = tag
	
	return union
end

local SemanticMT = { }
SemanticMT.__index = SemanticMT
function SemanticMT:encode(encoder, value)
	encoder:encode(self.mapper, value)
end

function SemanticMT:decode(decoder)
	return decoder:decode(self.mapper)
end

function composed.semantic(id, mapper)
	local semantic = { }
	setmetatable(semantic, SemanticMT)
	
	semantic.tag    = encoding.tags.SEMANTIC .. id .. mapper.tag
	semantic.mapper = mapper
	return semantic
end

--Left to implement is
-- object and embedded

return composed