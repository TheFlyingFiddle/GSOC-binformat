#include "creader.h"
#include "cwriter.h"
#include "cformat.h"
#include <stdio.h>
#include <lua.h> 
#include <lauxlib.h>
#include <lualib.h>

static int new_file_writer(lua_State* L)
{
	FILE* f = fopen("c_file.dat", "wb");
	
	//First get the stream data.
	writer_t* writer	= lua_newuserdata(L, sizeof(writer_t));
	*writer = writer_create((void*)f, (stream_write_t)&fwrite);

	printf("New file writer.\n");
	luaL_getmetatable(L, WRITER_META_TABLE);
	lua_setmetatable(L, -2);
	return 1;
}

static int close_file_writer(lua_State* L)
{
	printf("Closing file writer.\n");

	writer_t* writer = lua_touserdata(L, 1);
	fflush(writer->stream);
	fclose(writer->stream);
}

static int writer_int8(lua_State* L)
{
	writer_t* writer	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
	
	if(integer < INT8_MIN|| integer > INT8_MAX)
		luaL_error(L, "integer overflow");
	
	write_int8(writer, (int8_t)integer);
	return 0;
}

static int writer_int16(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
	
	if(integer < INT16_MIN || integer > INT16_MAX)
		luaL_error(L, "integer overflow");
	
	write_int16(writer, (int16_t)integer);
	return 0;
}

static int writer_int32(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);

	if(integer < INT32_MIN || integer > INT32_MAX)
		luaL_error(L, "integer overflow");
	
	write_int32(writer, (int32_t)integer);
	return 0;
}

static int writer_int64(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);

	if(integer < INT64_MIN || integer > INT64_MAX)
		luaL_error(L, "integer overflow");
	
	write_int64(writer, (int64_t)integer);
	return 0;
}

static int writer_uint8(lua_State* L)
{
	writer_t* writer	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
	
	if(integer < 0 || integer > UINT8_MAX)
		luaL_error(L, "integer overflow");
	
	write_uint8(writer, (uint8_t)integer);
	return 0;
}

static int writer_uint16(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
	
	if(integer < 0 || integer > UINT16_MAX)
		luaL_error(L, "integer overflow");
	
	write_uint16(writer, (uint16_t)integer);
	return 0;
}

static int writer_uint32(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);

	if(integer < 0 || integer > UINT32_MAX)
		luaL_error(L, "integer overflow");
	
	write_uint32(writer, (uint32_t)integer);
	return 0;
}

static int writer_uint64(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Unsigned integer = (lua_Unsigned)luaL_checkinteger(L, 2);
	write_uint64(writer, (uint64_t)integer);
	return 0;
}

static int writer_float(lua_State* L)
{
	writer_t* writer = lua_touserdata(L, 1);
	write_float(writer, luaL_checknumber(L, 2));
	return 0;
}

static int writer_double(lua_State* L)
{
	writer_t* writer = lua_touserdata(L, 1);
	write_double(writer, luaL_checknumber(L, 2));
	return 0;
}

static int writer_varint(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Unsigned integer = (lua_Unsigned)luaL_checkinteger(L, 2);
	write_varint(writer, (uint64_t)integer);
	return 0;
}

static int writer_varintzz(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
	write_varintzz(writer, (int64_t)integer);
	return 0;
}

static int new_file_reader(lua_State* L)
{
	FILE* f = fopen("c_file.dat", "rb");
	
	char* 	  data		= lua_newuserdata(L, sizeof(reader_t) + 4096);
	reader_t* reader 	= (reader_t*)data;
	uint8_t*  buffer	= (uint8_t*)(data + sizeof(reader_t));
	*reader = reader_create(f, (stream_read_t)&fread, buffer, 4096);

	luaL_getmetatable(L, READER_META_TABLE);
	lua_setmetatable(L, -2);
	return 1;
}

static int reader_int8(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_int8(reader));
	return 1;
}

static int reader_int16(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_int16(reader));
	return 1;
}

static int reader_int32(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_int32(reader));
	return 1;
}

static int reader_int64(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_int64(reader));
	return 1;
}


static int reader_uint8(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_uint8(reader));
	return 1;
}

static int reader_uint16(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_uint16(reader));
	return 1;
}

static int reader_uint32(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_uint32(reader));
	return 1;
}

static int reader_uint64(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, (lua_Integer)read_uint64(reader));
	return 1;
}

static int reader_float(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushnumber(L, read_float(reader));
	return 1;
}

static int reader_double(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushnumber(L, read_double(reader));
	return 1;
}

static int reader_varint(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, read_varint(reader));
	return 1;
}

static int reader_varintzz(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_pushinteger(L, read_varintzz(reader));
	return 1;
}


static const luaL_Reg format_lib[] =
{
	{ "writer", new_file_writer },
	{ "reader", new_file_reader },
	{ NULL,		NULL}
};

static const luaL_Reg write_m[] =
{
	{ "close", 	close_file_writer 	},
	{ "int8",	writer_int8		  	},
	{ "int16",	writer_int16	  	},
	{ "int32",	writer_int32		},
	{ "int64",	writer_int64		},
	{ "uint8",	writer_uint8		},
	{ "uint16",	writer_uint16	  	},
	{ "uint32",	writer_uint32		},
	{ "uint64",	writer_uint64		},
	{ "float" , writer_float		},
	{ "double", writer_double		},
	{ "varint", writer_varint		},
	{ "varintzz", writer_varintzz	},
	{ NULL,		NULL}
};

static const luaL_Reg read_m[ ] = 
{
	{ "new", 	new_file_reader },
	{ "int8",	reader_int8		  	},
	{ "int16",	reader_int16	  	},
	{ "int32",	reader_int32		},
	{ "int64",	reader_int64		},
	{ "uint8",	reader_uint8		},
	{ "uint16",	reader_uint16	  	},
	{ "uint32",	reader_uint32		},
	{ "uint64",	reader_uint64		},
	{ "float" , reader_float		},
	{ "double", reader_double		},
	{ "varint", reader_varint		},
	{ "varintzz", reader_varintzz	},
	{ NULL,		NULL }
};

__declspec(dllexport) int __cdecl luaopen_c_cformat(lua_State* L)
{	
	luaL_newmetatable(L, WRITER_META_TABLE);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	
	luaL_setfuncs(L, write_m, 0);
	lua_pop(L, 1);
	
	luaL_newmetatable(L, READER_META_TABLE);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	
	luaL_setfuncs(L, read_m, 0);
	lua_pop(L, 1);
		
	luaL_newlib(L, format_lib);
	return 1;
}