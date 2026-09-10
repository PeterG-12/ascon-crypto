#pragma once

#include "aead128_types.h"
#include <stdint.h>



#define STREAM_DRIVER 

#define IS_WORD_RDY_INT(status) (status & (1 << 6)) 
#define IS_FINISH_RDY_INT(status) (status & (1 << 7)) 

crypto_array_t *encrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *plaintext,
                        crypto_array_t *tag, crypto_array_t *text_out_buffer,  uint32_t rx_fifo_size, uint32_t tx_fifo_size);
crypto_array_t *decrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *ciphertext,
                        crypto_array_t *tag, crypto_array_t *text_out_buffer, crypto_array_t* resulting_tag_buffer,  uint32_t rx_fifo_size, uint32_t tx_fifo_size);
crypto_array_t *aead_process_lite(const crypto_array_t *associated_data,
                             const crypto_array_t *ciphertext, crypto_array_t *tag, crypto_array_t *text_out_buffer,
                             uint8_t encrypt_mode);
crypto_array_t *aead_process_stream(const crypto_array_t *associated_data,
                             const crypto_array_t *text_in, crypto_array_t *tag, crypto_array_t *text_out_buffer,
                             uint8_t encrypt_mode, uint32_t rx_fifo_size, uint32_t tx_fifo_size);

void set_key(crypto_array_t *key);
void set_nonce(crypto_array_t *nonce);
void set_associated_data_count(uint32_t count);
void set_text_count(uint32_t count);
void slink_rx_full_handler(void);