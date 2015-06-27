local encoding  = require"encoding"
local standard  = encoding.standard
local primitive = encoding.primitive

--A reference mapping of string values
local string_ref_mapping = standard.object(primitive.string)

--
local output = io.open("References.dat", "wb")

local string_list        = standard.list(string_ref_mapping)
local fruit_basket       = 
{
   "Apple", "Orange", "Apple", 
   "Banana", "Orange", "Pineapple",
   "Banana", "Apple"
}

--Will only encode the full values "Apple", "Orange", "Banana" and "Pineapple" a 
--single time. The other times will simply be instream references. 
encoding.encode(output, fruit_basket, string_list)

local person_ref_mapping = standard.object(standard.tuple
{
     { key = "first_name", mapping = primitive.string },
     { key = "last_name",  mapping = primitive.string },
     { key = "age",        mapping = primitive.uint8  }
})

local task_mapping = standard.tuple
{
     { key = "assigned",    mapping = person_ref_mapping },
     { key = "description", mapping = primitive.string } 
}

local task_list = standard.list(task_mapping)

local persons = 
{ 
     john = { first_name = "John", last_name = "Doe",   age = 23 },
     jane = { first_name = "Jane", last_name = "Doe",   age = 32 }
}

local tasks = 
{
    { assigned = persons.john, description = "Build a Time machine" },
    { assigned = persons.john, description = "Travel back in time" },  
    { assigned = persons.jane, description = "Invent warp drive" },
    { assigned = persons.jane, description = "Visit Orion" }
}

--Encode the tasks, the persons john and jane will only be encoded a single time.
--Thus their references will be valid even after the decoding.
encoding.encode(output, tasks, task_list)
output:close()

local input  = io.open("References.dat", "rb")
local fruits = encoding.decode(input, string_list)
local tasks  = encoding.decode(input, task_list)

--Make sure that the referential integrity is still there.
assert(tasks[1].assigned == tasks[2].assigned)