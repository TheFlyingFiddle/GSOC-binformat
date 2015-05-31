local io = require "io"
local debug = require "debug"
local array = require "table"
local table = require "loop.table"
local Viewer = require "loop.debug.Viewer"
local Matcher = require "loop.debug.Matcher"

encoding = require "encoding"
primitive = require "encoding.primitive"
standard = require "encoding.standard"

local function hexastream(output, stream, prefix, start)
	local cursor = {}
	local last = #stream
	local opened
	for count = 1, last do
		local base = start or 0
		local lines = string.format("\n%s%%0%dx: ", prefix or "", math.ceil(math.log((base+last)/16, 10))+1)
		local text = {}
		local opnened
		for count = count-(count-1)%16, last do
			local column = (count-1)%16
			-- write line start if necessary
			if column == 0 then
				output:write(lines:format(base+count-1))
			end
			-- write hexadecimal code
			local code = stream:byte(count, count)
			output:write(string.format(" %02x", code))
			if code == 0 then
				text[#text+1] = "."
			elseif code == 255 then
				text[#text+1] = "#"
			elseif stream:match("^[%w%p ]", count) then
				text[#text+1] = stream:sub(count, count)
			else
				text[#text+1] = "?"
			end
			-- write blank if reached the end of the stream
			if count == last then
				output:write(string.rep("   ", 15-column))
				text[#text+1] = string.rep(" ", 15-column)
				if column < 8 then output:write(" ") end
				column = 15
			end
			-- write ASCII text if last column, or a blank space if middle column
			if column == 15 then
				output:write(" |"..array.concat(text).."|")
				text = {}
			elseif column == 7 then
				output:write(" ")
			end
		end
		break
	end
end

local viewer = Viewer{
	linebreak = false,
	noindices = true,
	nolabels = true,
	metaonly = true,
}
local chunksize = 16
local function assertequals(value, actual, expected)
	local replace
	local afile = assert(io.open(actual, "rb"))
	local efile = assert(io.open(expected, "rb"))
	local lines = 0
	for adata in afile:lines(chunksize) do
		local edata = efile:read(chunksize)
		if adata ~= edata then
			afile:close()
			afile = assert(io.open(actual, "rb"))
			io.write("Encoding of '")
			viewer:write(value)
			io.write("'")
			if lines > 0 then
				io.write("\nCommon  :")
				hexastream(io.stdout, afile:read(lines*chunksize))
			end
			io.write("\nActual  :")
			hexastream(io.stdout, afile:read("*a"), nil, lines*chunksize)
			io.write("\nExpected:")
			hexastream(io.stdout, edata..efile:read("*a"), nil, lines*chunksize)
			io.write("\nShall the actual output replace the expected ? "); io.flush()
			replace = (string.find(io.read(), "^[yY]") ~= nil)
			break
		end
		lines = lines+1
	end
	afile:close()
	efile:close()
	if replace == nil then
		os.remove(actual)
	elseif replace == true then
		os.rename(actual, expected)
	else
		error("stream changed")
	end
end

local function asserterror(pattern, func, ...)
	local errorok
	local function handler(errmsg)
		if errmsg:match(pattern) then
			errorok = true
			return errmsg
		end
		return "unexpected error: "..errmsg
	end
	local callok, errmsg = xpcall(func, handler, ...)
	assert(not callok, "error was expected")
	assert(errorok, errmsg)
end

local tid = 0
function runtest(test)
	tid = tid+1
	local encodeerror = test.encodeerror
	local mapping = test.mapping
	local basedir = test.basedir or "streams"
	for gid, group in ipairs(test) do
		for cid, case in ipairs(group) do
			local basename = basedir.."/out_t"..tid.."g"..gid.."c"..cid
			local outpath = basename..".dat"
			local regression = not test.noregression and io.open(outpath)
			if regression then
				regression:close()
				outpath = basename..".new"
			end

			do
				local file = assert(io.open(outpath, "wb"))
				local encoder = encoding.encoder(file, true)
				if encodeerror == nil then
					encoder:encode(mapping, case.actual)
				else
					asserterror(encodeerror, encoder.encode, encoder, mapping, case.actual)
				end
				encoder:close() -- do we expect this can be called after 'encode' raised an error?
				file:close()
			end

			if regression then
				assertequals(case.actual, outpath, basename..".dat")
				outpath = basename..".dat"
			end

			if encodeerror == nil then
				local file = assert(io.open(outpath, "rb"))
				local decoder = encoding.decoder(file, true)
				local recovered = decoder:decode(mapping)
				decoder:close()
				file:close()
				local expected = case.expected
				if expected == nil then
					if test.defaultexpected == nil then
						expected = case.actual
					else
						expected = test.defaultexpected
					end
				end
				if test.rounderror ~= nil then
					assert(math.abs((recovered-expected)/expected) < test.rounderror,
						"recovered value is too different from the expected")
				else
					local matcher = Matcher(table.copy(test.compareopts or {}))
					local ok, errmsg = matcher:match(recovered, expected)
					if not ok then print(recovered, expected) end
					assert(ok, errmsg)
				end
			end
		end
	end
end
