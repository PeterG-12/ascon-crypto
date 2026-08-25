#include "../include/aead128_helper.h"
#include "aead128_types.h"
#include "aead128_util.h"
#include <stdlib.h>
#include <sys/_types.h>

inline void *mem_copy(const void *restrict source,
                             void *restrict destination, unsigned int len) {
    const uint8_t *src = (uint8_t *)source;
    uint8_t *dst = (uint8_t *)destination;
    for (unsigned int i = 0; i < len; i++) {
        dst[i] = src[i];
    }

    return dst;
}

inline void *mem_set(void *restrict destination, uint8_t byte,
                            unsigned int len) {
    uint8_t *dst = (uint8_t *)destination;
    for (unsigned int i = 0; i < len; i++) {
        dst[i] = byte;
    }

    return dst;
}

crypto_block_t *bytes_to_crypto_block(uint8_t *bytes, unsigned int bit_len) {
    if (bytes == NULL)
        return NULL;

    int block_count = (bit_len / CRYPTO_BLOCK_BIT_SIZE) + 1;

    crypto_block_t *blocks =
        (crypto_block_t *)malloc(block_count * sizeof(crypto_block_t));
    if (blocks == NULL) {
        return NULL;
    }

    for (unsigned int i = 0; i < block_count - 1; i++) {
        mem_copy(bytes + (i * CRYPTO_BLOCK_BYTE_SIZE), &blocks[i],
                 CRYPTO_BLOCK_BYTE_SIZE);
    }

    int last_block_len = bit_len % CRYPTO_BLOCK_BIT_SIZE;

    mem_set(&blocks[block_count - 1], 0, CRYPTO_BLOCK_BYTE_SIZE);
    mem_copy(bytes + ((block_count - 1) * CRYPTO_BLOCK_BYTE_SIZE),
             &blocks[block_count - 1], CRYPTO_BLOCK_BYTE_SIZE);

    pad_block(blocks[block_count - 1], last_block_len);

    return blocks;
}
