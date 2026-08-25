#include "../src/aead128_hal.h"
#include "../src/aead128_util.h"




void encrypt(const uint8_t *associated_data, const uint8_t *plaintext,
             int associated_data_len, int plaintext_len);
void decrypt(const uint8_t *associated_data, const uint8_t *ciphertext,
             int associated_data_len, int ciphertext_len);

