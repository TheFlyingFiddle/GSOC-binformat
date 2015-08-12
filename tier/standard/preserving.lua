local meta = require"tier.meta"
local types  

local Preserving = { meta = meta.dynamic }

function Preserving:encode(encoder, value, ...)
	local mapping = value.mapping
	local data    = value.data
	types:encode(encoder, mapping)
	mapping:encode(encoder, data, ...)
end 

function Preserving:decode(decoder, ...)
	local mapping = types:decode(decoder, value)
	local data    = mapping:decode(decoder, ...)
	return { ["mapping"] = mapping, ["data"] = data }
end 

return function(s)
	assert(s.type, "Meta type mapping standard.type must be initialized before this module is loaded!")
	s.preserving = Preserving
	types        = s.type	
end 