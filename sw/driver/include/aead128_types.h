#pragma once

#include <stddef.h>
#include <unistd.h>

#define CRYPTO_BLOCK_BIT_SIZE 128
#define CRYPTO_BLOCK_BYTE_SIZE 16



union crypto_block{
    uint8_t b[CRYPTO_BLOCK_BYTE_SIZE];
    uint32_t w[CRYPTO_BLOCK_BYTE_SIZE / 4];
};

typedef union crypto_block crypto_block_t;


struct crypto_array{
    crypto_block_t* blocks;
    size_t arr_len;
    size_t byte_len;
};

typedef struct crypto_array crypto_array_t;

