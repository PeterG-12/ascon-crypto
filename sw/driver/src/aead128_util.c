#include "aead128_util.h"
#include "aead128_types.h"
#include <stdint.h>
#include <sys/unistd.h>


void bytes_to_word(uint8_t bytes[16], uint32_t array[4]) {
    for (int i = 0; i < 4; i++) {
        array[i] =
            ((uint32_t)bytes[4 * i + 0] | (uint32_t)bytes[4 * i + 1] << 8 |
             (uint32_t)bytes[4 * i + 2] << 16 |
             (uint32_t)bytes[4 * i + 3] << 24);
    }
}

int get_nth_word(const crypto_block_t *data, int data_len, int index,
                 uint32_t word_buffer[4]) {

    uint8_t bytes[16];

    // Check the bounds to avoid dereferencing invalid memory
    if ((data + index * 16 + 15) - data > data_len) {
        return -1;
    }

    for (int i = 0; i < 16; i++) {
        //bytes[i] = *(data + index * 16 + i);
    }

    bytes_to_word(bytes, word_buffer);

    return 0;
}

void pad_block(crypto_block_t* data, unsigned int bit_len){

    if(bit_len % CRYPTO_BLOCK_BIT_SIZE == 0)
        return;

    unsigned char first_non_full_byte = bit_len / 8;
    unsigned char last_bit = bit_len % 8;

    data->b[first_non_full_byte] |= 0x01 << (last_bit);

    return;
}

int check_tag(crypto_block_t *tag_a, crypto_block_t *tag_b){
    for(int i = 0; i < CRYPTO_BLOCK_BYTE_SIZE / 4; i++){
        if(tag_a->w[i] != tag_b->w[i]){
            return -1;
        }
    }

    return 0;
}