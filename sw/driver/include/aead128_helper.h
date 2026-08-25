#pragma once

#include "../src/aead128_util.h"
#include "aead128_types.h"
#include <stdint.h>
#include <unistd.h>

crypto_block_t *bytes_to_crypto_block(uint8_t *bytes, unsigned int bit_len);
inline void *mem_copy(const void *restrict source,
                             void *restrict destination, unsigned int len);
inline void *mem_set(void *restrict destination, uint8_t byte,
                            unsigned int len);