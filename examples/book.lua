local encoding = require"encoding"

-- We are going to encode a simple book description. 
local book = 
{
   id       = 1234,
   title    = "Programming in Lua",
   author   = "Roberto Ierusalimschy",
   pages    = 366,
}

--Open a file and write the book information to it.
local outfile = assert(io.open("EncodingHelloWorld.dat", "wb"))
encoding.encode(outfile, book)
outfile:close()

--Open a file and read back the book information from it.
local infile    = assert(io.open("EncodingHelloWorld.dat", "rb"))
local book      = encoding:decode(infile)
infile:close()

--Ensure that the decoded book contains the same data as the encoded book. 
assert(book.id     == 1234)
assert(book.title  == "Programming in Lua")
assert(book.author == "Roberto Ierusalimschy")
assert(book.pages  == 366)