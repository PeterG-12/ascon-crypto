#pragma once

#include "aead128_regs.h"
#include <neorv32.h>
#include <stdint.h>
#include <unistd.h>

#define A128_MMIO_R(a) (*(volatile uint32_t *)(a))
#define A128_MMIO_W(a, v) (*(volatile uint32_t *)(a) = (uint32_t)(v))

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

void write_32(uint32_t address, const uint32_t data);
void write_128(uint32_t address, const uint32_t data[4]);
uint32_t read_32(uint32_t address);
void read_128(uint32_t address, uint32_t buffer[4]);

void provide_key(const uint32_t key[4]);
void provide_nonce(const uint32_t nonce[4]);
void write_text(const uint32_t text[4]);
void write_associated_data(const uint32_t associated_data[4]);
void write_text_len(const uint32_t text_len);
void read_text(uint32_t buffer[4]);
void read_tag(uint32_t buffer[4]);

void commit_write_ctrl_register(struct aead128_control *state);
struct aead128_status read_status_register(void);
void clear_word_rdy_interrupt();
void clear_finished_rdy_interrupt();

