
local io = require "io"
local debug = require "debug"
local array = require "table"
local table = require "loop.table"
local oo = require "loop.base"
local Viewer = require "loop.debug.Viewer"
local Matcher = require "loop.debug.Matcher"

tags = require "encoding.tags"
encoding = require "encoding"
primitive = encoding.primitive
standard = encoding.standard
custom   = require"encoding.custom"

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

viewer = Viewer{
	linebreak = false,
	noindices = true,
	nolabels = true,
	--metaonly = true,
}
local chunksize = 16
local function assertequals(value, actual, expected)
	local replace
	local afile = assert(io.open(actual, "rb"))
	local efile = assert(io.open(expected, "rb"))
	local lines = 0
	for adata in afile:lines(chunksize) do
		local edata = efile:read(chunksize) or ""
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
			hexastream(io.stdout, edata..(efile:read("*a") or ""), nil, lines*chunksize)
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

local function assertcount(count, ...)
	if count ~= nil then
		assert(select("#", ...) == count, "wrong number of results")
	end
	return ...
end

local function asserterror(pattern, func, ...)
	local errorok
	local function handler(errmsg)
		if errmsg:match(pattern) or pattern == "any" then
			errorok = true
			return errmsg
		end
		return "unexpected error: "..errmsg
	end
	local callok, errmsg = xpcall(func, handler, ...)
	assert(not callok, "error was expected")
	assert(errorok, errmsg)
end

local function tohexa(c)
	return string.format("%02x", string.byte(c))
end

local unsafe = "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%._-]"
local function tofilename(mapping, case)
	local value = case.actual
	local id = case.id or viewer.labels[value] or viewer:tostring(value)
	
	local tagid
	if mapping.id then
		tagid = tags[mapping.tag] .. "_" .. string.gsub(mapping.id, ".", tohexa) 
	else
		tagid = tags[mapping.tag]	
	end
	return tagid .. "_"..type(value)..
	  "_"..string.gsub(string.sub(id,1, 128), unsafe, "")
end

local BufferStream = oo.class{
	position = 0,
	write = array.insert,
	flush = function () end,
}
function BufferStream:close()
	self.stream = self.stream or array.concat(self)
end
function BufferStream:read(count)
	local pos = self.position
	local finish = pos+count
	self.position = finish
	return self.stream:sub(pos+1, finish)
end

local function rundynamictest(test)
	local mapping = test.mapping
	local basedir = test.basedir or "streams"
	for gid, group in ipairs(test) do
		for cid, case in ipairs(group) do
			io.write("Dyn_" .. tags[mapping.tag], ": "); viewer:write(case.actual); io.write(" ... "); io.flush()
			local output = BufferStream()
			
			do
				local encoder = encoding.encoder(output, true)
				encoder:encode(mapping, case.actual)
				encoder:close()
				output:close()
			end
			
			do 
				local decoder = encoding.decoder(output, false)
				local recovered = assertcount(test.countexpected, decoder:decode(standard.dynamic))
				decoder:close()
				output:close()	
				
				if test.countexpected == nil or test.countexpected > 0 then
					local expected = case.expected
					if expected == nil then
						if test.defaultexpected ~= nil then
							expected = test.defaultexpected
						else
							expected = case.actual
						end
					end
					if test.rounderror ~= nil then
						assert(math.abs((recovered-expected)/expected) < test.rounderror,
							"recovered value is too different from the expected")
					elseif test.matcher ~= nil then
						local ok, errmgs = test.matcher(recovered, expected)
						if not ok then 
							print(recovered, excpected)
						end					
						assert(ok, errmsg)
					else
						local matcher = Matcher(table.copy(test.compareopts or {}))
						local ok, errmsg = matcher:match(recovered, expected)
						if not ok then print(recovered, expected) end
						assert(ok, errmsg)
					end
					viewer:write(recovered)
				end
				print()
			end
		end
	end
end


local tid = 0
function runtest(test)
	tid = tid+1
	local encodeerror = test.encodeerror
	local mapping = test.mapping
	local basedir = test.basedir or "streams"
	for gid, group in ipairs(test) do
		for cid, case in ipairs(group) do
			io.write(tags[mapping.tag],": "); viewer:write(case.actual); io.write(" ... "); io.flush()
			local basename = basedir.."/"..tofilename(mapping, case)
			local outpath = basename..".dat"
			local regression = not test.noregression and io.open(outpath)
			if regression then
				regression:close()
				outpath = basename..".new"
			end

			local output = test.noregression and BufferStream()
			                                  or assert(io.open(outpath, "wb"), "no such file\n\n\n" .. outpath)
			do
				local encoder = encoding.encoder(output, false)
				if encodeerror == nil then
					encoder:encode(mapping, case.actual)
				else
					asserterror(encodeerror, encoder.encode, encoder, mapping, case.actual)
				end
				encoder:close() -- do we expect this can be called after 'encode' raised an error?
				output:close()
			end

			if regression then
				assertequals(case.actual, outpath, basename..".dat")
				outpath = basename..".dat"
			end

			if encodeerror == nil then
				local input = test.noregression and output
				                                 or assert(io.open(outpath, "rb"))
				local decoder = encoding.decoder(input, false)
				local recovered = assertcount(test.countexpected, decoder:decode(mapping))
				decoder:close()
				input:close()
				
				if test.countexpected == nil or test.countexpected > 0 then
					local expected = case.expected
					if expected == nil then
						if test.defaultexpected ~= nil then
							expected = test.defaultexpected
						else
							expected = case.actual
						end
					end
					if test.rounderror ~= nil then
						assert(math.abs((recovered-expected)/expected) < test.rounderror,
							"recovered value is too different from the expected")
					elseif test.matcher ~= nil then
						local ok, errmgs = test.matcher(recovered, expected)
						if not ok then 
							print(recovered, excpected)
						end					
						assert(ok, errmsg)
					else
						local matcher = Matcher(table.copy(test.compareopts or {}))
						local ok, errmsg = matcher:match(recovered, expected)
						viewer:write(recovered) print()
						
						if not ok then print(recovered, expected) end
						
						assert(ok, errmsg)
					end
					viewer:write(recovered)
				end
				print()
			else
				print("error: "..encodeerror)
			end
		end
	end
	
	if encodeerror == nil and not test.nodynamic then
		rundynamictest(test)
	end
end
