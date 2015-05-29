local encoding = require"encoding"

local testing = { }

--Faked output stream.
--It stores it's output in a string.
local outMT = { }
outMT.__index = outMT
function outMT:write(string)
	self.buffer = self.buffer .. string;		
end

function outMT:flush() end
function outMT:close() end

--Faked input stream.
--Reads it's input from a string.
local inMT = { }
inMT.__index = inMT
function inMT:read(count)
	local res = string.sub(self.buffer, self.pos, self.pos + count - 1)
	self.pos = self.pos + count
	return res;
end

function testing.outstream()
	local mock = { }
	mock.buffer = ""
	setmetatable(mock, outMT)
	return mock
end

function testing.instream(str)
	local mock = { }
	setmetatable(mock, inMT)
	mock.pos   = 1
	mock.buffer = str
	return mock	
end


function testing.randomInts(min, max, count)
	local numbers = { }
	for i=1, count, 1 do
		table.insert(numbers, math.random(min, max))
	end
	return numbers
end

function testing.randomDoubles(count)
	local numbers = { }
	for i=1, count, 1 do
		table.insert(numbers, math.random())
	end
	return numbers
end

function testing.deepEquals(a, b)
	local ta = type(a)
	local tb = type(b)

	if ta ~= tb then return false end
	
	if ta == "table" then 
		for k, v in pairs(a) do
			if not testing.deepEquals(b[k], v) then
				return false
			end
		end
		return true
	else 
		return a == b;
	end
end

local function pf(a, l)
	local level = l
		
	if type(a) == "table" then
		local space1 = ""
		local space2 = ""
 		for i=1, level, 1 do
			space1 = space1 .. "  ";
		end
		space2 = space1 .. "  "
				
		local s = "\n" .. space1 .. "{\n"
		for k, v in pairs(a) do
			s = s .. space2 .. "[" .. pf(k, level + 1) .. "] = " .. pf(v, level + 1) .. "\n" 
		end
		s = s .. space1 .. "}"
		return s;
	elseif type(a) == "string" then
		return "\"" .. a .. "\""
	else
		return tostring(a)
	end
end

function testing.prettyPrint(a)
	print(pf(a, 0))
end

function testing.testmapping(data, mapping)
	local out = testing.outstream();
	encoding.encode(out, data, mapping)
	local in_ = testing.instream(out.buffer)
	local value = encoding.decode(in_, mapping)
	assert(testing.deepEquals(data, value))
end

return testing