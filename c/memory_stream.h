#ifndef C_MEMORY_STREAM_FILE_H
#define C_MEMORY_STREAM_FILE_H

#include <stdint.h>

#define IN_MEMORY_STREAM 	"format.in_memory_stream_type"
#define OUT_MEMORY_STREAM	"format.out_memory_stream_type"

typedef void* (*memalloc)(size_t size);
typedef void  (*memdealloc)(void* ptr);

typedef struct 
{
	uint8_t*  start;
	uint8_t*  pos;
	uint8_t*  end;
	memalloc  	 allocate;
	memdealloc   deallocate;
} outmemory_stream_t;

typedef struct 
{
	uint8_t*	 position;
	uint8_t*	 end;
} inmemory_stream_t;

outmemory_stream_t outmemory_stream_open(memalloc alloc, memdealloc dealloc, 
									     size_t initialCapacity);

size_t outmemory_stream_write(const uint8_t* __restrict source,
		   	 				  size_t element_size,
		  					  size_t element_count,
		   	 				  outmemory_stream_t* __restrict stream);

void outmemory_stream_flush(outmemory_stream_t* stream);
void outmemory_stream_close(outmemory_stream_t* stream);

inmemory_stream_t inmemory_stream_open(uint8_t* buffer, size_t size);

size_t inmemory_stream_read_inline(inmemory_stream_t* __restrict stream,
								   uint8_t** dest, size_t size);
								   
size_t inmemory_stream_read(uint8_t* __restrict dest, 
							size_t element_size, 
							size_t element_count, 
							inmemory_stream_t* __restrict stream);
							
void inmemory_stream_close(inmemory_stream_t* stream);

#endif