from re import M
import string
import cocotb
from cocotb.triggers import Timer, Edge, with_timeout
from random import randint
import logging
from typing import TYPE_CHECKING


# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs

def split(hexstring):
    hexstring = hexstring[2:]
    out_str = hexstring[0:16] + "  " + hexstring[16: 32] + "  " + hexstring[32: 48] + "  " + hexstring[48 : 64] + "  " + hexstring[64:80]
    return out_str

def parse_and_pad(hexstring : str):
    M = list((hexstring[0+i:16+i] for i in range(0, len(hexstring), 16)))

    print(M)

    for i in range(0, len(M)):
        new_str = ""
        old_str = M[i]

        old_str_length = len(old_str)
        for j in range(0, old_str_length, 2):
            new_str += old_str[old_str_length - 2 - j: old_str_length - j]
        M[i] = new_str

    byte_length = len(hexstring) // 2
    byte_length %= 8
    # Get length in bytes of last 64-bit word
    print(M)

    padded_word = ""
    if byte_length == 0:
        padded_word = "0000000000000001"
        M.append(padded_word)
    else:
        last = M[-1] # the last, incomplete word
        padded_word = last
        padded_word = "01" + padded_word
        for i in range(0, 8 - byte_length - 1):
            padded_word = "00" + padded_word
        M[-1] = padded_word
    
    print(M)
    return M

async def generate_clock(dut : copra_stubs.AsconHash256):

    """Generate clock pulses."""
    for _ in range(10000):
        dut.clk_i.value = 0
        await Timer(5, unit="ns")
        dut.clk_i.value = 1
        await Timer(5, unit="ns")

        

async def generate_log(dut : copra_stubs.AsconHash256):
    logger = logging.getLogger("my_testbench")
    logger.warning("This is an info message")

    curr_state = dut.curr_state.value

    while dut.finished_o.value != 1:
        await dut.clk_i.rising_edge

        if curr_state != dut.curr_state.value:
            curr_state = dut.curr_state.value
            logger.warning("STATE CHANGED!")


        if dut.start_core.value == 1:
            logger.warning("Starting core with: %s" % split(hex(dut.core_in.value)))

        if dut.core_finished.value == 1:
            logger.warning("Core finished with: %s" % split(hex(dut.core_out.value)))

async def generate_input(dut : copra_stubs.AsconHash256, hexstring : str):
    logger = logging.getLogger("my_testbench")
    M_list = parse_and_pad(hexstring)
    count = len(M_list)
    i = 0

    if count > 1:
        dut.m_i.value = int(M_list[i], 16)
        logger.warning("INPUT: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
        i += 1

        while dut.finished_o.value != 1:
            await dut.clk_i.rising_edge

            if dut.word_processed_o.value == 1:
                if i != count:
                    dut.m_i.value = int(M_list[i], 16)
                    logger.warning("INPUT: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
                    i += 1
                if i == count:
                    dut.word_left.value = 0
    else:
        logger.warning("INPUT else: " + M_list[i] + "   " + str(hex(int(M_list[i], 16))[2:]))
        dut.m_i.value = int(M_list[i], 16)
        dut.word_left.value = 0





async def test_for_hex(dut : copra_stubs.AsconHash256, hexstring):
    logger = logging.getLogger("my_testbench")
    dut.start_i.value = 0
    dut.reset_i.value = 1
    
    cocotb.start_soon(generate_clock(dut))
    
    await Timer(60, unit="ns")
    
    dut.reset_i.value = 0

    dut.start_i.value = 1
    dut.word_left.value = 1

    cocotb.start_soon(generate_input(dut, hexstring))
    #cocotb.start_soon(generate_log(dut))


    while dut.finished_o.value != 1:
        await Timer(10, unit="ns")

    logger.warning("Finished with: %s" % hex(dut.state_o.value)[2:])

    await Timer(20, unit="ns")

@cocotb.test()
async def test_ascon_hash(dut : copra_stubs.AsconHash256):
    #dut.m_i.value = int(0x0706050403020100)
    

    await test_for_hex(dut, "000102")
    await test_for_hex(dut, "00010203")
    await test_for_hex(dut, "0001020304")


    await test_for_hex(dut, "0001020304050607")
    await test_for_hex(dut, "000102030405060708")
    await test_for_hex(dut, "00010203040506070809")




