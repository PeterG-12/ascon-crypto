from re import M
import string
import cocotb
from cocotb.triggers import Timer, Edge, with_timeout
from cocotb.clock import Clock
from random import randint
import logging
from typing import TYPE_CHECKING
from util.parseandpad import parse_and_pad
from util.parsefile import parse_hash_file
from util.general import pad_zeroes
from util.simuutil import generate_clock, generate_state_log

debug = False

# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs

async def generate_input(dut : copra_stubs.AsconHash256, hexstring : str):
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    Mtup : tuple = parse_and_pad(hexstring)
    M_list = Mtup[0]
    count = len(M_list)
    i = 0

    # More than 1 64-bit word total
    if count > 1:
        dut.m_i.value = int(M_list[i], 16)
        if debug: logger.warning("Input: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
        i += 1

        while dut.finished_o.value != 1:
            await dut.clk_i.rising_edge

            if dut.word_processed_o.value == 1:
                if i != count:
                    dut.m_i.value = int(M_list[i], 16)
                    if debug: logger.warning("Input: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
                    i += 1
                if i == count:
                    dut.word_left_i.value = 0
    #Exactly 1 64-bit word
    else:
        if debug: logger.warning("Input: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
        dut.m_i.value = int(M_list[i], 16)
        dut.word_left_i.value = 0

async def test_for_hex(dut : copra_stubs.AsconHash256, hexstring, correct_result):
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    dut.start_i.value = 0
    dut.reset_i.value = 1
        
    await Timer(60, unit="ns")
    
    dut.reset_i.value = 0

    dut.start_i.value = 1
    dut.word_left_i.value = 1

    cocotb.start_soon(generate_input(dut, hexstring))


    while dut.finished_o.value != 1:
        await Timer(10, unit="ns")

    correct_result = pad_zeroes(correct_result)
    actual_result = pad_zeroes(hex(dut.state_o.value)[2:])

    if debug: logger.warning("Finished with: %s" % actual_result)
    if debug: logger.warning("Correct solution: " + correct_result)

    assert actual_result == correct_result
    
    await Timer(20, unit="ns")

@cocotb.test()
async def test_ascon_hash(dut : copra_stubs.AsconHash256):
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    

    KAT_dictionary = parse_hash_file("LWC_HASH_KAT_128_256.txt")

    count = 0
    TESTS_TO_RUN = -1 # -1 to perform all tests
    cocotb.start_soon(generate_clock(dut))

    for key in KAT_dictionary.keys():
        logger.info("Starting round: %s " % count)
        count += 1
        await test_for_hex(dut, key, KAT_dictionary[key])
        if debug: logger.warning("Correct solution: " + KAT_dictionary[key])

        if count == TESTS_TO_RUN:
            break
        



