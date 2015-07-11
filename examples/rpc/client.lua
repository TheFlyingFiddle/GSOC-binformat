local socket 	= require"socket"
local tier 	= require"tier"
local tierstream	= require"examples.rpc.tierstream"

local Proxy = { }

local function handleresults(success, ...)
	if not success then error(...) end
	return ...
end

function Proxy:__index(method)
	return function(proxy, ...)
		local stream = tierstream(assert(socket.connect(proxy.host, proxy.port)))
		stream:put(proxy.name, method, ...)
		return handleresults(stream:get())
	end	
end

local evaluator = setmetatable(
{
	name = "evaluator",
	host = "localhost",
	port = 12345
}, Proxy)

local function fat(n)
	local res = 1
	for i=1, n do
		res = res * i
	end
	return res
end

local function fatrec(n)
	if n == 0 
		then return 1
		else return n * fatrec(n - 1)
	end
end

evaluator:repeats(999)
evaluator:execute("iterative", fat, 999)
evaluator:execute("recursive", fatrec, 999)
local n, results = evaluator:report()
for name, result in pairs(results) do 
	print("", name, result) 
end