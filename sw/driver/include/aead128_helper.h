#pragma once

#include <stdint.h>
#include "aead128_types.h"
#include "../src/aead128_util.h"
#include <unistd.h>

crypto_block_t* bytes_to_crypto_block(uint8_t* bytes,unsigned int bit_len);
static inline void* mem_copy(const void *restrict source, void *restrict destination, unsigned int len);