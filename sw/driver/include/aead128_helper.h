#pragma once

#include "../src/aead128_util.h"
#include "aead128_types.h"
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/_intsup.h>
#include <sys/_types.h>
#include <unistd.h>

void print_crypto_array(crypto_array_t *array);
void free_crypto_array(crypto_array_t *array);
crypto_array_t *new_crypto_array(unsigned int block_count);
crypto_array_t *bytes_to_crypto_array(uint8_t *bytes, size_t byte_len);

static inline void *mem_copy(const void *restrict source,
                             void *restrict destination, size_t len) {
    const uint8_t *src = (uint8_t *)source;
    uint8_t *dst = (uint8_t *)destination;
    for (unsigned int i = 0; i < len; i++) {
        dst[i] = src[i];
    }

    return dst;
}

static inline void *word_mem_copy(const void *restrict source,
                                  void *restrict destination, size_t len) {
    
    if(len % 4){
        return NULL;
    }
    
    const uint32_t *src = (uint32_t *)source;
    uint32_t *dst = (uint32_t *)destination;
    for (size_t i = 0; i < len / 4; i += 1) {
        dst[i] = src[i];
    }

    return dst;
}

static inline void *mem_set(void *restrict destination, uint8_t byte,
                            unsigned int len) {
    uint8_t *dst = (uint8_t *)destination;
    for (unsigned int i = 0; i < len; i++) {
        dst[i] = byte;
    }

    return dst;
}

uint8_t hex_to_val(char c);
void hex_to_bytes(const char *hex_string, uint8_t byte_arr[], unsigned int len);
void print_error(const char *error_msg);
void string_to_bytes(const char *string, size_t len, uint8_t bytes[32]);
void putc_hex_character(uint8_t byte);
void print_byte_string(uint8_t *bytes, size_t len);
