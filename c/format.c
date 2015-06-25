#include "reader.h"
#include "writer.h"
#include "format.h"
#include "memory_stream.h"
#include <string.h>
#include <stdlib.h>
#include <lua.h> 
#include <lauxlib.h>
#include <lualib.h>

#define DEFAULT_STREAM_CAPACITY 0xFF

static void* create_userdata(lua_State* L, size_t size, const char* meta_table)
{
	void* udata = lua_newuserdata(L, size);
	luaL_getmetatable(L, meta_table);
	lua_setmetatable(L, -2);
	return udata;
}

static int new_writer(lua_State* L)
{
	void* handle;
	writer_api api; 	
	
	int type = lua_type(L, 1);
	switch(type)
	{
		case LUA_TUSERDATA:	
			handle = luaL_testudata(L, 1, OUT_MEMORY_STREAM);
			if(handle)
			{
				api.write = (stream_write_t)&outmemory_stream_write;
				api.flush = (stream_flush_t)&outmemory_stream_flush;
				api.close = (stream_close_t)&outmemory_stream_close;
				break;
			}
			
			handle = luaL_testudata(L, 1, LUA_FILEHANDLE);
			if(handle)
			{
				luaL_Stream* stream = handle;
				handle	  = stream->f;
				api.write = (stream_write_t)&fwrite;
				api.flush = (stream_flush_t)&fflush;
				api.close = (stream_close_t)&fclose;				
				break;
			}

			luaL_error(L, "Inputstream expected");	
		case LUA_TTABLE: 
			luaL_error(L, "Cannot yet use lua table writers");
		break;
		default:
			luaL_error(L, "Inputstream expected");
			break;
	}
		
	//First get the stream data.
	char* udata	= create_userdata(L, sizeof(writer_t) + 4096, WRITER_META_TABLE);
	writer_t* writer = (writer_t*)udata;
	uint8_t* buffer = udata + sizeof(writer_t);
	*writer = writer_create(handle, buffer, 4096, api);
		
	return 1;
}

static int flush_writer(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	write_flush(writer);
	return 0;
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
		luaL_error(L, "unsigned overflow");
	
	write_uint8(writer, (uint8_t)integer);
	return 0;
}

static int writer_uint16(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
	
	if(integer < 0 || integer > UINT16_MAX)
		luaL_error(L, "unsigned overflow");
	
	write_uint16(writer, (uint16_t)integer);
	return 0;
}

static int writer_uint32(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);

	if(integer < 0 || integer > UINT32_MAX)
		luaL_error(L, "unsigned overflow");
	
	write_uint32(writer, (uint32_t)integer);
	return 0;
}

static int writer_uint64(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
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
	writer_t* writer 	 = lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);
	
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

static int writer_raw(lua_State* L)
{
	writer_t* writer = lua_touserdata(L, 1);
	size_t size;
	const char* str = lua_tolstring(L, 2, &size);
	if(str == NULL)	luaL_error(L, "string expected");
	
	write_raw(writer, (uint8_t*)str, size);
	return 0;
}

static int writer_stream(lua_State* L)
{
	writer_t* writer = lua_touserdata(L, 1);
	if(lua_type(L, 2) != LUA_TSTRING)
		luaL_error(L, "string expected");

	size_t size;
	const char* str = lua_tolstring(L, 2, &size);
	
	write_varint(writer, size);
	write_raw(writer, (uint8_t*)str, size);
	return 0;
}

static int writer_bits(lua_State* L)
{
	writer_t* writer = lua_touserdata(L, 1);
	lua_Integer size = luaL_checkinteger(L, 2);
	lua_Integer val  = luaL_checkinteger(L, 3);
	
	uint64_t max  = ((uint64_t)1 << (uint64_t)size) - 1;
	uint64_t uval = (uint64_t)val;
	if(uval > max)
		luaL_error(L, "unsigned overflow bits %d max %d val %d", size, max, uval);
		
	write_bits(writer, size, uval);
	return 0;
}

static int writer_signed_bits(lua_State* L)
{
	writer_t* writer = lua_touserdata(L, 1);
	lua_Integer size = luaL_checkinteger(L, 2);
	lua_Integer val  = luaL_checkinteger(L, 3);
	
	int64_t max = ((uint64_t)1) << (size - 1);	
	if(-max > val || val >= max)
		luaL_error(L, "integer overflow");
	
	write_singed_bits(writer, size, val);
	return 0;
}

static int writer_flushbits(lua_State* L)
{
	writer_t* writer 	= lua_touserdata(L, 1);
	write_flushbits(writer);
	return 0;
}

static int writer_align(lua_State* L)
{
	writer_t* writer	= lua_touserdata(L, 1);
	lua_Integer integer	= luaL_checkinteger(L, 2);
	write_align(writer, integer);
	return 0;
}

static int new_reader(lua_State* L)
{
	void* handle;
	reader_api api; 	
	
	int type = lua_type(L, 1);
	switch(type)
	{
		case LUA_TUSERDATA:	
			handle = luaL_testudata(L, 1, IN_MEMORY_STREAM);
			if(handle)
			{
				api.read  = (stream_write_t)&inmemory_stream_read;
				api.close = (stream_close_t)&inmemory_stream_close;
				break;
			}
			
			handle = luaL_testudata(L, 1, LUA_FILEHANDLE);
			if(handle)
			{
				luaL_Stream* stream = handle;
				handle	  = stream->f;
				api.read  = (stream_read_t)&fread;
				api.close = (stream_close_t)&fclose;
				break;
			}

			luaL_error(L, "Inputstream expected");	
		case LUA_TTABLE: 
			luaL_error(L, "Cannot yet use lua table writers");
		break;
		default:
			luaL_error(L, "Inputstream expected");
			break;
	}
		
	char*	 udata		= create_userdata(L, sizeof(reader_t) + 4096, READER_META_TABLE);
	reader_t* reader 	= (reader_t*)udata;
	uint8_t*  buffer	= (uint8_t*)(udata + sizeof(reader_t));
	*reader = reader_create(handle, api, buffer, 4096);
		
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

static int reader_raw(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	lua_Integer count 	= luaL_checkinteger(L, 2);
	
	if(reader_can_read_inplace(reader, count))
	{
		uint8_t* data = read_raw(reader, count);
		lua_pushlstring(L, (char*)data, count);		
	}
	else
	{
		printf("Count: %d", count);
		luaL_error(L, "To large count");
	}
	
	return 1;
}

static int reader_stream(lua_State* L)
{
	reader_t* reader	= lua_touserdata(L, 1);
	uint64_t  size		= read_varint(reader);
	if(reader_can_read_inplace(reader, size))
	{
		uint8_t* data = read_raw(reader, size);
		lua_pushlstring(L, (char*)data, size);
	}	
	else
	{
		printf("Size: %d", size);
		luaL_error(L, "To large count");
	}
	
	return 1;	
}

static int reader_discardbits(lua_State* L)
{
	reader_t* reader = lua_touserdata(L, 1);
	read_discardbits(reader);
	return 0;
}

static int reader_bits(lua_State* L)
{
	reader_t* reader = lua_touserdata(L, 1);
	lua_Integer size = luaL_checkinteger(L, 2);	

	uint64_t value = read_bits(reader, size);	
	
	lua_pushinteger(L, value);
	return 1;
}

static int reader_signed_bits(lua_State* L)
{
	reader_t* reader = lua_touserdata(L, 1);
	lua_Integer size = luaL_checkinteger(L, 2);	
	lua_pushinteger(L, read_signed_bits(reader, size));
	return 1;
}


static int reader_align(lua_State* L)
{
	reader_t* reader = lua_touserdata(L, 1);
	lua_Integer integer = luaL_checkinteger(L, 2);	
	read_align(reader, integer);
	return 0;
}

static int new_out_stream(lua_State* L)
{
	lua_Integer capacity = lua_tointeger(L, 1);
	if(capacity == 0)
		capacity = DEFAULT_STREAM_CAPACITY;
	
	outmemory_stream_t* stream = create_userdata(L, sizeof(outmemory_stream_t), OUT_MEMORY_STREAM);
	*stream = outmemory_stream_open(malloc, free, capacity);
	return 1;
}

static int close_outstream(lua_State* L)
{
	outmemory_stream_t* stream = luaL_checkudata(L, 1, OUT_MEMORY_STREAM);
	outmemory_stream_close(stream);
	return 0;	
}

static int flush_outstream(lua_State* L)
{
	outmemory_stream_t* stream = luaL_checkudata(L, 1, OUT_MEMORY_STREAM);
	outmemory_stream_flush(stream);
	return 0;
}

static int write_outstream(lua_State* L)
{
	outmemory_stream_t* stream = luaL_checkudata(L, 1, OUT_MEMORY_STREAM);
	size_t length;
	const char* str = lua_tolstring(L, 2, &length);

	outmemory_stream_write((uint8_t*)str, 1, length, stream);
	return 0;
}

static int getdata_outstream(lua_State* L)
{
	outmemory_stream_t* stream = luaL_checkudata(L, 1, OUT_MEMORY_STREAM);
	size_t length = stream->pos - stream->start;
		
	lua_pushlstring(L, stream->start, length);
	return 1;
}

static int new_in_stream(lua_State* L)
{
	size_t length;
	const char* str = lua_tolstring(L, 1, &length);
	if(str == NULL)	luaL_error(L, "string expected");
	
	
	char* data = create_userdata(L, sizeof(inmemory_stream_t) + length, IN_MEMORY_STREAM);

	inmemory_stream_t* stream = (inmemory_stream_t*)data;
	uint8_t* buffer = data + sizeof(inmemory_stream_t);
	memcpy(buffer, str, length);
	*stream = inmemory_stream_open(buffer, length);
	
	return 1;
}

static int read_instream(lua_State* L)
{
	inmemory_stream_t* stream = luaL_checkudata(L, 1, IN_MEMORY_STREAM);
	lua_Integer count 		  = luaL_checkinteger(L, 2);
	
	uint8_t* buffer;
	size_t length	= inmemory_stream_read_inline(stream, &buffer, (size_t)count);
	lua_pushlstring(L, buffer, length);	
	return 1; 
}

static int close_instream(lua_State* L)
{
	inmemory_stream_t* stream = luaL_checkudata(L, 1, IN_MEMORY_STREAM);
	inmemory_stream_close(stream);
	return 0;
}

static const luaL_Reg format_lib[] =
{
	{ "writer", new_writer },
	{ "reader", new_reader },
	{ "outmemorystream", new_out_stream },
	{ "inmemorystream",	 new_in_stream },
	{ NULL,		NULL}
};

static const luaL_Reg outstream_m[] = 
{
	{ "close",   close_outstream },
	{ "flush",   flush_outstream },
	{ "getdata", getdata_outstream },
	{ "write",	 write_outstream },
	{ "__gc",	 close_outstream },
	{ NULL, NULL}
};

static const luaL_Reg instream_m[] =
{
	{ "close",  close_instream },
	{ "read", 	read_instream  },
	{ "__gc", close_instream},
	{ NULL, NULL}
};

static const luaL_Reg write_m[] =
{
	{ "flush",  flush_writer		},
	{ "flushbits", writer_flushbits },
	{ "align",	  writer_align		},
	{ "raw",	   writer_raw		},
	{ "stream",	   writer_stream	},
	{ "bits",	   writer_bits		},
	{ "uint",	   writer_bits		},
	{ "int",	   writer_signed_bits },
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
	{ "discardbits", reader_discardbits },
	{ "align",		 reader_align	},
	{ "raw",	reader_raw			},
	{ "stream", reader_stream		},
	{ "bits",	   reader_bits		},
	{ "uint",	   reader_bits		},
	{ "int",	   reader_signed_bits },
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

static void register_ctype(lua_State* L, const char* id, const luaL_Reg* funcs)
{
	luaL_newmetatable(L, id);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	
	luaL_setfuncs(L, funcs, 0);
	lua_pop(L, 1);
}

__declspec(dllexport) int __cdecl luaopen_c_format(lua_State* L)
{	
	register_ctype(L, WRITER_META_TABLE, write_m);
	register_ctype(L, READER_META_TABLE, read_m);
	register_ctype(L, OUT_MEMORY_STREAM,  outstream_m);
	register_ctype(L, IN_MEMORY_STREAM,  instream_m);
		
	luaL_newlib(L, format_lib);
	return 1;
}