#include "aead128_hal.h"
#include "aead128_helper.h"
#include <stdint.h>
#include <stdlib.h>

struct aead128_status read_status_register(void) {
    uint32_t val = read_32(A128_ADDR_STATUS);
    struct aead128_status status;

    status.finished = val & 1;
    status.text_ready = (val & 2) >> 1;
    status.word_processed = (val & 4) >> 2;
    status.word_rdy_int = (val & 8) >> 3;
    status.finished_rdy_int = (val & 16) >> 4;

    return status;
}

void commit_write_ctrl_register(struct aead128_control *state) {
    uint32_t val = 0;

    val |= (state->start) | (state->associated_data_word_left << 1) |
           (state->text_word_left << 2) | (state->encrypt_mode << 3) |
           (state->input_ready << 4) | (state->text_read << 5) |
           (state->word_rdy_en << 6) | (state->finished_rdy_en << 7);

    write_32(A128_ADDR_CTRL, val);
}

uint32_t read_32(uint32_t address) { return A128_MMIO_R(address); }

uint32_t *read_128(uint32_t address) {
    uint32_t *read_val = (uint32_t *)malloc(sizeof(uint32_t) * 4);
    if (read_val == NULL) {
        print_error("Read data memory allocation failure\n");
        return NULL;
    }
    for (int i = 0; i < 4; i++) {
        read_val[i] = read_32(address + (i * 4));
    }

    return read_val;
}

void write_32(uint32_t address, const uint32_t data) {
    A128_MMIO_W(address, data);
}

void write_128(uint32_t address, const uint32_t data[4]) {
    for (int i = 0; i < 4; i++) {
        write_32(address + (i * 4), data[i]);
    }
}

void provide_key(const uint32_t key[4]) { write_128(A128_ADDR_KEY, key); }

void provide_nonce(const uint32_t nonce[4]) {
    write_128(A128_ADDR_NONCE, nonce);
}

void write_associated_data(const uint32_t associated_data[4]) {
    write_128(A128_ADDR_ASSOC_DATA, associated_data);
}

void write_text(const uint32_t text[4]) { write_128(A128_ADDR_TEXT_IN, text); }

void write_text_len(uint32_t text_len) {
    write_32(A128_ADDR_TEXT_LEN, text_len);
}

uint8_t *read_text() { return (uint8_t *)read_128(A128_ADDR_TEXT_OUT); }

uint8_t *read_tag() { return (uint8_t *)read_128(A128_ADDR_TAG_OUT); }

inline void clear_word_rdy_interrupt(){
    write_32(A128_ADDR_STATUS, 1 << 3);
}

inline void clear_finished_rdy_interrupt(){
    write_32(A128_ADDR_STATUS, 1 << 4);
}