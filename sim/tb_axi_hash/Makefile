export PYTHONPATH := $(PWD)/..:$(PYTHONPATH)

# Simulator settings
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

EXTRA_ARGS += --std=08
COMPILE_ARGS += --std=08
EXTRA_ARGS += -Wno-hide


#Stub generation
# Python test module name (Runs Copra first, then your test)
COCOTB_TEST_MODULES = copra.integration.autostub,test_ascon_aead_axi

VHDL_SOURCES += $(wildcard ../../rtl/*.vhd)
VHDL_SOURCES += $(wildcard ../../rtl/axi/*.vhd)
TOPLEVEL = asconaead128

#VHDL_SOURCES += $(PWD)/vhdl/*.vhd
# Top-level entity name

SIM_ARGS += --wave=wave.ghw
# Include cocotb make rules
include $(shell cocotb-config --makefiles)/Makefile.sim