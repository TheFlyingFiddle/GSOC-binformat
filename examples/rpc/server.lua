local socket 	 = require"socket"
local tierstream = require"examples.rpc.tierstream"

evaluator = { }
function evaluator:repeats(count)
	self.results = { }
	self.count = count
end

function evaluator:execute(name, func, ...)
	local time = socket.gettime()
	for i=1, self.count do
		func(...)
	end
	self.results[name] = socket.gettime() - time
end

function evaluator:report()
	return self.count, self.results
end

local function dispatch(name, method, ...)
	local object = _G[name]
	if object then
		if type(object[method]) == "function" then
			return pcall(object[method], object, ...)
		else
			return false, "method '" .. method .. "' not found"
		end
	else
		return false, "object '" .. name .. "' not found"
	end
end

local server  = assert(socket.bind("localhost", 12345))
local channel, errmsg
repeat
	channel, errmsg = server:accept()
	if channel then
		local stream = tierstream(channel)
		local params = { stream:get() }
		local data = { dispatch(table.unpack(params)) }
		stream:put(table.unpack(data))
		channel:close()
	end
until errmsg
server:close()