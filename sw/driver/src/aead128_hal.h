#pragma once

#include "aead128_regs.h"
#include <neorv32.h>
#include <stdint.h>
#include <unistd.h>

#define A128_MMIO_R(a) (*(volatile uint32_t *)(a))
#define A128_MMIO_W(a, v) (*(volatile uint32_t *)(a) = (uint32_t)(v))

#define CTRL_START (1 << 0)
#define CTRL_AD_LEFT (1 << 1)
#define CTRL_TXT_LEFT (1 << 2)
#define CTRL_ENCRYPT_MODE (1 << 3)
#define CTRL_INP_RDY (1 << 4)
#define CTRL_TXT_READ (1 << 5)
#define CTRL_WORD_RDY_EN (1 << 6)
#define CTRL_FIN_RDY_EN (1 << 7)


#define STAT_FIN (1 << 0)
#define STAT_TXT_RDY (1 << 1)
#define STAT_WRD_PROC (1 << 2)
#define STAT_WRD_RDY_INT (1 << 3)
#define STAT_FIN_RDY_INT (1 << 4)

#define SET_CTRL(x, v) ((x) |= (v)) 
#define CLR_CTRL(x, v) ((x) &= ~(v))
#define COMMIT_CTRL(x) (A128_MMIO_W(A128_ADDR_CTRL, x))

#define READ_STAT() (A128_MMIO_R(A128_ADDR_STATUS))
#define CHECK_STAT(s, v) ((s) & (v))


struct aead128_control {
    uint8_t start;
    uint8_t associated_data_word_left;
    uint8_t text_word_left;
    uint8_t encrypt_mode;
    uint8_t input_ready;
    uint8_t text_read;
    uint8_t word_rdy_en;
    uint8_t finished_rdy_en;
};

struct aead128_status {
    uint8_t finished;
    uint8_t text_ready;
    uint8_t word_processed;
    uint8_t word_rdy_int;
    uint8_t finished_rdy_int;
};

static inline uint32_t read_32(uint32_t address) {
    return A128_MMIO_R(address);
}

static inline void read_128(uint32_t address, uint32_t buffer[4]) {

    for (int i = 0; i < 4; i++) {
        buffer[i] = read_32(address + (i * 4));
    }

    return;
}

static inline void write_32(uint32_t address, const uint32_t data) {
    A128_MMIO_W(address, data);
}

static inline void write_128(uint32_t address, const uint32_t data[4]) {
    for (int i = 0; i < 4; i++) {
        write_32(address + (i * 4), data[i]);
    }
}

static inline struct aead128_status read_status_register(void) {
    uint32_t val = read_32(A128_ADDR_STATUS);
    struct aead128_status status;

    status.finished = val & 1;
    status.text_ready = (val & 2) >> 1;
    status.word_processed = (val & 4) >> 2;
    status.word_rdy_int = (val & 8) >> 3;
    status.finished_rdy_int = (val & 16) >> 4;

    return status;
}

static inline void commit_write_ctrl_register(struct aead128_control *state) {
    uint32_t val = 0;

    val |= (state->start) | (state->associated_data_word_left << 1) |
           (state->text_word_left << 2) | (state->encrypt_mode << 3) |
           (state->input_ready << 4) | (state->text_read << 5) |
           (state->word_rdy_en << 6) | (state->finished_rdy_en << 7);

    write_32(A128_ADDR_CTRL, val);
}

static inline void provide_key(const uint32_t key[4]) {
    write_128(A128_ADDR_KEY, key);
}

static inline void provide_nonce(const uint32_t nonce[4]) {
    write_128(A128_ADDR_NONCE, nonce);
}

static inline void write_associated_data(const uint32_t associated_data[4]) {
    write_128(A128_ADDR_ASSOC_DATA, associated_data);
}

static inline void write_text(const uint32_t text[4]) {
    write_128(A128_ADDR_TEXT_IN, text);
}

static inline void write_text_len(uint32_t text_len) {
    write_32(A128_ADDR_TEXT_LEN, text_len);
}

static inline void read_text(uint32_t buffer[4]) {
    read_128(A128_ADDR_TEXT_OUT, buffer);
}

static inline void read_tag(uint32_t buffer[4]) {
    read_128(A128_ADDR_TAG_OUT, buffer);
}

static inline void clear_word_rdy_interrupt() {
    write_32(A128_ADDR_STATUS, 1 << 3);
}

static inline void clear_finished_rdy_interrupt() {
    write_32(A128_ADDR_STATUS, 1 << 4);
}
