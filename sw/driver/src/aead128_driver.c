#include "../include/aead128_driver.h"
#include "aead128_hal.h"
#include "aead128_helper.h"
#include "aead128_types.h"
#include <stdint.h>
#include <stdlib.h>
#include <sys/unistd.h>

crypto_block_t *encrypt(const crypto_block_t *associated_data,
                        const crypto_block_t *plaintext,
                        int associated_data_bit_len, int plaintext_bit_len,
                        crypto_block_t *tag) {
    struct aead128_control control;
    struct aead128_status status;
    
    mem_set(&control, 0, sizeof(struct aead128_control));
    mem_set(&status, 0, sizeof(struct aead128_status));

    control.encrypt_mode = 1;
    control.text_word_left = 1;

    commit_write_ctrl_register(&control);

    int plen = 128;
    int associated_data_count =
        associated_data_bit_len / 128 + (int)(associated_data_bit_len > 0);
    int plaintext_count =
        plaintext_bit_len / 128 + (int)(plaintext_bit_len > 0);
    int last_text_word_len = plaintext_bit_len % 128;

    crypto_block_t *ciphertext =
        (crypto_block_t *)malloc(plaintext_count * sizeof(crypto_block_t));
    if (ciphertext == NULL) {
        return NULL;
    }

    int plaintext_i = 0;
    int ciphertext_i = 0;
    int associated_data_i = 0;

    if (associated_data_count == 0) {
        control.associated_data_word_left = 0;
    } else {
        control.associated_data_word_left = 1;
        write_associated_data(associated_data[0].w);
    }

    if (plaintext_count <= 1) {
        plen = last_text_word_len;
        control.text_word_left = 0;
        write_text(plaintext[0].w);
    }

    control.start = 1;
    control.input_ready = 1;
    commit_write_ctrl_register(&control);
    control.input_ready = 0;

    status = read_status_register();

    control.start = 0;
    commit_write_ctrl_register(&control);

    while (status.finished != 1) {

        int word_processed_old = 0;
        status = read_status_register();
        if (status.word_processed != 1) {
            // Wait for word_processed rising edge
            while (!(word_processed_old == 0 && status.word_processed == 1)) {
                word_processed_old = status.word_processed;
                status = read_status_register();
            }
        }

        write_text_len(plen);

        if (associated_data_count > 0 &&
            associated_data_i < associated_data_count) {
            control.associated_data_word_left = 1;
            control.text_word_left = 1;
            write_associated_data(associated_data[associated_data_i].w);
            associated_data_i++;
        } else if (plaintext_i < plaintext_count) {
            if (plaintext_i == plaintext_count - 1) {
                plen = last_text_word_len;
                write_text_len(plen);
                control.text_word_left = 0;
            } else {
                control.text_word_left = 1;
            }

            control.associated_data_word_left = 0;

            write_text(plaintext[plaintext_i].w);
            plaintext_i++;
        } else {
            control.associated_data_word_left = 0;
            control.text_word_left = 0;
        }

        control.input_ready = 1;
        commit_write_ctrl_register(&control);
        control.input_ready = 0;

        int text_ready_old = status.text_ready;
        status = read_status_register();

        if (text_ready_old == 0 && status.text_ready == 1) {
            uint8_t *text_out = read_text();
            mem_copy(text_out, ciphertext + ciphertext_i,
                     CRYPTO_BLOCK_BYTE_SIZE);
            ciphertext_i++;
            
            control.text_read = 1;
            commit_write_ctrl_register(&control);
            control.text_read = 0;
        }
    }

    uint8_t *tag_out = read_tag();
    mem_copy(tag_out, tag, CRYPTO_BLOCK_BYTE_SIZE);

    mem_set(&control, 0, sizeof(struct aead128_control));

    return ciphertext;
}

crypto_block_t *decrypt(const crypto_block_t *associated_data,
                        const crypto_block_t *ciphertext,
                        int associated_data_bit_len, int ciphertext_bit_len,
                        crypto_block_t *tag) {
    return NULL;
}

void set_key(crypto_block_t *key) {
    uint32_t key_array[4];
    mem_copy(key, key_array, CRYPTO_BLOCK_BYTE_SIZE);
    provide_key(key_array);
}

void set_nonce(crypto_block_t *nonce) {
    uint32_t nonce_array[4];
    mem_copy(nonce, nonce_array, CRYPTO_BLOCK_BYTE_SIZE);
    provide_nonce(nonce_array);
}