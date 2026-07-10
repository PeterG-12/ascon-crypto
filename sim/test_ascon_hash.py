from re import M
import string
import cocotb
from cocotb.triggers import Timer, Edge, with_timeout
from random import randint
import logging
from typing import TYPE_CHECKING
from util.parseandpad import parse_and_pad
from util.parsefile import parse_file


debug = False

# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs

def split(hexstring):
    hexstring = hexstring[2:]
    out_str = hexstring[0:16] + "  " + hexstring[16: 32] + "  " + hexstring[32: 48] + "  " + hexstring[48 : 64] + "  " + hexstring[64:80]
    return out_str

def pad_zeroes(hexstring):
    length = len(hexstring)
    out_string = hexstring
    while length < 64:
        out_string = "0" + out_string
        length += 1
        
    return out_string

async def generate_clock(dut : copra_stubs.AsconHash256):

    """Generate clock pulses."""
    for _ in range(10000):
        dut.clk_i.value = 0
        await Timer(5, unit="ns")
        dut.clk_i.value = 1
        await Timer(5, unit="ns")

        

async def generate_log(dut : copra_stubs.AsconHash256):
    logger = logging.getLogger("my_testbench")
    if debug: logger.warning("This is an info message")

    curr_state = dut.curr_state.value

    while dut.finished_o.value != 1:
        await dut.clk_i.rising_edge

        if curr_state != dut.curr_state.value:
            curr_state = dut.curr_state.value
            if debug: logger.warning("STATE CHANGED!")


        if dut.start_core.value == 1:
            if debug: logger.warning("Starting core with: %s" % split(hex(dut.core_in.value)))

        if dut.core_finished.value == 1:
            if debug: logger.warning("Core finished with: %s" % split(hex(dut.core_out.value)))

async def generate_input(dut : copra_stubs.AsconHash256, hexstring : str):
    logger = logging.getLogger("my_testbench")
    M_list = parse_and_pad(hexstring)
    count = len(M_list)
    i = 0

    # More than 1 64-bit word total
    if count > 1:
        dut.m_i.value = int(M_list[i], 16)
        if debug: logger.warning("INPUT: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
        i += 1

        while dut.finished_o.value != 1:
            await dut.clk_i.rising_edge

            if dut.word_processed_o.value == 1:
                if i != count:
                    dut.m_i.value = int(M_list[i], 16)
                    if debug: logger.warning("Input: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
                    i += 1
                if i == count:
                    dut.word_left.value = 0
    #Exactly 1 64-bit word
    else:
        if debug: logger.warning("Input: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
        dut.m_i.value = int(M_list[i], 16)
        dut.word_left.value = 0





async def test_for_hex(dut : copra_stubs.AsconHash256, hexstring, correct_result):
    logger = logging.getLogger("my_testbench")
    dut.start_i.value = 0
    dut.reset_i.value = 1
    
    cocotb.start_soon(generate_clock(dut))
    
    await Timer(60, unit="ns")
    
    dut.reset_i.value = 0

    dut.start_i.value = 1
    dut.word_left.value = 1

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
    #dut.m_i.value = int(0x0706050403020100)
    logger = logging.getLogger("my_testbench")
    

    KAT_dictionary = parse_file("LWC_HASH_KAT_128_256.txt")

    count = 0
    for key in KAT_dictionary.keys():
        count += 1
        await test_for_hex(dut, key, KAT_dictionary[key])
        if debug: logger.warning("Correct solution: " + KAT_dictionary[key])
        
    # Possibility for performing individual checks

    #await test_for_hex(dut, "000102")
    #await test_for_hex(dut, "00010203")
    #await test_for_hex(dut, "0001020304")


    #await test_for_hex(dut, "0001020304050607")
    #await test_for_hex(dut, "000102030405060708")
    #await test_for_hex(dut, "00010203040506070809")




