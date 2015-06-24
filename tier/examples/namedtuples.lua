local encoding  = require"encoding"
local primitive = encoding.primitive
local standard  = encoding.standard

--A standard vector2 mapping. 
local vector_mapping = standard.tuple
{
   { key = "x", mapping = primitive.float },
   { key = "y", mapping = primitive.float }
}

--A mapping from a Lua table representing a monster to an encoded monster.
--It's important to note that the fields will be encoded in the order,
--that they are laid out within the tuple. Thus it will not
--continue to work if the order of the fields are changed.
local monster_mapping = standard.tuple
{
   { key = "name",         mapping = primitive.string },
   { key = "health",       mapping = primitive.uint16 },
   { key = "mana",         mapping = primitive.uint16 },
   { key = "position",     mapping = vector_mapping }, 
   { key = "friendly",     mapping = primitive.boolean } 
}

local monster_data = 
{
   name     = "Imp Wizard", 
   health   = 200,
   mana     = 175,
   position = { x = 10.0, y = 35.0 },
   friendly = false
}

local output = io.open("NamedTuples.dat", "wb")

--Encode the monster!
--The monster_mapping looks at all the fields in the monster_data
--and encodes them one after the other.
encoding.encode(output, monster_data, monster_mapping) 
output:close()

--We read back the monster data.
local input = io.open("NamedTuples.dat", "rb")
local monster = encoding.decode(input, monster_mapping);
input:close()