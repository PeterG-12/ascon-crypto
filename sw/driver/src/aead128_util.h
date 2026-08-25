#include <unistd.h>


void bytes_to_word(uint8_t bytes[16], uint32_t array[4]);
int get_nth_word(const uint8_t *data, int data_len, int index,
                 uint32_t word_buffer[4]);