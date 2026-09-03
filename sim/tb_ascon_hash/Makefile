export PYTHONPATH := $(PWD)/..:$(PYTHONPATH)

# Simulator settings
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

EXTRA_ARGS += --std=08
COMPILE_ARGS += --std=08

#Stub generation
# Python test module name (Runs Copra first, then your test)
COCOTB_TEST_MODULES = copra.integration.autostub,test_ascon_hash

VHDL_SOURCES += $(wildcard ../../AsconCrypto.srcs/sources_1/new/*.vhd)
TOPLEVEL = ascon_hash256


#SIM_ARGS += --wave=wave.ghw
# Include cocotb make rules
include $(shell cocotb-config --makefiles)/Makefile.sim