#ifndef C_READER_FILE_H
#define C_READER_FILE_H

#include <stdint.h>

typedef size_t (*stream_read_t)(void* __restrict buffer, 
								size_t element_size, 
								size_t element_count, 
								void* __restrict handle);
typedef int (*stream_close_t)(void* handle);

typedef struct
{
	stream_read_t read;
	stream_close_t close;
	
} reader_api;
				
typedef struct 
{
	void* 	 		handle;	
	uint32_t 		position; 	

	uint8_t* 		buffer_start;
	uint8_t* 		buffer_end;
	uint8_t* 		buffer_pos;
	uint32_t		buffer_capacity;
	
	uint8_t			bit_buffer;
	uint32_t		bit_count;
	
	reader_api		api;
} reader_t;


reader_t reader_create(void* handle, 
					   reader_api api, 
					   uint8_t* buffer, 
					   uint32_t buffer_capacity);

uint8_t* read_raw(reader_t* reader, size_t size);
size_t read_raw_copy(reader_t* reader, size_t size, uint8_t* into);

uint64_t read_varint(reader_t* reader);
uint64_t read_bits(reader_t* reader, size_t inSize);
int64_t  read_signed_bits(reader_t* reader, size_t size);
void read_align(reader_t* reader, size_t to);


size_t reader_can_read_inplace(reader_t* reader, size_t size);
int8_t read_int8(reader_t* reader);
int16_t read_int16(reader_t* reader);
int32_t  read_int32(reader_t* reader);
int64_t 	read_int64(reader_t* reader);
uint8_t  read_uint8(reader_t*  reader);
uint16_t read_uint16(reader_t* reader);
uint32_t read_uint32(reader_t* reader);
uint64_t read_uint64(reader_t* reader);
float read_float (reader_t* reader); 
double read_double(reader_t* reader); 
int64_t  read_varintzz(reader_t* reader); 
void read_discardbits(reader_t* reader);

#endif