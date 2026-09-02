#include "../include/aead128_driver.h"
#include "aead128_hal.h"
#include "aead128_helper.h"
#include "aead128_types.h"
#include <stdint.h>
#include <string.h>
#include <sys/unistd.h>

static volatile uint8_t interrupt_fired;

void machine_interrupt_handler(void) {
    struct aead128_status status = read_status_register();
    if (status.word_rdy_int) {
        interrupt_fired = 1;
        clear_word_rdy_interrupt();
    }

    if (status.finished_rdy_int) {
        interrupt_fired = 1;
        clear_finished_rdy_interrupt();
    }
}

crypto_array_t *aead_process(const crypto_array_t *associated_data,
                             const crypto_array_t *text_in, crypto_array_t *tag,
                             uint8_t encrypt_mode) {

    interrupt_fired = 0;
    struct aead128_control control;
    struct aead128_status status;

    mem_set(&control, 0, sizeof(struct aead128_control));
    mem_set(&status, 0, sizeof(struct aead128_status));

    control.encrypt_mode = encrypt_mode;
    control.text_word_left = 1;

#ifdef USE_INTERRUPTS
    control.word_rdy_en = 1;
    control.finished_rdy_en = 1;
#endif

    commit_write_ctrl_register(&control);

    int plen = 128;

    int associated_data_count =
        (associated_data->arr_len > 0)
            ? (associated_data->arr_len)
            : 0;
    int text_in_count =
        (text_in->arr_len > 0) ? (text_in->arr_len) : 0;
    int last_text_word_len = text_in->byte_len * 8 % CRYPTO_BLOCK_BIT_SIZE;

    crypto_array_t *text_out = new_crypto_array(text_in_count + (int)(text_in_count == 0));
    if (text_out == NULL) {
        print_error("Memory allocation during aead process\n");
        return NULL;
    }
    
    text_out->byte_len = text_in->byte_len;
    text_out->arr_len = (text_in->byte_len / 16) + (int)(text_in->byte_len > 0);

    int text_in_i = 0;
    int text_out_i = 0;
    int associated_data_i = 0;

    if (associated_data_count == 0) {
        control.associated_data_word_left = 0;
    } else {
        control.associated_data_word_left = 1;
        write_associated_data(associated_data->blocks[0].w);
    }

    if (text_in_count <= 1) {
        plen = last_text_word_len;
        control.text_word_left = 0;
        write_text(text_in->blocks[0].w);
    }

    control.start = 1;
    control.input_ready = 1;
    commit_write_ctrl_register(&control);
    control.input_ready = 0;

    status = read_status_register();

    control.start = 0;
    commit_write_ctrl_register(&control);

    while (status.finished != 1) {

        status = read_status_register();
        if (status.word_processed != 1) {
#ifdef USE_INTERRUPTS
            while (status.word_processed != 1) {

                neorv32_cpu_csr_clr(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);
                if (!interrupt_fired)
                    asm volatile("wfi");
                neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);

                interrupt_fired = 0;
                status = read_status_register();
                if (status.finished == 1) {
                    goto tag_read;
                }
            }
#endif

#ifndef USE_INTERRUPTS
            int word_processed_old = 0;
            if (!status.word_processed) {
                // Wait for word_processed rising edge
                while (
                    !(word_processed_old == 0 && status.word_processed == 1)) {
                    word_processed_old = status.word_processed;
                    status = read_status_register();
                }
            }
#endif
        }

        write_text_len(plen);

        if (associated_data_count > 0 &&
            associated_data_i < associated_data_count) {
            control.associated_data_word_left = 1;
            control.text_word_left = 1;
            write_associated_data(associated_data->blocks[associated_data_i].w);
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

            write_text(text_in->blocks[text_in_i].w);
            text_in_i++;
        } else {
            control.associated_data_word_left = 0;
            control.text_word_left = 0;
        }

        control.input_ready = 1;
        commit_write_ctrl_register(&control);
        control.input_ready = 0;

        status = read_status_register();

        if (status.text_ready == 1) {
            uint32_t text_out_read_buffer[4];
            read_text(text_out_read_buffer);
            mem_copy(text_out_read_buffer, text_out->blocks[text_out_i].b,
                     CRYPTO_BLOCK_BYTE_SIZE);

            text_out_i++;

            control.text_read = 1;
            commit_write_ctrl_register(&control);
            control.text_read = 0;
        }
    }
    uint32_t tag_out[4];
    #ifdef USE_INTERRUPTS
    tag_read:
    #endif

    read_tag(tag_out);
    mem_copy(tag_out, tag->blocks[0].b, CRYPTO_BLOCK_BYTE_SIZE);

    mem_set(&control, 0, sizeof(struct aead128_control));
    commit_write_ctrl_register(&control);

    return text_out;
}

crypto_array_t *encrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *plaintext, crypto_array_t *tag) {

    crypto_array_t *ciphertext =
        aead_process(associated_data, plaintext, tag, 1);
    return ciphertext;
}

crypto_array_t *decrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *ciphertext, crypto_array_t *tag) {

    crypto_array_t *resulting_tag = new_crypto_array(1);
    if (resulting_tag == NULL) {
        print_error("Memory allocation failure during decryption process\n");
        return NULL;
    }
    crypto_array_t *plaintext =
        aead_process(associated_data, ciphertext, resulting_tag, 0);

    // Only check tag if one is provided
    if (tag != NULL) {
        if (check_tag(tag, resulting_tag) == -1) {
            for(uint32_t i = 0; i < plaintext->arr_len; i++){
                mem_set(plaintext->blocks[i].b, 0, CRYPTO_BLOCK_BYTE_SIZE);
            }

            free_crypto_array(plaintext);
            free_crypto_array(resulting_tag);

            print_error("Tags do not match!\n");
            
            return NULL;
        }
    }

    free_crypto_array(resulting_tag);

    return plaintext;
}

void set_key(crypto_array_t *key) {
    uint32_t key_array[4];
    mem_copy(key->blocks, key_array, CRYPTO_BLOCK_BYTE_SIZE);
    provide_key(key_array);
}

void set_nonce(crypto_array_t *nonce) {
    uint32_t nonce_array[4];
    mem_copy(nonce->blocks, nonce_array, CRYPTO_BLOCK_BYTE_SIZE);
    provide_nonce(nonce_array);
}