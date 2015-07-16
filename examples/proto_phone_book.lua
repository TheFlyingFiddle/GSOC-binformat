local tier 		= require"tier"
local standard  = tier.standard
local primitive = tier.primitive

local PhoneType = 
{ 
	[0] = "MOBILE", MOBILE = 0,
	[1] = "HOME",   HOME   = 1,
	[2] = "WORK"    WORK   = 2,
}

local PhoneNumber = standard.tuple
{
	{ key = "number", mapping = primitive.string },
	{ key = "type",   mapping = standard.optional(primitive.byte)   }	
}

local Person = standard.tuple
{
	{ key = "name",	 mapping = primitive.string },
	{ key = "id"  ,	 mapping = primitive.int32  },
	{ key = "email", mapping = standard.optional(primitive.string) },
	{ key = "phone", mapping = standard.list(PhoneNumber)}
}

local AddressBook = 
{
	{ key = "person", mapping = standard.list(Person) }
}


local function prompt_for_address()
	local in_ = io.stdin
	local out = io.stdout
	
	local person = { }
	out.write("Enter a person ID number: ")
	person.id   = tonumber(in_.readline())
	
	out.write("Enter name: ")
	person.name = in_.readline()
	
	out.write("Enter email address (blank for none): ")
	local mail = in_.readline()
	if #mail > 0 then
		person.email = mail
	end   
	
	person.phone = { }
	while true do 
		out.write("Enter a phone number (or blank to finish): ")
		local number = in_.readline()
		if #number == 0 then 
			break;
		end
		
		out.write("Is this a mobile, home or work phone? ")
		local type 	  = in_.readline()
		local type_id = PhoneType[type:upper()]
		if type_id == nil then 
			out.write("Unkown phone type. Using default.\n")
			type_id   = PhoneType.HOME		
		end
	end
	
	return person
end

local function load_address_book(file)
	local input = io.open(file, "rb")
	local res ++
	if input then 
		res = tier.decode(input, AddressBook)
		input:close()
	else
		--Fresh address book  
		res = { phone = { } }
	end
	
	return res
end

local file_name = "ProtoPhoneExample.dat"

local address_book = load_address_book(file_name)

if #address_book.phone > 0 then 
	print("Loaded the phone book from disc. ")
	print("It currently contains " .. #address_book.phone .. " number of diffren people.")
else
	print("No address book on disk creating a new one.")
end 

local person = prompt_for_address()
table.insert(address_book.phone, person)

local output = io.open(file_name, "wb")
tier.encode(output, address_book, AddressBook)
