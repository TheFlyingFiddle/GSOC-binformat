local tier  = require"tier"
local custom	= require"tier.custom"

local standard  = tier.standard
local primitive = tier.primitive

local dna_table = 
{
	A = 0, a = 0,
	T = 1, t = 1,
	G = 2, g = 2,
	C = 3, c = 3,
	
	[0] = "A", [1] = "T",
	[2] = "G", [3] = "C"
}

local DnaTransform = { }
function DnaTransform:to(value)
	assert(type(value) == "string", "expected string")

	local list = { }
	for i=1, #value do
		local char   = string.sub(value, i, i);
		local bitval = dna_table[char]
		table.insert(list, bitval)		
	end	
	
	return list
end

function DnaTransform:from(dna_list)
	for i=1, #dna_list do
		dna_list[i] = dna_table[dna_list[i]]
	end
	return table.concat(dna_list)
end

local dna_mapping = custom.transform(DnaTransform, custom.semantic("DNA", standard.list(primitive.uint2)))


--Tests
local tests = { "AGGTGGGCTTTAATTAATTACCGGAAGGTTAACCTT" }

local stream = io.open("DNA.dat", "wb")
tier.encode(stream, tests[1], dna_mapping)
stream:close()

stream = io.open("DNA.dat", "rb")
local res = tier.decode(stream, dna_mapping);
assert(res == tests[1])
stream:close();