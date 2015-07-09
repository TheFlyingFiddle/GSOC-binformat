local display = {}
function display.hexastream(output, stream, sprefix, start)
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
				output:write(" |".. table.concat(text) .."|")
				text = {}
			elseif column == 7 then
				output:write(" ")
			end
		end
		break
	end
end

return display