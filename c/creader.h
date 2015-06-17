#ifndef C_READER_FILE_H
#define C_READER_FILE_H


#include <stdint.h>
#include <string.h>
#include <stdio.h>

typedef size_t (*stream_read_t)(void* __restrict buffer, size_t element_size, size_t element_count, 
								void* __restrict handle);

typedef enum  
{
	NO_ERROR = 0,
	STREAM_READ_FAILED = 1,
	CORRUPT_STREAM = 2,
	TO_LARGE_INPLACE_READ = 3
} error_t;

typedef struct 
{
	void* 			stream_handle;	
	stream_read_t	read;	 
	
	uint32_t position; 	

	//We have a buffered stream. 
	//We don't have to have a buffered stream
	//But I feel that this is the best option.
	uint8_t* buffer_start;
	uint8_t* buffer_end;
	uint8_t* buffer_pos;

	uint32_t buffer_capacity;
	error_t	 error;	
} reader_t;

reader_t reader_create(void* stream, stream_read_t read, uint8_t* buffer, uint32_t buffer_capacity)
{
	reader_t reader;
	reader.stream_handle  	= stream;
	reader.read	   			= read;
	reader.position 		= 0;
	
	reader.buffer_start = buffer;
	reader.buffer_end	= buffer;
	reader.buffer_pos	= buffer;
	reader.buffer_capacity = buffer_capacity;
	reader.error = NO_ERROR;
		
	return reader;
}


size_t reader_can_read_inplace(reader_t* reader, size_t size)
{
	return reader->buffer_capacity <= size;
}

static uint8_t* read_raw(reader_t* reader, size_t size)
{
	uint8_t* data;
	uint32_t left = reader->buffer_end - reader->buffer_pos;
	if(size <= left)
	{
		data = reader->buffer_pos;
		reader->buffer_pos += size;
	}
	else
	{
		if(size > reader->buffer_capacity)
		{ 
			reader->error = TO_LARGE_INPLACE_READ;
			return NULL;
		}
		
		memmove(reader->buffer_start, reader->buffer_pos, left);		
		
		size_t to_read = reader->buffer_capacity - left;
		size_t was_read = reader->read(reader->buffer_start + left, 1, to_read, reader->stream_handle);
				
		data = reader->buffer_start;
		reader->buffer_pos = reader->buffer_start + size;
		reader->buffer_end = reader->buffer_start + was_read + left;		
	}	
	
	reader->position += size;
	return data;
}

static size_t read_raw_copy(reader_t* reader, size_t size, uint8_t* into)
{
	if(reader_can_read_inplace(reader, size))
	{
		uint8_t* data = read_raw(reader, size);
		memcpy(into, data, size);
	}
	else
	{
		size_t left = reader->buffer_end - reader->buffer_pos;
		memcpy(into, reader->buffer_pos, left);
		into += left;
		
		reader->buffer_pos = reader->buffer_start;
		reader->buffer_end = reader->buffer_start;
				
		size_t to_take = size - left;
		reader->read(into, 1, to_take, reader->stream_handle);
		reader->position += size;
	}
	
	return size;
}

int8_t read_int8(reader_t* reader)  
{
	return *(int8_t*)read_raw(reader, 1);
}

int16_t read_int16(reader_t* reader) 
{ 
	return *(int16_t*)read_raw(reader, 2);	
}

int32_t  read_int32(reader_t* reader) 
{ 
	return *(int32_t*)read_raw(reader, 4);	
}

int64_t 	read_int64(reader_t* reader)
{ 
	return *(int64_t*)read_raw(reader, 8);
}

uint8_t  read_uint8(reader_t*  reader) 
{ 
	return *(uint8_t*)read_raw(reader, 1);	
}

uint16_t read_uint16(reader_t* reader)
{ 
	return *(uint16_t*)read_raw(reader, 2);	
}

uint32_t read_uint32(reader_t* reader) 
{ 
	return *(uint32_t*)read_raw(reader, 4);	
}

uint64_t read_uint64(reader_t* reader) 
{ 
	return *(uint64_t*)read_raw(reader, 8);
}

typedef union { uint32_t int_; float float_; } float_converter_t;
float	read_float (reader_t* reader) 
{ 
	float_converter_t conv;
	conv.int_ = read_uint32(reader);
	return conv.float_;
}


typedef union { uint64_t int_; double float_; } double_converter_t;
double	read_double(reader_t* reader) 
{ 
	double_converter_t conv;
	conv.int_ = read_uint64(reader);
	return conv.float_;	
}

uint64_t read_varint(reader_t* reader) 
{
	uint64_t value = 0;
	int count = 0;
	while(1)
	{
		uint8_t bite = read_uint8(reader);
		value = value | ((bite & 0x7F) << (count));
		if (bite < 0x80) break;
		count += 7;	
		
		if(count == 70)
		{
			reader->error = CORRUPT_STREAM;
			return 0;
		}
	}
	return value;				
}

int64_t  read_varintzz(reader_t* reader) 
{ 
	uint64_t val = read_varint(reader);
	return (val >> 1) ^ (-(val & 1));
}

void reader_align(reader_t* reader, size_t to)		 
{ 
	uint32_t alignment = (reader->position + (to - 1)) & ~(to - 1);
	int i;
	for(i = 0; i < alignment; i++)
	{
		read_uint8(reader);
	}
}

#endif