local tier      = require"tier"
local standard  = tier.standard 
local primitive = tier.primitive
local format    = require"format"

local ostream = format.outmemorystream
local istream = format.inmemorystream

local semantic  = standard.semantic
local bytearray = standard.bytearray
local embedded  = standard.embedded
local opaque    = standard.opaque
local tuple		= standard.tuple
local uint32	= primitive.uint32
local string    = primitive.string
local stream    = primitive.stream
local dynamic   = standard.dynamic
local list      = standard.list

local UUID   	 = semantic("UUID", bytearray(32))
local SHA256 	 = semantic("SHA256", bytearray(32))
local Credential = embedded(tuple{
	{ key = "login",   mapping = UUID },
	{ key = "session", mapping = uint32 },
	{ key = "ticket",  mapping = uint32 },
	{ key = "hash",    mapping = SHA256 }
})

local CallRequest = tuple{
	{ key = "operation", mapping = string },
	{ key = "targetid",  mapping = stream },
	{ key = "parameters", mapping = list(dynamic) },
	{ key = "credential", mapping = Credential }
}

local CallRequest2 = tuple{
	{ key = "operation",  mapping = string },
	{ key = "targetid",   mapping = stream },
	{ key = "parameters", mapping = list(dynamic) },
	{ key = "credential", mapping = opaque() }
}

local data = 
{
	operation  = "add",
	targetid   = "localhost",
	parameters = { 1, 2 },
	credential = 
	{
		login   = "de305d5475b4431badb2eb6b9e546014",
		session = 32, 
		ticket  = 3124,
		hash    = "de305d5475ee431badb2eb6b9e546014",
	}
}

--We check that the contents of the stream are preserved after it has been encoded as an 
--opaque type and then decoded to the proper type. 
local output = tier.encodestring(data, CallRequest)
local res = tier.decode(output, CallRequest2)
output	  = tier.encodestring(res, CallRequest2)
res = tier.decode(output, CallRequest)

assert(res.credential.login 	== 	data.credential.login)
assert(res.credential.session 	== 	data.credential.session)
assert(res.credential.ticket 	== 	data.credential.ticket)
assert(res.credential.hash 		== 	data.credential.hash)