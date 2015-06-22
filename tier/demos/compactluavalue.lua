package.path = package.path .. ";../?.lua"

local encoding  = require"encoding"
local primitive = require"encoding.primitive"
local standard  = require"encoding.standard" 

--Lua values are the standard type to be encoded with the encoder
--Because of this it's important that they are encoded as efficiently as 
--possible. 

local TrueMapper = { }
function TrueMapper:encode(encoder, value) end
function TrueMapper:decode(decoder) return true end

local FalseMapper = { }
function FalseMapper:encode(encoder, value) end
function FalseMapper:decode(decoder) return false end


local FixedString = { }
FixedString.__index = FixedString
function FixedString:encode(encoder, value) 
	print("encoding fixed string", self.size, value)
	encoder:writeraw(value)
end

function FixedString:decode(decoder)
	print("decoding fixed string", self.size)
	return decoder:readraw(self.size)
end

local function fixedstring(size)
	local fs = { }
	setmetatable(fs, FixedString)
	fs.size = size
	return fs
end

local LUAVALUE = 0x7e
local LuaValue = { }
LuaValue.tag = LUAVALUE

local FixedMap = { }
FixedMap.__index = FixedMap
function FixedMap:encode(encoder, value)
	for k, v in pairs(value) do
		LuaValue:encode(encoder, k)
		LuaValue:encode(encoder, v)
	end
end

function FixedMap:decode(decoder)
	print("decoding fixed map", self.size)
	local object = { }
	for i=1, self.size do
		local key 	= LuaValue:decode(decoder)
		local value = LuaValue:decode(decoder)
		object[key] = value
	end
	return object
end

local function fixedmap(size)
	local fm = { }
	setmetatable(fm, FixedMap)
	fm.tag = encoding.tags.FIXEDMAP
	fm.size = size
	return fm
end

local mappers = 
{
	primitive.null,			-- 0
	TrueMapper,				-- 1
	FalseMapper,			-- 2
	primitive.varint,		-- 3
	primitive.fpdouble, 	-- 4
	primitive.string,		-- 5
	standard.object(standard.map(LuaValue, LuaValue)), -- 6
	standard.object(standard.list(LuaValue)), -- 7
	fixedstring(0),   -- 8
	fixedstring(1),	  -- 9
	fixedstring(2),	  -- 10			
	fixedstring(3),	  -- 11
	fixedstring(4),	  -- 12
	fixedstring(5),	  -- 13
	fixedstring(6),	  -- 14
	fixedstring(7),   -- 15
	fixedstring(8),   -- 16
	fixedstring(9),   -- 17
	fixedstring(10),  -- 18
	fixedstring(11),  -- 19
	fixedstring(12),  -- 20
	fixedstring(13),  -- 21
	fixedstring(14),  -- 22
	fixedstring(15),  -- 23
	fixedstring(16),  -- 24
	standard.object(fixedmap(0)),	--25
	standard.object(fixedmap(1)),	--26
	standard.object(fixedmap(2)),	--27
	standard.object(fixedmap(3)),	--28
	standard.object(fixedmap(4)),	--29
	standard.object(fixedmap(5)),	--30
	standard.object(fixedmap(6)),	--31
	standard.object(fixedmap(7)),	--32
	standard.object(fixedmap(8)),	--33
	standard.object(fixedmap(9)),	--34
	standard.object(fixedmap(10)),	--35
	standard.object(fixedmap(11)),	--36
	standard.object(fixedmap(12)),	--37
	standard.object(fixedmap(13)),	--38
	standard.object(fixedmap(14)),	--39
	standard.object(fixedmap(15)),	--40
	standard.object(fixedmap(16)),	--41
}

function LuaValue:encode(encoder, value)
	local vt = type(value)
	local index
	if vt == "nil" then
		index = 0
	elseif vt == "boolean" then
		if value then index = 1	else index = 2 end
	elseif vt == "number" then
		local tmp = value // 1
		if tmp == value then index = 3 else index = 4 end
	elseif vt == "string" then
		local len = string.len(value)
		if len > 16 then index = 5 else index = 8 + len end
	elseif vt == "table" then
		local count = 0;
		for _ in pairs(value) do
			count = count + 1
		end
		if count > 16 then index = 6 else index = 25 + count end
	else 
		error("Cannot encode lua value of type " .. vt .. ".")
	end 
	
	local mapper = mappers[index + 1]
	encoder:writebyte(index)	
	mapper:encode(encoder, value)
end

function LuaValue:decode(decoder)
	local byte = decoder:readbyte()
	byte = byte + 1
	local mapper = mappers[byte]
	return mapper:decode(decoder)
end

local function luavalue()
	return LuaValue
end

--Some comparissons. 
local mapping = luaval.luavalue();
local data = 
{
	flag = true,
	number = 123.45,
	text   = "Lua 5.1",
	list   =
	{
		[1] = "A",
		[2] = "B",
		[3] = "C"
	}
}

local optimal = standard.tuple(
{
	{ key = "flag", 	mapping = primitive.boolean },
	{ key = "number",	mapping = primitive.fpdouble },
	{ key = "text",     mapping = primitive.string},
	{ key = "list",     mapping = standard.list(primitive.string)},
})