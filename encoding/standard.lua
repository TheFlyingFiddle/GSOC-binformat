local encoding = require"encoding"
local composed = require"encoding.composed"

local standard = { }

local TableAsList = { }
function TableAsList:getsize(value) return #value end
function TableAsList:getitem(value, index) return value[index] end
function TableAsList:create(size) return { } end
function TableAsList:setitem(value, index, item) value[index] = item end

local newlist = composed.list;
function standard.list(...)
	return newlist(TableAsList, ...)
end

local newarray = composed.array;
function standard.array(...)
	return newlist(TableAsList, ...)
end

local TableAsMap = { }
function TableAsMap:getsize(value) return #value end
function TableAsMap:getitem(value, i)
	local counter = 0;
	for k, v in pairs(value) do 
		if counter == i then
			return k, v;
		end
		counter = counter + 1;
	end
	
	return nil;
end

function TableAsMap:create(size)
	return { }
end

function TableAsMap:putitem(value, key, item)
	value[key] = item;
end

local newmap = composed.map;
function standard.map(...)
	return newmap(TableAsMap, ...)
end

local TableAsTupleMT = { }
TableAsTupleMT.__index = TableAsTupleMT
function TableAsTupleMT:getitem(value, index)
	local key = self.keys[index]
	return value[key];
end

function TableAsTupleMT:create()
	return { }
end

function TableAsTupleMT:setitem(value, index, item)
	local key = self.keys[index]
	value[key] = item;
end

local newtuple = composed.tuple;
function standard.tuple(members)
	local keys 	  = { }
	local mappers = { }

	for i=1, #members, 1 do
		local member = members[i];
		mappers[i] = member.mapping;
		if member.key then
			keys[i] = member.key
		else
			keys[i] = i;
		end 
	end

	local handler = { }
	setmetatable(handler, TableAsTupleMT)
	handler.keys = keys;
	
	return newtuple(handler, table.unpack(mappers))				
end


local TypeUnionMT = { }
TypeUnionMT.__index = TypeUnionMT;
function TypeUnionMT:select(value)
	local typeof = type(value)
	local counter = 1
	for k,v in pairs(self.kinds) do
		if k == typeof then 
			return counter, v;
		end
		counter = counter + 1
	end	
	
	error(string.format("Cannot encode type: %s", typeof))
end

function TypeUnionMT:create(kind, value)
	return value;
end

local newunion = composed.union;
function standard.union(kinds)
	local handler = { }
	setmetatable(handler, TypeUnionMT)
	handler.kinds = kinds;
	
	local mappers = { }
	for k, v in pairs(kinds) do
		table.insert(mappers, v)
	end
	
	return newunion(handler, table.unpack(mappers))	
end



return standard