#pragma once

#include "../src/aead128_util.h"
#include "aead128_types.h"
#include <stdint.h>
#include <sys/_types.h>
#include <unistd.h>

crypto_block_t *bytes_to_crypto_block(uint8_t *bytes, unsigned int bit_len);
void *mem_copy(const void *restrict source,
                             void *restrict destination, unsigned int len);
void *mem_set(void *restrict destination, uint8_t byte,
                            unsigned int len);

uint8_t hex_to_val(char c);
void hex_to_bytes(const char* hex_string, uint8_t byte_arr[], unsigned int len);
void print_error(const char* error_msg);