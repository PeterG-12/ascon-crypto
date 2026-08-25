#include "aead128_util.h"
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

int get_nth_word(const uint8_t *data, int data_len, int index,
                 uint32_t word_buffer[4]) {

    uint8_t bytes[16];

    // Check the bounds to avoid dereferencing invalid memory
    if ((data + index * 16 + 15) - data > data_len) {
        return -1;
    }

    for (int i = 0; i < 16; i++) {
        bytes[i] = *(data + index * 16 + i);
    }

    bytes_to_word(bytes, word_buffer);

    return 0;
}

void pad(uint8_t* data, int len, int r_bytes){
    int pad_len = r_bytes - (len % r_bytes);

    if(pad_len == 0)
        return;

    data[len] = 1; 

    for(int i = len + 1; i < pad_len + len; i++){
        data[i] = 0;
    }

    return;
}

uint8_t* parse(uint8_t* data_in, int bit_len){

}