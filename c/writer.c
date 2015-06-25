#include "writer.h"
#include <string.h>

writer_t writer_create(void* stream, uint8_t* buffer, size_t buffercap, writer_api api)
{
	writer_t writer;
	writer.stream   = stream;
	writer.api = api;	
	writer.buffer_start = buffer;
	writer.buffer_pos	= buffer;
	writer.buffer_end	= buffer + buffercap;
	
	writer.position = 0;
	return writer;
}

#include <stdio.h>

static void writer_flush_buffered(writer_t* writer)
{
	size_t length = writer->buffer_pos - writer->buffer_start;
	
	writer->api.write(writer->buffer_start, 1, length, writer->stream);
	writer->buffer_pos = writer->buffer_start;
	writer->position += length;
}

void write_raw(writer_t* writer, uint8_t* bytes, size_t size)
{
	if(writer->buffer_pos + size <= writer->buffer_end)
	{
		memcpy(writer->buffer_pos, bytes, size);
		writer->buffer_pos += size;
	}
	else
	{
		writer_flush_buffered(writer);				
		if(size > writer->buffer_end - writer->buffer_start)
		{
			writer->api.write(bytes, 1, size, writer->stream);
			writer->position += size;
		}
		else
		{
			memcpy(writer->buffer_pos, bytes, size);
			writer->buffer_pos += size;
		}
	}
}

void write_int8 (writer_t* writer, int8_t value)  
{		
	write_raw(writer, (uint8_t*)&value, 1);
}

void write_int16(writer_t* writer, int16_t value)
{ 
	uint8_t* ptr = (uint8_t*)&value;
	write_raw(writer, ptr, 2);
}

void write_int32(writer_t* writer, int32_t value) 
{
	uint8_t* ptr = (uint8_t*)&value;
	write_raw(writer, ptr, 4);	
}

void write_int64(writer_t* writer, int64_t value) 
{
	uint8_t* ptr = (uint8_t*)&value;
	write_raw(writer, ptr, 8);	
}

void write_uint8 (writer_t* writer, uint8_t value)  
{
	write_raw(writer, &value, 1);
}

void write_uint16(writer_t* writer, uint16_t value) 
{ 
	uint8_t* ptr = (uint8_t*)&value;
	write_raw(writer, ptr, 2);
}

void write_uint32(writer_t* writer, uint32_t value) 
{ 
	uint8_t* ptr = (uint8_t*)&value;
	write_raw(writer, ptr, 4);	
}

void write_uint64(writer_t* writer, uint64_t value) 
{ 
	uint8_t* ptr = (uint8_t*)&value;
	write_raw(writer, ptr, 8);	
}

void write_float(writer_t* writer, float value) 		
{ 
	typedef union { uint32_t int_; float float_; } converter;
	converter conv;
	conv.float_ = value;
	write_uint32(writer, conv.int_);		
}

void write_double(writer_t* writer, double value) 	
{ 
	typedef union { uint64_t int_; double float_; } converter;
	converter conv;
	conv.float_ = value;
	write_uint64(writer, conv.int_);		
}

void write_varint(writer_t* writer, uint64_t value) 	
{	
	uint8_t buffer[10];
	int 		count = 0;
	while(value >= 0x80)
	{
		buffer[count++] = (uint8_t)(value | 0x80);
		value = (uint64_t)(value >> 7);
	}
	
	buffer[count++] = (uint8_t)value;	
	write_raw(writer, &buffer[0], count);
}

void write_varintzz(writer_t* writer, int64_t value) 
{
	uint64_t nval = (value << 1) ^ (value >> 63);	
	write_varint(writer, nval);
}

void write_stream(writer_t* writer, 
						 uint8_t* stream, 
						 uint32_t size) 
{
	write_varint(writer, (uint64_t)size);
	write_raw(writer, stream, size);
}

void write_bits(writer_t* writer, size_t size, uint64_t value)
{
	uint32_t  count = writer->bit_count;
	uint64_t  bits  = writer->bit_buffer;
	bits		    = bits | (value << count);
	
	count = count + size;	
	while (count >= 8)
	{
		count = count - 8;
		value = value >> (size - count);
		size  = count;
		write_uint8(writer, bits & 0xFF);	
		bits  = value;
	}
	
	writer->bit_count = count;
	writer->bit_buffer = bits & ~(-1 << count);
}

void write_singed_bits(writer_t* writer, size_t size, int64_t value)
{
	int64_t half = (int64_t)1 << (int64_t)(size - 1);
	if(value < 0) 
	{
		int64_t offset = ((int64_t)1 << size);
		int64_t nval   = offset + value;
		write_bits(writer, size, nval);
	}
	else
	{
		write_bits(writer, size, value);	
	}
}

void write_align(writer_t* writer, int to) 
{ 
	int i;
	uint32_t pos	   = writer->position + (writer->buffer_pos - writer->buffer_start);
	uint32_t to_align  = ((pos + (to - 1)) & ~(to - 1)) - pos;

	for(i = 0; i < to_align; i++)
	{
		write_uint8(writer, 0);
	}
}

void write_flushbits(writer_t* writer)
{
	if(writer->bit_count > 0)
	{
		write_uint8(writer, writer->bit_buffer & 0xFF);
		writer->bit_count  = 0;
		writer->bit_buffer = 0;
	}
}


void write_flush(writer_t* writer)
{
	write_flushbits(writer);	
	writer_flush_buffered(writer);
	writer->api.flush(writer->stream);
}