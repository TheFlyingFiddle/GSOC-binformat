#include "memory_stream.h"

#include <stdint.h>
#include <string.h>

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

outmemory_stream_t outmemory_stream_open(memalloc alloc, memdealloc dealloc, size_t initialCapacity)
{
	outmemory_stream_t stream;
	stream.start		= alloc(initialCapacity);
	stream.pos 	    	= stream.start;
	stream.end	    	= stream.start + initialCapacity;
	stream.allocate   	= alloc;
	stream.deallocate 	= dealloc;
	return stream;
}

size_t outmemory_stream_write(const uint8_t* __restrict source,
		   	 				  size_t element_size,
		  					  size_t element_count,
		   	 				  outmemory_stream_t* __restrict stream)
{
	size_t size = element_size * element_count;
	if(stream->pos + size > stream->end)
	{
		size_t length		= stream->pos - stream->start;
		size_t capacity		= stream->end - stream->start;
		size_t new_capacity = MAX(capacity * 2, length + size);
					
		//Need to reallocate.
		uint8_t* new_mem = stream->allocate(new_capacity);
		memcpy(new_mem, stream->start, length);
		stream->deallocate(stream->start);
		
		stream->start = new_mem;
		stream->pos	  = stream->start + length;
		stream->end	  = stream->start + new_capacity;
	}
	
	memcpy(stream->pos, source, size);
	stream->pos += size;	
		
	return size;
}

void outmemory_stream_flush(outmemory_stream_t* stream)
{
	//There is not really anything to do here.
}

void outmemory_stream_close(outmemory_stream_t* stream)
{
	if(stream->deallocate != NULL)
	{
		stream->deallocate(stream->start);
		memset(stream, 0, sizeof(outmemory_stream_t));
	}
}


inmemory_stream_t inmemory_stream_open(uint8_t* buffer, size_t size)
{
	inmemory_stream_t stream;
	stream.position = buffer;
	stream.end		= buffer + size;
	return stream;
}

size_t inmemory_stream_read_inline(inmemory_stream_t* __restrict stream,
								   uint8_t** dest, 
								   size_t size)
{
	size_t actual = MIN(stream->end - stream->position, size);
	*dest = stream->position;
	stream->position += actual;
	return actual;	
}

size_t inmemory_stream_read(uint8_t* __restrict dest, 
							size_t element_size, 
							size_t element_count, 
							inmemory_stream_t* __restrict stream)
{
	size_t size   = element_size * element_count;
	size_t actual = MIN(stream->end - stream->position, size);
	
	memcpy(dest, stream->position, actual);
	stream->position += actual;
		
	return actual;
} 

void inmemory_stream_close(inmemory_stream_t* stream)
{
	stream->position = NULL;
	stream->end		 = NULL;
}
