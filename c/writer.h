#ifndef C_WRITER_FILE_H
#define C_WRITER_FILE_H
#include <stdint.h>

typedef size_t (*stream_write_t)(void* buffer, size_t element_size,  
							     size_t element_count, void* handle);
typedef int (*stream_flush_t)(void* handle); 
typedef int (*stream_close_t)(void* handle);

typedef struct
{
	stream_write_t write;
	stream_flush_t flush;
	stream_close_t close;	
} writer_api;

typedef struct 
{
	uint8_t* buffer_start;
	uint8_t* buffer_pos;
	uint8_t* buffer_end;
		
	uint8_t  bit_buffer;
	uint32_t bit_count;
		
	void* stream; 		//The stream we are writing to. 
	uint32_t position;	//Stream position
	writer_api api;
} writer_t;

writer_t writer_create(void* stream, uint8_t* buffer, size_t buffercap, writer_api api);
void write_raw(writer_t* writer, uint8_t* bytes, size_t size);
void write_int8 (writer_t* writer, int8_t value);
void write_int16(writer_t* writer, int16_t value);
void write_int32(writer_t* writer, int32_t value);
void write_int64(writer_t* writer, int64_t value);
void write_uint8 (writer_t* writer, uint8_t value);
void write_uint16(writer_t* writer, uint16_t value);
void write_uint32(writer_t* writer, uint32_t value);
void write_uint64(writer_t* writer, uint64_t value);
void write_float(writer_t* writer, float value);
void write_double(writer_t* writer, double value);
void write_varint(writer_t* writer, uint64_t value);
void write_varintzz(writer_t* writer, int64_t value);
void write_stream(writer_t* writer, uint8_t* stream, uint32_t size);
void write_bits(writer_t* writer, size_t size, uint64_t value);
void write_singed_bits(writer_t* writer, size_t size, int64_t value);
void write_align(writer_t* writer, int to);
void write_flushbits(writer_t* writer);
void write_flush(writer_t* writer);

#endif