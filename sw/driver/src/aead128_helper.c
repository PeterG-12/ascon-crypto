#include "../include/aead128_helper.h"
#include "aead128_types.h"
#include "aead128_util.h"
#include "neorv32_uart.h"
#include <stddef.h>
#include <stdlib.h>
#include <sys/_types.h>

void *mem_copy(const void *restrict source, void *restrict destination,
               unsigned int len) {
    const uint8_t *src = (uint8_t *)source;
    uint8_t *dst = (uint8_t *)destination;
    for (unsigned int i = 0; i < len; i++) {
        dst[i] = src[i];
    }

    return dst;
}

void *mem_set(void *restrict destination, uint8_t byte, unsigned int len) {
    uint8_t *dst = (uint8_t *)destination;
    for (unsigned int i = 0; i < len; i++) {
        dst[i] = byte;
    }

    return dst;
}


crypto_array_t *new_crypto_array(unsigned int block_count){
    crypto_array_t *array = (crypto_array_t*)malloc(sizeof(crypto_array_t));
    if(array == NULL){
        print_error("Memory allocation during bytes_to_crypto_array");
        return NULL;
    }

    array->blocks =
        (crypto_block_t *)malloc(block_count * sizeof(crypto_block_t));
    if (array->blocks == NULL) {
        print_error("Memory allocation during bytes_to_crypto_array");
        free(array);
        return NULL;
    }


    array->arr_len = block_count;
    // Assume filled crypto block
    array->byte_len = block_count * CRYPTO_BLOCK_BYTE_SIZE;

    return array;
}

void print_crypto_array(crypto_array_t* array){
    for(unsigned int i = 0; i < array->arr_len; i++){
        for(int j = 0; j < CRYPTO_BLOCK_BYTE_SIZE; j++){
            neorv32_uart0_printf("%x ", array->blocks[i].b[j]);
            if(j % 6 == 5){
                neorv32_uart0_printf("\n");
            }
        }
    }
}

void free_crypto_array(crypto_array_t* array){
    free(array->blocks);
    array->blocks = NULL;
    free(array);
    array = NULL;
}

crypto_array_t *bytes_to_crypto_array(uint8_t *bytes, size_t byte_len) {
    if (bytes == NULL)
        return NULL;

    int block_count = (byte_len / CRYPTO_BLOCK_BYTE_SIZE) + 1;
    

    crypto_array_t *array = new_crypto_array(block_count);

    array->arr_len = block_count;
    array->byte_len = byte_len;

    // Handling special case of empty plaintext
    if(byte_len == 0){
        mem_set(&array->blocks[0], 0, CRYPTO_BLOCK_BYTE_SIZE);
        array->blocks[0].b[0] = 0x01;
        array->arr_len = 0;
        return array;
    }

    for (unsigned int i = 0; i < block_count - 1; i++) {
        mem_copy(bytes + (i * CRYPTO_BLOCK_BYTE_SIZE), &array->blocks[i],
                 CRYPTO_BLOCK_BYTE_SIZE);
    }

    int last_block_len = byte_len % CRYPTO_BLOCK_BYTE_SIZE;

    mem_set(&array->blocks[block_count - 1], 0, CRYPTO_BLOCK_BYTE_SIZE);
    mem_copy(bytes + ((block_count - 1) * CRYPTO_BLOCK_BYTE_SIZE),
             &array->blocks[block_count - 1], last_block_len);

    array->blocks[block_count - 1].b[last_block_len] = 0x01;

    return array;
}

uint8_t hex_to_val(char c) {
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    return 0;
}

void hex_to_bytes(const char *hex_string, uint8_t byte_arr[],
                  unsigned int len) {
    for (unsigned int i = 0; i < len; i++) {
        byte_arr[i] = (hex_to_val(hex_string[2 * i]) << 4) |
                      hex_to_val(hex_string[2 * i + 1]);
    }
}

void print_error(const char *error_msg) { neorv32_uart0_printf(error_msg); }