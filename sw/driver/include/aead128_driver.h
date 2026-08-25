#pragma once

#include "../src/aead128_hal.h"
#include "aead128_types.h"
#include "../src/aead128_util.h"
#include <stdint.h>



void encrypt(const crypto_block_t *associated_data, const crypto_block_t *plaintext,
             int associated_data_len, int plaintext_len);
void decrypt(const crypto_block_t *associated_data, const crypto_block_t *ciphertext,
             int associated_data_len, int ciphertext_len);

