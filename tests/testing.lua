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


return testing