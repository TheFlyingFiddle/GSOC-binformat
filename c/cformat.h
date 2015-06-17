#ifndef C_FORMAT_FILE_H
#define C_FORMAT_FILE_H

#define FORMAT_LIB	"format"
#define WRITER_META_TABLE "format.writer"
#define READER_META_TABLE "format.reader"

#include <lua.h>
extern __declspec(dllexport) int __cdecl luaopen_c_cformat(lua_State* L);

#endif