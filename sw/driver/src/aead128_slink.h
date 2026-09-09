#include "../include/aead128_helper.h"
#include "neorv32_sdi.h"
#include "neorv32_slink.h"
#include <neorv32.h>
#include <stdint.h>
#include <sys/types.h>

static inline int setup_stream() {
    if (neorv32_slink_available() == 0) {
        print_error("ERROR! SLINK module not implemented.");
        return -1;
    }

    int rx_depth = neorv32_slink_get_rx_fifo_depth();
    int tx_depth = neorv32_slink_get_tx_fifo_depth();
    neorv32_uart0_printf("RX FIFO depth: %u\n"
                         "TX FIFO depth: %u\n\n",
                         rx_depth, tx_depth);

    // setup SLINK module, no interrupts
    neorv32_slink_setup(0);
    return 0;
}

static inline int tx_full() { return neorv32_slink_tx_full(); }

static inline int rx_empty() { return neorv32_slink_rx_empty(); }

static inline void write_word_stream(const uint32_t word) {
    neorv32_uart0_printf("Sending: %x\n", word);
    neorv32_slink_put(word);
}

static inline uint32_t read_word_stream() {
    uint32_t word = neorv32_slink_get();
    neorv32_uart0_printf("Receving: %x\n", word);
    return word;
}
