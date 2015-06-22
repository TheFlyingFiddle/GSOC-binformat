#TIER
TIER is a simple to use binary encoding and serialization format implemented in the Lua programing language. It is primarily intended to be used as a data communication format. It is an alternative to other popular encoding formats such as JSON, XML and Google's Protocol Buffers. What sets TIER apart from these formats and others like them is that data encoded in TIER can optionally be encoded together with type metadata. This metadata gives valuable context to the application. What kind of data is encoded, how to decode that data ability to do type checking and more. This kind of information can be invaluable when debugging problems in data communication between applications. 

##Usage
To use TIER simply require the encoding module and start. For example:
```lua
--Contains everything needed to encode simple things.
local encoding = require"encoding"
local standard = encoding.standard

--A mapping object maps application value to and from TIER encodings.
--This particular mapping maps tables to list of 32 bit integers. 
local mapping = standard.list(encoding.primitive.int32)

--Data to encode.
local out_list = { 1, 1, 2, 3, 5, 8, 13 } 

--Destination file. 
local output = io.open("Fibonacci.dat", "wb")

--Encodes the list in the TIER format using the mapping. 
encoding.encode(output, out_list, mapping)
output:close()

--We read from the destination file. 
local input   = io.open("Fibonacci.dat", "rb");

--Decodes the file into a list again.
--Metadata is encoded together with the sequence so we 
--Dont have to supply a mapping.
local in_list = encoding.decode(input)
input:close()

--Check that the list contains the same stuff.
for i=1, #out_list do
	assert(out_list[i] == in_list[i])
end
```
The example encodes the first seven numbers in the Fibonacci sequence to the file "Fibonacci.dat".
Note the mapping that is supplied to the encode function, this mapping tells the encode function how 
to encode the value. In this case a list of 32 bit integers. The later part of the example decodes the 
"Fibonacci.dat" file back into an application list. Notice that it is not neccessary to provide a mapping 
to this function. The file already contains metadata that is used to figure out what kind of data that is decoded. 

##Documentation
The [wiki](https://github.com/TheFlyingFiddle/GSOC-binformat/wiki) contains a growing collection of tutorials 
on how to use the format. The exact encoding format is not yet set in stone but when it is the wiki will contain the
complete specification document. 

##How to get TIER
TIER is avaliable from this github repo. Simply clone the repo and extract the contents of the tier directory
to the standard lua path on your system. When the format and implementation has reached a more stable state
the format will be avaliable as a LuaRocks moonrock. 

##Version Alpa 0
TIER is currently in an alpha stage. It is not ready for production use. Anything from the code to the 
encoding format is stil subject to change. Changes are however more likely to be additions to the 
format or background changes that do not affect the end user api.