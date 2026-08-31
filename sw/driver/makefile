# Application makefile.
# Use this makefile to configure all relevant CPU / compiler options.

-include config.mk

# Override the default CPU ISA
MARCH = rv32i_zicsr_zifencei

# Override the default RISC-V GCC prefix
RISCV_PREFIX ?= riscv64-elf-

# Override default optimization goal
EFFORT = -Os

# Add extended debug symbols
USER_FLAGS += -ggdb -gdwarf-3

 
# Adjust processor IMEM size
USER_FLAGS += -Wl,--defsym,__neorv32_rom_size=32k

# Adjust processor DMEM size
USER_FLAGS += -Wl,--defsym,__neorv32_ram_size=16k

# Adjust maximum heap size
USER_FLAGS += -Wl,--defsym,__neorv32_heap_size=1k


USER_FLAGS += --specs=nano.specs

# Additional sources
APP_SRC += $(wildcard src/*.c)
APP_INC += -I include/
APP_INC += -I src/

# Set path to NEORV32 root directory
NEORV32_HOME ?= ../../..

# Include the main NEORV32 makefile
include $(NEORV32_HOME)/sw/common/common.mk
