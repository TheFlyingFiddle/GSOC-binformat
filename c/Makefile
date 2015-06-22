LUA_DIR     = C:/LUA
LUA_INCLUDE = ${LUA_DIR}/include
LUA_DLL_DIR	= ${LUA_DIR}

C_FILES		= writer.c
C_FILES	   += reader.c
C_FILES	   += format.c
C_FILES	   += memory_stream.c

H_FILES	 	= writer.h
H_FILES	   += reader.h
H_FILES	   += format.h
H_FILES	   += memory_stream.h

cformat.dll : ${C_FILES} ${H_FILES}
	gcc -shared  -O3 -I${LUA_INCLUDE} ${C_FILES} -o format.dll -L${LUA_DLL_DIR} -llua53
	
clean:
	rm cformat.dll