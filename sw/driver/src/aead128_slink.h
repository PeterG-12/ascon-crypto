#include "../include/aead128_helper.h"
#include "../include/aead128_driver.h"
#include "aead128_hal.h"
#include "neorv32_dma.h"
#include "neorv32_slink.h"
#include "neorv32_uart.h"
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
    //neorv32_uart0_printf("Sent word: %x\n", word);
    A128_MMIO_W(SLINK_DATA, word);
}

static inline uint32_t read_word_stream() { 
    uint32_t data = A128_MMIO_R(SLINK_DATA);
    //neorv32_uart0_printf("Read word: %x\n", data);
    return data; }

static inline void program_send(const void * src, void * dest, unsigned int count){
    int dma_rc = neorv32_dma_program(
    (uint32_t)(src), 
    (uint32_t)(dest), 
    DMA_SRC_INC_WORD |  
    DMA_DST_CONST_WORD | 
    count
  );

  if (dma_rc) {
    print_error("Programming DMA descriptor failed!\n");
  }

  return;
}

static inline void program_recv(const void * src, void * dest, unsigned int count){
    int dma_rc = neorv32_dma_program(
    (uint32_t)(src), 
    (uint32_t)(dest), 
    DMA_SRC_CONST_WORD |  
    DMA_DST_INC_WORD | 
    count
  );

  if (dma_rc) {
    print_error("Programming DMA descriptor failed!\n");
  }

  return;
}