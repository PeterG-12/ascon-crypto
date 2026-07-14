from re import M
from sre_compile import AT
import string
import cocotb
from cocotb.triggers import Timer, Edge, with_timeout
from cocotb.clock import Clock
from random import randint
import logging
from typing import TYPE_CHECKING
from util.parseandpad import parse, pad, split320
from util.parsefile import parse_file
from util.general import pad_zeroes, split, invert_bytes_per_word
from util.simuutil import generate_clock, generate_state_log

debug = True
debugPerm = False

# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs

async def generate_input(dut : copra_stubs.AsconAed):
    logger = logging.getLogger("my_testbench")

    

    key = "000102030405060708090A0B0C0D0E0F"
    nonce = "000102030405060708090A0B0C0D0E0F"

    key = invert_bytes_per_word(key)
    nonce = invert_bytes_per_word(nonce)

    dut.k_i.value = int(key, 16)
    dut.n_i.value = int(nonce, 16)



    pt = "000102030405060708090A0B0C0D0E0F101112131415161718"
    ad = "000102030405060708090A0B0C0D0E0F10111213141516171819"
        
    p_last_word_len = 128
    Ptup = parse(pt, 16)
    P_list = Ptup[0]
    P_list[-1] = pad(P_list[-1], 16)
    for i in range(0, len(P_list)):
        P_list[i] = invert_bytes_per_word(P_list[i])
    p_last_word_len = Ptup[1]

    Atup = parse(ad, 16)
    A_list = Atup[0]
    print(A_list)

    A_list[-1] = pad(A_list[-1], 16)
    for i in range(0, len(A_list)):
        A_list[i] = invert_bytes_per_word(A_list[i])
    print(A_list)

    count_a = len(A_list)
    count_p = len(P_list)
    i_a = 0
    i_p = 0

    dut.plaintext_word_left_i.value = 1

    dut.p_len_i.value = 128

    if count_a == 0:
        dut.associated_data_word_left_i.value = 0
        dut.p_i.value = int(P_list[0], 16)
        i_p = 1
    else:
        dut.associated_data_word_left_i.value = 1
        dut.a_i.value = int(A_list[0], 16)
        if debug: logger.warning("Associated data input: " + A_list[i_a])

        i_a = 1

    

    await dut.start_i.rising_edge

    


    while dut.finished_o.value != 1:
        if dut.word_processed_o.value == 1:
            # More than 1 64-bit word total
            if count_a > 0 and i_a < count_a:
                dut.associated_data_word_left_i.value = 1
                dut.plaintext_word_left_i.value = 1
                dut.a_i.value = int(A_list[i_a], 16)
                if debug: logger.warning("Associated data input: " + A_list[i_a])

                i_a += 1

            elif count_p > 0 and i_p < count_p:
                if i_p == count_p - 1:
                    if debug: logger.warning("LASTLEN input: " + str(p_last_word_len))
                    dut.p_len_i.value = p_last_word_len
                    dut.plaintext_word_left_i.value = 0
                    #if debug: logger.warning("Plaintext input: " + P_list[i_p] + "Last: " + str(dut.plaintext_word_left_i.value) + "  " + str(i_p) + "  " + str(count_p))
                else:
                    dut.plaintext_word_left_i.value = 1


                dut.associated_data_word_left_i.value = 0
                dut.p_i.value = int(P_list[i_p], 16)
                if debug: logger.warning("Plaintext input: " + P_list[i_p])
                
                i_p += 1



        await dut.clk_i.rising_edge

outp = ""
async def log_core_output(dut : copra_stubs.AsconAed):
    global outp
    logger = logging.getLogger("my_testbench")
    
    while dut.finished_o.value != 1:
        await dut.c_ready_o.rising_edge
        output = invert_bytes_per_word(hex(dut.c_o.value)[2:])[0:(int(dut.p_len_i.value) // 4)]
        if debug: logger.warning("Output: " + "   " + output)
        outp += invert_bytes_per_word(output)


async def log_tag(dut : copra_stubs.AsconAed):
    global outp
    logger = logging.getLogger("my_testbench")
    
    await dut.finished_o.rising_edge


async def log_core(dut : copra_stubs.AsconAed):
    logger = logging.getLogger("my_testbench")
    
    while dut.finished_o.value != 1:
        await dut.clk_i.rising_edge

        if dut.ascon_core_inst.curr_state.value == "00000001":
            try:
                if debugPerm: logger.warning("Const: " + "   " + split320(hex(dut.ascon_core_inst.constant_addition.value)[2:]))
                if debugPerm: logger.warning("Nonlinear: " + "   " + split320(hex(dut.ascon_core_inst.nonlinear_substition.value)[2:]))
                if debugPerm: logger.warning("Linear: " + "   " + split320(hex(dut.ascon_core_inst.linear_diffusion.value)[2:]))
            except:
                pass



async def log_core_input(dut : copra_stubs.AsconAed):
    logger = logging.getLogger("my_testbench")
    
    while dut.finished_o.value != 1:
        await dut.start_core.rising_edge
        #if debug: logger.warning("Core input: " + "   " + split(pad_zeroes(hex(dut.core_in.value))))
        if debug: logger.warning("Core input: " + "   " + split(pad_zeroes(hex(dut.core_in.value)[2:], 80)))
        if debug: logger.warning("Debug clock at: " + str(int(str(dut.debug_clock.value), 2)))


        await dut.core_finished.rising_edge
        if debug: logger.warning("Core output: " + "   " + split(pad_zeroes(hex(dut.core_out.value)[2:], 80)))
        if debug: logger.warning("Debug clock at: " + str(int(str(dut.debug_clock.value), 2)))


        


async def test_for_hex(dut : copra_stubs.AsconAed, hexstring, correct_result):
    logger = logging.getLogger("my_testbench")
    dut.start_i.value = 0
    dut.reset_i.value = 1
        
    await Timer(60, unit="ns")
    
    dut.reset_i.value = 0

    dut.start_i.value = 1
    dut.word_left_i.value = 1

    cocotb.start_soon(generate_input(dut, hexstring))

    await Timer(60, unit="ns")
    dut.start_i.value = 0
    
    while dut.finished_o.value != 1:
        await Timer(10, unit="ns")

    correct_result = pad_zeroes(correct_result)
    actual_result = pad_zeroes(hex(dut.state_o.value)[2:])

    if debug: logger.warning("Finished with: %s" % actual_result)
    if debug: logger.warning("Correct solution: " + correct_result)

    assert actual_result == correct_result
    
    await Timer(20, unit="ns")

@cocotb.test()
async def test_ascon_aead(dut : copra_stubs.AsconAed):
    #dut.m_i.value = int(0x0706050403020100)
    logger = logging.getLogger("my_testbench")
    
    cocotb.start_soon(generate_clock(dut))
    cocotb.start_soon(log_core_output(dut))
    cocotb.start_soon(log_core_input(dut))
    cocotb.start_soon(log_core(dut))

    cocotb.start_soon(log_tag(dut))

    dut.reset_i.value = 0

    cocotb.start_soon(generate_input(dut))
    dut.start_i.value = 1
    await Timer(40, unit="ns")
    dut.start_i.value = 0


    await Timer(60000, unit="ns")
    if debug: logger.warning("Finished with: %s" % invert_bytes_per_word(outp))
    if debug: logger.warning("Tag: " + invert_bytes_per_word(str(hex(dut.t_o.value))[2:]))


