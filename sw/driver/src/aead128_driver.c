#include "../include/aead128_driver.h"
#include "aead128_hal.h"
#include "aead128_helper.h"
#include "aead128_slink.h"
#include "aead128_types.h"
#include "neorv32_dma.h"
#include "neorv32_uart.h"
#include <stdint.h>
#include <string.h>
#include <sys/unistd.h>

static volatile uint8_t interrupt_fired;
static volatile uint32_t rx_fifo_depth;

void machine_interrupt_handler(void) {
    uint32_t stat = READ_STAT();
    if (CHECK_STAT(stat, STAT_WRD_RDY_INT)) {
        interrupt_fired = 1;
        clear_word_rdy_interrupt();
    }

    if (CHECK_STAT(stat, STAT_FIN_RDY_INT)) {
        interrupt_fired = 1;
        clear_finished_rdy_interrupt();
    }
}

crypto_array_t *aead_process_stream(const crypto_array_t *associated_data,
                                    const crypto_array_t *text_in,
                                    crypto_array_t *tag,
                                    crypto_array_t *text_out_buffer,
                                    uint8_t encrypt_mode, uint32_t rx_fifo_size,
                                    uint32_t tx_fifo_size) {
    interrupt_fired = 0;
    uint32_t control = 0;

    if (encrypt_mode)
        SET_CTRL(control, CTRL_ENCRYPT_MODE);

    COMMIT_CTRL(control);

    int associated_data_count =
        (associated_data->arr_len > 0) ? (associated_data->arr_len) : 0;
    int text_in_count = (text_in->arr_len > 0) ? (text_in->arr_len) : 0;
    int last_text_word_len = text_in->byte_len * 8 % CRYPTO_BLOCK_BIT_SIZE;

    text_out_buffer->byte_len = text_in->byte_len;
    text_out_buffer->arr_len = text_in->arr_len;

    provide_associated_data_count(associated_data_count);
    provide_text_count(text_in_count);
    write_text_len(last_text_word_len);

    while (!rx_empty()) {
        read_word_stream();
    }

    SET_CTRL(control, CTRL_START);
    COMMIT_CTRL(control);
    CLR_CTRL(control, CTRL_START);
    COMMIT_CTRL(control);

    for (int i = 0; i < associated_data_count; i++) {
        for (int j = 0; j < 4; j++) {
            write_word_stream(associated_data->blocks[i].w[j]);
        }
    }

    int text_received = 0;
    int text_sent = 0;

    // Configure based on FIFO depth
    const uint32_t max_blocks = 32;

    while (text_received < text_in_count) {
        while ((text_sent < text_in_count) &&
               ((text_sent - text_received) < max_blocks)) {
            for (int j = 0; j < 4; j++) {
                write_word_stream(text_in->blocks[text_sent].w[j]);
            }
            text_sent++;
        }

        uint32_t produced = get_produced_count();
        while ((text_received < produced) && (text_received < text_in_count)) {
            for (int j = 0; j < 4; j++) {
                text_out_buffer->blocks[text_received].w[j] =
                    read_word_stream();
            }
            text_received++;
        }
    }

    while (!CHECK_STAT(READ_STAT(), STAT_FIN))
        ;

    for (int i = 0; i < 4; i++) {
        tag->blocks[0].w[i] = read_word_stream();
    }

    return text_out_buffer;
}

crypto_array_t *aead_process_lite(const crypto_array_t *associated_data,
                                  const crypto_array_t *text_in,
                                  crypto_array_t *tag,
                                  crypto_array_t *text_out_buffer,
                                  uint8_t encrypt_mode) {

    interrupt_fired = 0;

    uint32_t control = 0;
    uint32_t stat = 0;

    SET_CTRL(control, CTRL_TXT_LEFT);
    if (encrypt_mode)
        SET_CTRL(control, CTRL_ENCRYPT_MODE);

#ifdef USE_INTERRUPTS
    SET_CTRL(control, CTRL_FIN_RDY_EN | CTRL_WORD_RDY_EN);
#endif

    COMMIT_CTRL(control);

    int plen = 128;

    int associated_data_count =
        (associated_data->arr_len > 0) ? (associated_data->arr_len) : 0;
    int text_in_count = (text_in->arr_len > 0) ? (text_in->arr_len) : 0;
    int last_text_word_len = text_in->byte_len * 8 % CRYPTO_BLOCK_BIT_SIZE;

    text_out_buffer->byte_len = text_in->byte_len;
    text_out_buffer->arr_len =
        (text_in->byte_len / 16) + (int)(text_in->byte_len > 0);

    int text_in_i = 0;
    int text_out_i = 0;
    int associated_data_i = 0;

    if (associated_data_count == 0) {
        CLR_CTRL(control, CTRL_AD_LEFT);
    } else {
        SET_CTRL(control, CTRL_AD_LEFT);
        write_associated_data(associated_data->blocks[0].w);
    }

    if (text_in_count <= 1) {
        plen = last_text_word_len;
        SET_CTRL(control, CTRL_TXT_LEFT);
        write_text(text_in->blocks[0].w);
    }

    SET_CTRL(control, CTRL_START);
    SET_CTRL(control, CTRL_INP_RDY);

    COMMIT_CTRL(control);
    CLR_CTRL(control, CTRL_INP_RDY);

    CLR_CTRL(control, CTRL_START);
    COMMIT_CTRL(control);

    stat = READ_STAT();

    while (!CHECK_STAT(stat, STAT_FIN)) {

        stat = READ_STAT();

        if (!CHECK_STAT(stat, STAT_WRD_PROC)) {

#ifdef USE_INTERRUPTS
            while (!CHECK_STAT(stat, STAT_WRD_PROC)) {

                neorv32_cpu_csr_clr(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);
                if (!interrupt_fired)
                    asm volatile("wfi");
                neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);

                interrupt_fired = 0;
                stat = READ_STAT();
                if (CHECK_STAT(stat, STAT_FIN)) {
                    goto tag_read;
                }
            }
#endif

#ifndef USE_INTERRUPTS
            int word_processed_old = 0;
            if (!CHECK_STAT(stat, STAT_WRD_PROC)) {
                // Wait for word_processed rising edge
                while (!(word_processed_old == 0 &&
                         CHECK_STAT(stat, STAT_WRD_PROC))) {
                    word_processed_old = stat & STAT_WRD_PROC;
                    word_processed_old = (int)(word_processed_old > 0);
                    __asm__ volatile("nop\n"
                                     "nop\n"
                                     "nop\n"
                                     "nop\n"
                                     "nop\n"
                                     "nop\n"
                                     "nop\n");
                    stat = READ_STAT();
                }
            }
#endif
        }

        write_text_len(plen);

        if (associated_data_count > 0 &&
            associated_data_i < associated_data_count) {
            SET_CTRL(control, CTRL_AD_LEFT | CTRL_TXT_LEFT);
            write_associated_data(associated_data->blocks[associated_data_i].w);
            associated_data_i++;
        } else if (text_in_i < text_in_count) {
            if (text_in_i == text_in_count - 1) {
                plen = last_text_word_len;
                write_text_len(plen);
                CLR_CTRL(control, CTRL_TXT_LEFT);
            } else {
                SET_CTRL(control, CTRL_TXT_LEFT);
            }
            CLR_CTRL(control, CTRL_AD_LEFT);

            write_text(text_in->blocks[text_in_i].w);
            text_in_i++;
        } else {
            CLR_CTRL(control, CTRL_AD_LEFT | CTRL_TXT_LEFT);
        }

        SET_CTRL(control, CTRL_INP_RDY);
        COMMIT_CTRL(control);
        CLR_CTRL(control, CTRL_INP_RDY);

        stat = READ_STAT();

        if (CHECK_STAT(stat, STAT_TXT_RDY)) {
            read_text(text_out_buffer->blocks[text_out_i].w);

            text_out_i++;

            SET_CTRL(control, CTRL_TXT_READ);
            COMMIT_CTRL(control);
            CLR_CTRL(control, CTRL_TXT_READ);
        }
    }
#ifdef USE_INTERRUPTS
tag_read:
#endif

    read_tag(tag->blocks[0].w);

    control = 0;
    COMMIT_CTRL(control);

    return text_out_buffer;
}

crypto_array_t *encrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *plaintext, crypto_array_t *tag,
                        crypto_array_t *text_out_buffer, uint32_t rx_fifo_size,
                        uint32_t tx_fifo_size) {

#ifdef STREAM_DRIVER
    crypto_array_t *ciphertext =
        aead_process_stream(associated_data, plaintext, tag, text_out_buffer, 1,
                            rx_fifo_size, tx_fifo_size);
#endif

#ifndef STREAM_DRIVER
    crypto_array_t *ciphertext =
        aead_process_lite(associated_data, plaintext, tag, text_out_buffer, 1);
#endif

    return ciphertext;
}

crypto_array_t *decrypt(const crypto_array_t *associated_data,
                        const crypto_array_t *ciphertext, crypto_array_t *tag,
                        crypto_array_t *text_out_buffer,
                        crypto_array_t *resulting_tag_buffer,
                        uint32_t rx_fifo_size, uint32_t tx_fifo_size) {

#ifdef STREAM_DRIVER
    crypto_array_t *plaintext =
        aead_process_stream(associated_data, ciphertext, resulting_tag_buffer,
                            text_out_buffer, 0, rx_fifo_size, tx_fifo_size);
#endif

#ifndef STREAM_DRIVER
    crypto_array_t *plaintext = aead_process_lite(
        associated_data, ciphertext, resulting_tag_buffer, text_out_buffer, 0);
#endif

    // Only check tag if one is provided
    if (tag != NULL) {
        if (check_tag(tag, resulting_tag_buffer) == -1) {
            for (uint32_t i = 0; i < plaintext->arr_len; i++) {
                mem_set(plaintext->blocks[i].b, 0, CRYPTO_BLOCK_BYTE_SIZE);
            }

            print_error("Tags do not match!\n");

            return NULL;
        }
    }

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
