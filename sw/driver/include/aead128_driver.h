#pragma once

#include "../src/aead128_util.h"
#include "aead128_types.h"
#include <stdint.h>

#define USE_INTERRUPTS
#define IS_WORD_RDY_INT(status) (status & (1 << 6)) 
#define IS_FINISH_RDY_INT(status) (status & (1 << 7)) 

crypto_array_t *encrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *plaintext,
                        crypto_array_t *tag);
crypto_array_t *decrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *ciphertext,
                        crypto_array_t *tag);
crypto_array_t *aead_process(const crypto_array_t *associated_data,
                             const crypto_array_t *ciphertext, crypto_array_t *tag,
                             uint8_t encrypt_mode);

void set_key(crypto_array_t *key);
void set_nonce(crypto_array_t *nonce);