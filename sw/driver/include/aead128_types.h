#pragma once

#include <unistd.h>

#define CRYPTO_BLOCK_BIT_SIZE 128
#define CRYPTO_BLOCK_BYTE_SIZE CRYPTO_BLOCK_BIT_SIZE / 8

union crypto_block{
    uint8_t b[CRYPTO_BLOCK_BYTE_SIZE];
    uint32_t w[CRYPTO_BLOCK_BYTE_SIZE / 4];
};

typedef union crypto_block crypto_block_t;
