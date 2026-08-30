#pragma once

#include "../src/aead128_hal.h"
#include "../src/aead128_util.h"
#include "aead128_types.h"
#include <stdint.h>

crypto_block_t *encrypt(const crypto_block_t *associated_data,
                        const crypto_block_t *plaintext,
                        int associated_data_bit_len, int plaintext_bit_len,
                        crypto_block_t *tag);
crypto_block_t *decrypt(const crypto_block_t *associated_data,
                        const crypto_block_t *ciphertext,
                        int associated_data_bit_len, int ciphertext_bit_len,
                        crypto_block_t *tag);

void set_key(crypto_block_t *key);
void set_nonce(crypto_block_t *nonce);