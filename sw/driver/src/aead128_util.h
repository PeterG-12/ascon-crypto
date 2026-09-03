#include "../include/aead128_types.h"
#include <stdint.h>
#include <unistd.h>

void bytes_to_word(uint8_t bytes[16], uint32_t array[4]);
int get_nth_word(const crypto_array_t *data, int data_len, int index,
                 uint32_t word_buffer[4]);
int check_tag(crypto_array_t *tag_a, crypto_array_t *tag_b);

uint8_t nibble_to_byte(const char c);
uint8_t nibbles_to_byte(const char c[2]);