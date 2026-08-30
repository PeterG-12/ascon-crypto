#include "../include/aead128_types.h"
#include <unistd.h>

void bytes_to_word(uint8_t bytes[16], uint32_t array[4]);
int get_nth_word(const crypto_block_t *data, int data_len, int index,
                 uint32_t word_buffer[4]);
void pad_block(crypto_block_t *data, unsigned int bit_len);
int check_tag(crypto_block_t *tag_a, crypto_block_t *tag_b);