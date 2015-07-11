The experimental folder contains stuff not yet ready for production

###The optimal module
The optimal module contain mappings that are as fast as they can be.
Or atleast as fast as I can make them. Currently there is only one mapping
the mapping for uncompressed numbers. It deals with all number types that 
can be packed using the standard string.pack function.

###The dynamic module
The dynamic module contains an experimental implementation of a standard dynamic
mapping module. What makes it diffrent from the dynamic module currently in use
is that it does lots of introspection on the values to get better mappings. So far
it can recognise lists, sets, maps and tuples. The subtypes of these mappings
can be either primitives or dynamic types. 

I have plans for adding function support to this module aswell. 

Update: Function support has been added and I have switched from the old dynamic
implementation to the new one.

###The compression module
This is largly unfinished but the idea of this module is to create some compression 
mappings primarialy list of number compressing. The plan is to test it with 
simple16 and go from there. The goal is to be able to have compressed data.

###Other plans
A converter module that can convert from one mapping to another enabeling automatic
file conversions. What can be done with this has to be seen. 