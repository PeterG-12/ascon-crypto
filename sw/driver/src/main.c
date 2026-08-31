// THIS CODE IS A MODIFIED VERSION TAKING INSPIRATION FROM NEORV32 AXI BUS
// EXPLORER          //

// ================================================================================
// // The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32 //
// Copyright (c) NEORV32 contributors. // Copyright (c) 2020 - 2026 Stephan
// Nolting. All rights reserved.                  // Licensed under the
// BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause //
// ================================================================================
// //

#include "../include/aead128_driver.h"
#include "../include/aead128_helper.h"
#include "aead128_types.h"
#include <stdint.h>
#include <string.h>
#include <sys/_intsup.h>
#include <neorv32.h>

/**********************************************************************/ /**
                                                                          * @name
                                                                          * User
                                                                          * configuration
                                                                          **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/**@}*/

void machine_interrupt_handler(void);

// Global variables
char access_size;
char key_set;
char nonce_set;
volatile int exception;
volatile int interrupt;

int main() {

#ifndef __NEWLIB__
    neorv32_uart0_printf(
        "ERROR! Seems like the compiler does not support newlib... :(\n");
    return -1;
#endif
    neorv32_uart0_printf("NEWLIB version %u.%u\n", (uint32_t)__NEWLIB__,
                         (uint32_t)__NEWLIB_MINOR__);

    char buffer[70];
    char strtok_delimiter[] = " ";
    int length = 0;

    access_size = 0;

    // check if UART unit is implemented at all
    if (neorv32_uart0_available() == 0) {
        return 1;
    }

    // capture all exceptions and give debug info via UART
    neorv32_rte_setup();
    neorv32_rte_handler_install(TRAP_CODE_MEI, machine_interrupt_handler);

    // Global interrupt enable
    neorv32_cpu_csr_clr(CSR_MSTATUSH, 1 << 10);
    neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);


    // disable all interrupt sources except machine external interrupt
    neorv32_cpu_csr_write(CSR_MIE, 0);
    neorv32_cpu_csr_set(CSR_MIE, 1 << CSR_MIE_MEIE);

    interrupt = 0;

    // setup UART at default baud rate, no interrupts
    neorv32_uart0_setup(BAUD_RATE, 0);

    // intro
    neorv32_uart0_printf("\n<<< NEORV32 AEAD128 axi-lite module tester >>>\n\n");

    // info

    // Main menu
    for (;;) {
        neorv32_uart0_printf("BUS_EXPLORER:> ");
        length = neorv32_uart0_scan(buffer, 64, 1);
        neorv32_uart0_printf("\n");

        if (!length) { // nothing to be done
            continue;
        }

        char *command;


        command = strtok(buffer, strtok_delimiter);


        // decode input and execute command
        if ((!strcmp(command, "help")) || (command == NULL)) {
            neorv32_uart0_printf(
                "Available commands:\n"
                "\n"
                " help                        - show this text\n"
                " aead           - perform aead128 module test\n"
                "\n");
        }
        else if (!strcmp(command, "aead")) {
            
            int plaintext_byte_len = 2;
            int associated_data_byte_len = 11;
            
            uint8_t key[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                               0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};
            uint8_t nonce[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
                                 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
                                 0x0C, 0x0D, 0x0E, 0x0F};

            uint8_t pt[16] = {0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

            uint8_t ad[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                              0x08, 0x09, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00};

            crypto_block_t *nonce_block =
                bytes_to_crypto_block(nonce, CRYPTO_BLOCK_BIT_SIZE);
            set_nonce(nonce_block);

            crypto_block_t *key_block =
                bytes_to_crypto_block(key, CRYPTO_BLOCK_BIT_SIZE);
            set_key(key_block);

            crypto_block_t *pt_block = bytes_to_crypto_block(pt, plaintext_byte_len * 8);
            crypto_block_t *ad_block = bytes_to_crypto_block(ad, associated_data_byte_len * 8);
            crypto_block_t tag;
            
            neorv32_uart0_printf("Plaintext before processing: ");
            for(int i = 0; i < plaintext_byte_len; i++){
                neorv32_uart0_printf("%x ", pt[i]);
            }
            neorv32_uart0_printf("\n");


            crypto_block_t *ciphertext =
                encrypt(ad_block, pt_block, 11 * 8, 2 * 8, &tag);

            neorv32_uart0_printf("Tag produced: ");
            for(int i = 0; i < 16; i++){
                neorv32_uart0_printf("%x ", ciphertext->b[i]);
            }
            neorv32_uart0_printf("\n");


            crypto_block_t *plaintext =
                decrypt(ad_block, ciphertext, 11 * 8, 2 * 8, &tag);
            neorv32_uart0_printf("Plaintext after processing: ");
            for(int i = 0; i < plaintext_byte_len; i++){
                neorv32_uart0_printf("%x ", plaintext->b[i]);
            }
            neorv32_uart0_printf("\n");

            if(interrupt){
                neorv32_uart0_printf("An interrupt occured!\n");
            }
            neorv32_uart0_printf("ok\n");
        }

        else {
            neorv32_uart0_printf(
                "Invalid command. Type 'help' to see all commands.\n");
        }
    }

    return 0;
}
