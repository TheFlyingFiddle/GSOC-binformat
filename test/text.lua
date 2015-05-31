-- single value stream values
local CharCases = {
	{ actual = "a" },
	{ actual = "Z" },
	{ actual = "0" },
	{ actual = "1" },
	{ actual = "\000" },
	{ actual = "\001" },
	{ actual = "\b" },
	{ actual = "\f" },
	{ actual = "\n" },
	{ actual = "\t" },
	{ actual = "\v" },
}
-- double value stream values
local WideCharCases = {
	{ actual = "\255a" },
	{ actual = "\255Z" },
	{ actual = "\2550" },
	{ actual = "\2551" },
	{ actual = "\255\000" },
	{ actual = "\255\001" },
	{ actual = "\255\b" },
	{ actual = "\255\f" },
	{ actual = "\255\n" },
	{ actual = "\255\t" },
	{ actual = "\255\v" },
}
-- byte stream values
local allchars = {}
for i = 0, 255 do
	allchars[#allchars+1] = string.char(i)
end
local StreamCases = {
	{ actual = "0123456789" },
	{ actual = "abcdefghijklmnopqrstuvxywz" },
	{ actual = "ABCDEFGHIJKLMNOPQRSTUVXYWZ" },
	{ actual = "'\"!@#$%¨&*()-_=+´`[{]}~^,<.>;:/?\\|" },
	{ actual = "\b\f\n\t\v\0" },
	{ actual = table.concat(allchars) },
	{ actual = [[
Lorem ipsum dolor
sit amet, consectetur
Ut lobortis
placerat mi vel tempor
Il et felis eu sapien interdum
sollicitudin sit anet quis mi. Proin
iaculis vehicula ultrices]] },
}
-- non-textual values
local NonTextualCases = {
	{ actual = nil },
	{ actual = false },
	{ actual = true },
	{ actual = {} },
	{ actual = print },
	{ actual = function() end },
	{ actual = coroutine.running() },
	{ actual = io.stdout },
}

-- single byte characters
runtest{ mapping = primitive.char, CharCases }
--runtest{ mapping = primitive.char, defaultexpected = "\255", WideCharCases }
runtest{ mapping = primitive.char, encodeerror = "string expected", NonTextualCases }

-- double byte characters
runtest{ mapping = primitive.wchar, WideCharCases }
runtest{ mapping = primitive.wchar, encodeerror = "invalid wide character", CharCases }
runtest{ mapping = primitive.wchar, encodeerror = "string expected", NonTextualCases }

-- single byte string
runtest{ mapping = primitive.string,
	CharCases,
	WideCharCases,
	StreamCases,
}
runtest{ mapping = primitive.string, encodeerror = "string expected", NonTextualCases }
-- double byte string
runtest{ mapping = primitive.wstring,
	WideCharCases,
}

runtest{ mapping = primitive.wstring, encodeerror = "invalid wide string",
	CharCases,
}

runtest{ mapping = primitive.wstring, encodeerror = "string expected", NonTextualCases }
-- byte stream
runtest{ mapping = primitive.stream,
	CharCases,
	WideCharCases,
	StreamCases,
}
runtest{ mapping = primitive.stream, encodeerror = "string expected", NonTextualCases }
