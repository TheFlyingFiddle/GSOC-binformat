local tier  = require"tier"
local standard  = tier.standard
local primitive = tier.primitive

local bar_ref = standard.typeref()
local foo_mapping = standard.object(standard.tuple
{
   { key = "a_string", mapping = primitive.string }, 
   { key = "bar",      mapping = bar_ref }
})

local bar_mapping = standard.object(standard.tuple
{
   { key = "a_number", mapping = primitive.double },
   { key = "foo",      mapping = foo_mapping } 
})
bar_ref:setref(bar_mapping)

local output = io.open("CrossReferenceTypes.dat", "wb")

local foo = { a_string = "FizzBuzz" }
local bar = { a_number    = 52 , ["foo"] = foo }
foo.bar = bar

local tuple = standard.tuple 
{
    {mapping = foo_mapping},
    {mapping = bar_mapping}
}

tier.encode(output, {foo, bar}, tuple)
output:close()

local input = io.open("CrossReferenceTypes.dat", "rb")
local res     = tier.decode(input, tuple)
local foo_val = res[1]
local bar_val = res[2]

assert(foo_val == bar_val.foo)
assert(bar_val == foo_val.bar)