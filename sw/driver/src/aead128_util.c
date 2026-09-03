#include "aead128_util.h"
#include "aead128_helper.h"
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

int get_nth_word(const crypto_array_t *data, int data_len, int index,
                 uint32_t word_buffer[4]) {

    uint8_t bytes[16] = {0};

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

int check_tag(crypto_array_t *tag_a, crypto_array_t *tag_b){
    for(int i = 0; i < CRYPTO_BLOCK_BYTE_SIZE / 4; i++){
        if(tag_a->blocks->w[i] != tag_b->blocks->w[i]){
            return -1;
        }
    }

    return 0;
}

uint8_t nibble_to_byte(const char c){
    if(c >= '0' && c <= '9'){
        return (uint8_t)(c - '0');
    }

    if(c >= 'a' && c <= 'f'){
        return (10 + (uint8_t)(c - '0'));
    }

    return 0;
}

uint8_t nibbles_to_byte(const char c[2]){
    return 16 * nibble_to_byte(c[0]) + nibble_to_byte(c[1]);    
}