#include "../include/aead128_driver.h"


void encrypt(const uint8_t *associated_data, const uint8_t *plaintext,
             int associated_data_len, int plaintext_len) {
    struct aead128_control control;
    control.encrypt_mode = 1;
    control.text_word_left = 1;

    commit_write_ctrl_register(&control);

    int plen = 128;
    int associated_data_count =
        associated_data_len / 128 + (int)(associated_data_len > 0);
    int plaintext_count = plaintext_len / 128 + (int)(plaintext_len > 0);
    int last_text_word_len = plaintext_len % 128;

    int text_i = 0;
    int associated_data_i = 0;

    if (associated_data_count == 0) {
        control.associated_data_word_left = 0;
    } else {
        control.associated_data_word_left = 1;
        uint32_t associated_data_buffer[4];

        get_nth_word(associated_data, associated_data_len, associated_data_i,
                     associated_data_buffer);

        write_associated_data(associated_data_buffer);
    }

    if (plaintext_count <= 1) {
        plen = last_text_word_len;
        control.text_word_left = 0;
    }

    commit_write_ctrl_register(&control);
    uint32_t text[4];
    write_text(text);
}

void decrypt(const uint8_t *associated_data, const uint8_t *ciphertext,
             int associated_data_len, int ciphertext_len) {}