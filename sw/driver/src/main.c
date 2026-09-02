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
#include "neorv32_uart.h"
#include <neorv32.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sys/_intsup.h>

/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/**@}*/

void machine_interrupt_handler(void);
void do_encryption_decryption(uint8_t pt[32], uint8_t ad[32],
                              size_t pt_byte_len, size_t ad_byte_len);

// Global variables
char access_size;
char key_set;
char nonce_set;
volatile int exception;

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

  neorv32_cpu_csr_write(CSR_MIE, 0);

// Global interrupt enable
#ifdef USE_INTERRUPTS
  neorv32_cpu_csr_clr(CSR_MSTATUSH, 1 << 10);
  neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);

  // disable all interrupt sources except machine external interrupt

  neorv32_cpu_csr_set(CSR_MIE, 1 << CSR_MIE_MEIE);
#endif

  // setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // intro
  neorv32_uart0_printf("\n<<< NEORV32 AEAD128 axi-lite module tester >>>\n\n");

  // info
  uint8_t pt[32] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                    0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F};

  uint8_t ad[32] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                    0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F};

  size_t plaintext_byte_len = 32;
  size_t associated_data_byte_len = 32;

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

    if (!strcmp(command, "pt")) {
      neorv32_uart0_printf("Enter plaintext ");
      int length = neorv32_uart0_scan(buffer, 64, 1);
      neorv32_uart0_printf("\n");
      string_to_bytes(buffer, length, pt);
      plaintext_byte_len = length / 2 + (length % 2);
    }

    else if (!strcmp(command, "ad")) {
      neorv32_uart0_printf("Enter associated data ");
      int length = neorv32_uart0_scan(buffer, 64, 1);
      neorv32_uart0_printf("\n");
      string_to_bytes(buffer, length, ad);
      associated_data_byte_len = length / 2 + (length % 2);
    }

    else if (!strcmp(command, "aead")) {
      do_encryption_decryption(pt, ad, plaintext_byte_len,
                               associated_data_byte_len);
    }

    else if (!strcmp(command, "kat")) {
      for (int j = 0; j < 33; j++) {
        for (int i = 0; i < 33; i++) {
          do_encryption_decryption(pt, ad, j,
                                   i);
        }
      }

    }

    else {
      neorv32_uart0_printf(
          "Invalid command. Type 'help' to see all commands.\n");
    }
  }

  return 0;
}

void do_encryption_decryption(uint8_t pt[32], uint8_t ad[32],
                              size_t pt_byte_len, size_t ad_byte_len) {
  uint8_t key[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                     0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};
  uint8_t nonce[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                       0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};

  crypto_array_t *nonce_block = bytes_to_crypto_array(nonce, 16);
  set_nonce(nonce_block);

  crypto_array_t *key_block = bytes_to_crypto_array(key, 16);
  set_key(key_block);

  crypto_array_t *pt_block = bytes_to_crypto_array(pt, pt_byte_len);
  crypto_array_t *ad_block = bytes_to_crypto_array(ad, ad_byte_len);
  crypto_array_t *tag = new_crypto_array(1);

  neorv32_uart0_printf("Plaintext before processing: \n");
  for (size_t i = 0; i < pt_byte_len; i++) {
    putc_hex_character(pt[i]);
  }
  neorv32_uart0_printf("\n");

  crypto_array_t *ciphertext = encrypt(ad_block, pt_block, tag);

  neorv32_uart0_printf("Tag produced: \n");
  print_crypto_array(tag);
  neorv32_uart0_printf("\n");

  neorv32_uart0_printf("Ciphertext produced: \n");
  print_crypto_array(ciphertext);

  neorv32_uart0_printf("\n");

  crypto_array_t *plaintext = decrypt(ad_block, ciphertext, tag);
  neorv32_uart0_printf("Plaintext after processing: \n");

  print_crypto_array(plaintext);
  neorv32_uart0_printf("\n");

  free_crypto_array(pt_block);
  free_crypto_array(ad_block);
  free_crypto_array(key_block);
  free_crypto_array(nonce_block);
  free_crypto_array(ciphertext);
  free_crypto_array(plaintext);
  free_crypto_array(tag);
}