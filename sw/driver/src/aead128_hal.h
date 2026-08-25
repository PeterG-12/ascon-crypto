#include "aead128_regs.h"
#include <neorv32.h>
#include <stdint.h>
#include <unistd.h>

#define A128_MMIO_R(a) (*(volatile uint8_t *)(a))
#define A128_MMIO_W(a, v) (*(volatile uint8_t *)(a) = (uint8_t)(v))

// Prototypes
void test_memory(uint32_t address);
void set_memory(uint32_t address, int data, uint32_t num);
void read_memory(uint32_t address);
void setup_access(void);
void write_memory(uint32_t address, uint32_t data);
void hexdump(uint32_t address);
void aux_print_hex_byte(uint8_t byte);
void memory_trap_handler(void);

struct aead128_control {
    uint8_t start;
    uint8_t associated_data_word_left;
    uint8_t text_word_left;
    uint8_t encrypt_mode;
    uint8_t input_ready;
    uint8_t text_read;
};

struct aead128_status {
    uint8_t finished;
    uint8_t text_ready;
    uint8_t word_processed;
};

void write_32(uint32_t address, const uint32_t data);
void write_128(uint32_t address, const uint32_t data[4]);
uint32_t read_32(uint32_t address);
uint32_t *read_128(uint32_t address);

void provide_key(uint32_t key[4]);
void provide_nonce(uint32_t nonce[4]);
void write_text(uint32_t text[4]);
void write_associated_data(uint32_t associated_data[4]);
void write_text_len(uint32_t text_len);

void commit_write_ctrl_register(struct aead128_control *state);
struct aead128_status read_status_register(void);


