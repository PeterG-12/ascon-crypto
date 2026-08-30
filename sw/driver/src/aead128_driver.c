#include "../include/aead128_driver.h"
#include "aead128_hal.h"
#include "aead128_helper.h"
#include "aead128_types.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/unistd.h>

crypto_block_t *aead_process(const crypto_block_t *associated_data,
                             const crypto_block_t *text_in,
                             int associated_data_bit_len, int text_in_bit_len,
                             crypto_block_t *tag, uint8_t encrypt_mode) {

    struct aead128_control control;
    struct aead128_status status;

    mem_set(&control, 0, sizeof(struct aead128_control));
    mem_set(&status, 0, sizeof(struct aead128_status));

    control.encrypt_mode = encrypt_mode;
    control.text_word_left = 1;

    commit_write_ctrl_register(&control);

    int plen = 128;
    int associated_data_count =
        associated_data_bit_len / 128 + (int)(associated_data_bit_len > 0);
    int text_in_count = text_in_bit_len / 128 + (int)(text_in_bit_len > 0);
    int last_text_word_len = text_in_bit_len % 128;

    crypto_block_t *text_out =
        (crypto_block_t *)malloc(text_in_count * sizeof(crypto_block_t));
    if (text_out == NULL) {
        return NULL;
    }

    int text_in_i = 0;
    int text_out_i = 0;
    int associated_data_i = 0;

    if (associated_data_count == 0) {
        control.associated_data_word_left = 0;
    } else {
        control.associated_data_word_left = 1;
        write_associated_data(associated_data[0].w);
    }

    if (text_in_count <= 1) {
        plen = last_text_word_len;
        control.text_word_left = 0;
        write_text(text_in[0].w);
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
        } else if (text_in_i < text_in_count) {
            if (text_in_i == text_in_count - 1) {
                plen = last_text_word_len;
                write_text_len(plen);
                control.text_word_left = 0;
            } else {
                control.text_word_left = 1;
            }

            control.associated_data_word_left = 0;

            write_text(text_in[text_in_i].w);
            text_in_i++;
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
            uint8_t *text_out_read_buffer = read_text();
            mem_copy(text_out_read_buffer, text_out + text_out_i, CRYPTO_BLOCK_BYTE_SIZE);
            
            free(text_out_read_buffer);
            text_out_read_buffer = NULL;
            
            text_out_i++;

            control.text_read = 1;
            commit_write_ctrl_register(&control);
            control.text_read = 0;
        }
    }

    uint8_t *tag_out = read_tag();
    mem_copy(tag_out, tag, CRYPTO_BLOCK_BYTE_SIZE);

    mem_set(&control, 0, sizeof(struct aead128_control));
    commit_write_ctrl_register(&control);

    return text_out;
}

crypto_block_t *encrypt(const crypto_block_t *associated_data,
                        const crypto_block_t *plaintext,
                        int associated_data_bit_len, int plaintext_bit_len,
                        crypto_block_t *tag) {

    crypto_block_t *ciphertext =
        aead_process(associated_data, plaintext, associated_data_bit_len,
                     plaintext_bit_len, tag, 1);
    return ciphertext;
}

crypto_block_t *decrypt(const crypto_block_t *associated_data,
                        const crypto_block_t *ciphertext,
                        int associated_data_bit_len, int ciphertext_bit_len,
                        crypto_block_t *tag) {

    crypto_block_t *resulting_tag = (crypto_block_t*)malloc(sizeof(crypto_block_t));
    if(resulting_tag == NULL){
        return NULL;
    }
    crypto_block_t *plaintext =
        aead_process(associated_data, ciphertext, associated_data_bit_len,
                     ciphertext_bit_len, resulting_tag, 0);

    // Only check tag if one is provided
    if (tag != NULL) {
        if(check_tag(tag, resulting_tag) == -1){
            mem_set(plaintext, 0, CRYPTO_BLOCK_BYTE_SIZE);
            return NULL;
        }
    }

    free(resulting_tag);
    resulting_tag = NULL;

    return plaintext;
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