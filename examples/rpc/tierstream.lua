local TcpStream = { }
TcpStream.__index = TcpStream
local substr = string.sub

function TcpStream:write(data)
	assert(type(data) == "string")
	
	local datasize  = #data
	local buffered  = self.write_buffer
	local bufsize   = #buffered
	local flushsize = self.write_size
	
	--Deals with partial sends 
	if datasize + bufsize > flushsize then
		if datasize > flushsize then
			self:flush()
			self.write_buffer = data 
			self:flush()
		else 
			self.write_buffer = buffered .. data 
			self:flush()	
		end
	else
		self.write_buffer = buffered .. data	
	end
end

function TcpStream:read(count)
	local recv, err = self.socket:receive(count)
	if recv then 
		return recv
	else
		error("Failed to read from the socket, with error " .. err)
	end
end

function TcpStream:flush()
	if #self.write_buffer == 0 then return end
	local sent, err, partial = self.socket:send(self.write_buffer)
	
	self.write_buffer = ""
	if err then 
		error("Failed to write to socket, with error " .. err)
	end
	
end

function TcpStream:close()
	self:flush()
	self.socket:close()
end

local function tcpstream(tcp_socket, write_size)
	local stream = setmetatable({ }, TcpStream)
	stream.read_buffer  = ""
	stream.write_buffer = ""
	stream.write_size   = write_size or 16
	stream.socket       = tcp_socket
	return stream
end

local tier 	   = require"tier"
local cool_dynamic = require"experimental.dynamic"

local TierStream = { }
TierStream.__index = TierStream
function TierStream:put(...)
	local tuple = { ... }
	self.encoder:encode(cool_dynamic, tuple)
	self.stream:flush()
end

local unpack = table.unpack
function TierStream:get()
	return unpack(self.decoder:decode(cool_dynamic))
end

function TierStream:close()
	self.stream:close()
end

local function tierstream(tcp_socket, write_size, read_size)
	local stream   = setmetatable({ }, TierStream)
	stream.stream  = tcpstream(tcp_socket, write_size, read_size)

	stream.encoder = tier.encoder(tier.writer(stream.stream))
	stream.decoder = tier.decoder(tier.reader(stream.stream))
	return stream 	
end

return tierstream