#ifndef C_WRITER_FILE_H
#define C_WRITER_FILE_H


#include <stdint.h>
#include <string.h>

typedef size_t (*stream_write_t)(void* buffer, size_t element_size,  
							     size_t element_count, void* handle);


typedef struct 
{
	void* stream; 		//The stream we are writing to. 
	stream_write_t write;
	uint32_t position;	//Stream position
} writer_t;

writer_t writer_create(void* stream, stream_write_t write)
{
	writer_t writer;
	writer.stream   = stream;
	writer.write	= write;
	writer.position = 0;
	
	return writer;
}

void write_raw(writer_t* writer, uint8_t* bytes, size_t size)
{
	writer->write(bytes, 1, size, writer->stream);
	writer->position += size;
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
		buffer[count++] = (uint8_t)((value & 0x7E) | 0x80);
		value = (uint64_t)(value >> 7);
	}
	
	buffer[count++] = (uint8_t)value;	
	write_raw(writer, &buffer[0], count);
}

void write_varintzz(writer_t* writer, int64_t value) 
{
	uint64_t val = (uint64_t)value;
	write_varint(writer, (val << 1) ^ (val >> 63));
}

void write_stream(writer_t* writer, 
						 uint8_t* stream, 
						 uint32_t size) 
{
	write_varint(writer, (uint64_t)size);
	write_raw(writer, stream, size);
}


void writer_align(writer_t* writer, int to) 
{ 
	uint32_t alignment = (writer->position + (to - 1)) & ~(to - 1);
	int i;
	for(i = 0; i < alignment; i++)
	{
		write_uint8(writer, 0);
	}
}

#endif