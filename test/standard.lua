runtest{
	mapping = standard.list(primitive.boolean),
	{
		{ actual = {} },
		{ actual = { false } },
		{ actual = { true } },
		{ actual = { true, false, false, true, false } },
		{ actual = { false, true, true, false, true } },
	},
}

runtest{ noregression = true,
	mapping = standard.map(primitive.stream, primitive.varint),
	{
		{ actual = {}, },
		{ actual = { ["John Doe"]=25, ["Jane Doe"]=25, ["Baby Doe"]=1 } },
		{ actual = { ["Donald Duck"]=312, ["Mickey Mouse"]=32, ["Goofy"]=12 } },
	},
}

runtest{
	mapping = standard.tuple{
		{ mapping = primitive.stream },
		{ mapping = primitive.varint },
		{ mapping = primitive.boolean },
	},
	{
		{ actual = { "Picard", 20, true } },
		{ actual = { "Worf", 15, false } },
		{ actual = { "Riker", 18, false } },
		{ actual = { "Data", 13, false } },
	},
}

runtest{ noregression = true,
	mapping = standard.tuple{
		{ key = "name", mapping = primitive.stream },
		{ key = "rank", mapping = primitive.varint },
		{ key = "captain", mapping = primitive.boolean },
	},
	{
		{ actual = { name="Picard", rank=20, captain=true } },
		{ actual = { name="Worf", rank=15, captain=false } },
		{ actual = { name="Riker", rank=18, captain=false } },
		{ actual = { name="Data", rank=13, captain=false } },
	},
}

runtest{
	mapping = standard.array(standard.union{
		{ type = "string", mapping = primitive.stream },
		{ type = "nil", mapping = primitive.null }
	}, 5),
	{
		{ actual = { "A", nil, "B", nil, "C" } },
		{ actual = { "D", "E", nil, nil, "F" } },
	},
}
