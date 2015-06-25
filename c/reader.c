#include "reader.h"
#include <string.h>

reader_t reader_create(void* handle, reader_api api, 
					   uint8_t* buffer, uint32_t buffer_capacity)
{
	reader_t reader;
	reader.api				= api;
	reader.handle			= handle;
	reader.position 		= 0;
	reader.bit_buffer		= 0;
	reader.bit_count		= 0;
	
	reader.buffer_start = buffer;
	reader.buffer_end	= buffer;
	reader.buffer_pos	= buffer;
	reader.buffer_capacity = buffer_capacity;
		
	return reader;
}

#include <stdio.h>

uint8_t* read_raw(reader_t* reader, size_t size)
{
	uint32_t left = reader->buffer_end - reader->buffer_pos;
	if(size > left)
	{	
		memmove(reader->buffer_start, reader->buffer_pos, left);	
		
		size_t to_read = reader->buffer_capacity - left;
		size_t was_read = reader->api.read(reader->buffer_start + left, 1, to_read, reader->handle);
			
		reader->buffer_pos = reader->buffer_start;
		reader->buffer_end = reader->buffer_start + was_read + left;	
	}	
	
	uint8_t* data = reader->buffer_pos;
	reader->buffer_pos	+= size;
	reader->position += size;
	return data;
}

size_t read_raw_copy(reader_t* reader, size_t size, uint8_t* into)
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
		reader->api.read(into, 1, to_take, reader->handle);
		reader->position += size;
	}
	
	return size;
}

uint64_t read_varint(reader_t* reader) 
{
	uint64_t value = 0;
	int count = 0;
	while(1)
	{
		uint64_t bite = read_uint8(reader);
		value = value | ((bite & 0x7F) << (count));
		if (bite < 0x80) break;
		count += 7;	
		
		if(count == 70)
		{
			//reader->error = CORRUPT_STREAM;
			return 0;
		}
	}
	
	return value;				
}

uint64_t read_bits(reader_t* reader, size_t inSize)
{
	uint64_t size  = inSize;
	uint64_t bits  = reader->bit_buffer;
	uint32_t count = reader->bit_count;
	uint64_t ready = 0;
	
	uint64_t value = 0;
	
	while(count < size - ready)
	{
		value = value | (bits << ready);
		ready = ready + count;
		bits  = read_uint8(reader);
		count = 8;
	}
		
	size = size - ready;
	reader->bit_count  = count - size;
	reader->bit_buffer = bits >> size;
	
	return value | (bits & ~((uint64_t)-1 << size)) << ready;;
}

int64_t read_signed_bits(reader_t* reader, size_t size)
{
	uint64_t value = read_bits(reader, size);
	uint64_t sign  = (value >> (uint64_t)(size - 1)) & 0x01;
	if(sign)
	{
		uint64_t max = (uint64_t)1 << (uint64_t)size;
		return value - max;
	}
	
	return value;
}

void read_align(reader_t* reader, size_t to)		 
{ 
	uint32_t pos	  = reader->position;
	uint32_t to_align = ((pos + (to - 1)) & ~(to - 1)) - pos;
	
	int i;
	for(i = 0; i < to_align; i++)
		read_uint8(reader);
}

size_t reader_can_read_inplace(reader_t* reader, size_t size)
{
	return reader->buffer_capacity >= size;
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
	int32_t pos = *(int32_t*)read_raw(reader, 4);	
	return pos;
}

int64_t read_int64(reader_t* reader)
{ 
	return *(int64_t*)read_raw(reader, 8);
}

uint8_t  read_uint8(reader_t*  reader) 
{ 
	uint8_t val = *(uint8_t*)read_raw(reader, 1);	
	return val;
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

float read_float (reader_t* reader) 
{ 
	typedef union { uint32_t int_; float float_; } float_converter_t;
	float_converter_t conv;
	conv.int_ = read_uint32(reader);
	return conv.float_;
}

double read_double(reader_t* reader) 
{ 
	typedef union { uint64_t int_; double float_; } double_converter_t;
	double_converter_t conv;
	conv.int_ = read_uint64(reader);
	return conv.float_;	
}

int64_t  read_varintzz(reader_t* reader) 
{ 
	uint64_t val  = read_varint(reader);
	return (val >> 1) ^ (-(val & 1));;
}

void read_discardbits(reader_t* reader)
{
	reader->bit_count  = 0;
	reader->bit_buffer = 0;
}