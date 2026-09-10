#include "../include/aead128_helper.h"
#include "../include/aead128_driver.h"
#include "aead128_hal.h"
#include "neorv32_slink.h"
#include <neorv32.h>
#include <stdint.h>
#include <sys/types.h>

#define SLINK_DATA 0xffec0008

static inline int setup_stream() {
    if (neorv32_slink_available() == 0) {
        print_error("ERROR! SLINK module not implemented.");
        return -1;
    }
    // setup SLINK module, no interrupts
    neorv32_slink_setup(0);

    neorv32_dma_enable();
    return 0;
}

static inline int get_tx_fifo_size() {
    return neorv32_slink_get_tx_fifo_depth();
}

static inline int get_rx_fifo_size() {
    return neorv32_slink_get_rx_fifo_depth();
}

static inline int tx_full() { return neorv32_slink_tx_full(); }

static inline int tx_empty() { return neorv32_slink_tx_empty(); }

static inline int rx_empty() { return neorv32_slink_rx_empty(); }

static inline int rx_full() { return neorv32_slink_rx_full(); }


static inline void write_word_stream(const uint32_t word) {
    A128_MMIO_W(SLINK_DATA, word);
}

static inline uint32_t read_word_stream() { return A128_MMIO_R(SLINK_DATA); }
