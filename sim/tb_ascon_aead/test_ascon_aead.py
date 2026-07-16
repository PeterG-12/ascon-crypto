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
from util.parsefile import parse_aead_encrypt_file
from util.general import pad_zeroes, split, invert_bytes_per_word
from util.simuutil import generate_clock, generate_state_log

debugValue = False
debug = False
debugPerm = False

# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs




def set_val(val):
    #print("SETTING TO %s" % val)
    return val

async def generate_input(dut : copra_stubs.AsconAed, key, nonce, pt, ad):
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    if debugValue: logger.info("Key: " + key)
    if debugValue: logger.info("Nonce: " + nonce)
    if debugValue: logger.info("Pt: " + pt)
    if debugValue: logger.info("Ad: " + ad)


    count_a = 0
    count_p = 0
    i_a = 0
    i_p = 0

    #key = "000102030405060708090A0B0C0D0E0F"
    #nonce = "000102030405060708090A0B0C0D0E0F"
    #pt = "000102030405060708090A0B0C0D0E0F101112131415161718"
    #ad = "000102030405060708090A0B0C0D0E0F10111213141516171819"


    key = invert_bytes_per_word(key)
    nonce = invert_bytes_per_word(nonce)
    
    dut.k_i.value = int(key, 16)
    dut.n_i.value = int(nonce, 16)



    
        
    p_last_word_len = 128
    Ptup = parse(pt, 16)
    P_list = Ptup[0]
    P_list[-1] = pad(P_list[-1], 16)
    for i in range(0, len(P_list)):
        P_list[i] = invert_bytes_per_word(P_list[i])
    p_last_word_len = Ptup[1]

    Atup = parse(ad, 16)
    A_list = Atup[0]
    #print("Alist: ", A_list)

    if len(A_list) > 0:
        A_list[-1] = pad(A_list[-1], 16)
    for i in range(0, len(A_list)):
        A_list[i] = invert_bytes_per_word(A_list[i])
    #print("Alist 2: ", A_list)




    if ad != "":
        count_a = len(A_list)
    if pt != "":
        count_p = len(P_list)
    

    dut.plaintext_word_left_i.value = set_val(1)
    i_p = 0
    dut.p_len_i.value = 128


    if debug: logger.info(f"Associated data: {A_list}")
    if debug: logger.info(f"Plaintext data: {P_list}")

    if count_a == 0:
        dut.associated_data_word_left_i.value = 0
        dut.p_i.value = int(P_list[0], 16)
    else:
        dut.associated_data_word_left_i.value = 1
        dut.a_i.value = int(A_list[0], 16)
        if debug: logger.info("Associated data input: " + A_list[i_a])

    if count_p == 0:
        dut.p_len_i.value = p_last_word_len
        dut.plaintext_word_left_i.value = set_val(0)
        dut.p_i.value = int(P_list[0], 16)
        

    if count_p == 1:
        dut.p_i.value = int(P_list[0], 16)
        dut.p_len_i.value = p_last_word_len
        dut.plaintext_word_left_i.value = set_val(0)

    await dut.start_i.rising_edge

    


    while dut.finished_o.value != 1:
        await dut.core_finished.rising_edge
        if debug: logger.info(f"Count_a: {count_a} i_a: {i_a}  Count_p: {count_p} i_p: {i_p} ")

        # More than 1 64-bit word total
        if count_a > 0 and i_a < count_a:
            dut.associated_data_word_left_i.value = 1
            dut.plaintext_word_left_i.value = set_val(1)
            dut.a_i.value = int(A_list[i_a], 16)
            if debug: logger.info("Associated data input: " + A_list[i_a])
            if debug: logger.info("BRANCH 1 TAKEN ")

            i_a += 1

        elif count_p >= 0 and i_p < count_p:
            if i_p == count_p - 1:
                if debug: logger.info("BRANCH 2 TAKEN ")

                if debug: logger.info("LASTLEN input: " + str(p_last_word_len))
                dut.p_len_i.value = p_last_word_len
                dut.plaintext_word_left_i.value = set_val(0)
                if debug: logger.info("Plaintext input: " + P_list[i_p] + "Last: " + str(dut.plaintext_word_left_i.value) + "  " + str(i_p) + "  " + str(count_p))
            else:
                if debug: logger.info("BRANCH 3 TAKEN ")

                dut.plaintext_word_left_i.value = set_val(1)

            if debug: logger.info("BRANCH 4* TAKEN ")

            dut.associated_data_word_left_i.value = 0
            dut.p_i.value = int(P_list[i_p], 16)
            if debug: logger.info("Plaintext input: " + P_list[i_p])
            
            i_p += 1

        else:
            if debug: logger.info("BRANCH 5 TAKEN ")

            dut.associated_data_word_left_i.value = 0
            dut.plaintext_word_left_i.value = set_val(0)


        await dut.clk_i.rising_edge

outp = ""
async def log_core_output(dut : copra_stubs.AsconAed):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    if debug: logger.info("Output: started")
    
    while dut.finished_o.value != 1:
        await dut.c_ready_o.rising_edge
        output = invert_bytes_per_word(hex(dut.c_o.value)[2:])[0:(int(dut.p_len_i.value) // 4)]
        if debug: logger.info("Output: " + "   " + output + "  " + str(dut.p_len_i.value))
        outp += invert_bytes_per_word(output)


async def log_tag(dut : copra_stubs.AsconAed):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    
    await dut.finished_o.rising_edge


async def log_core(dut : copra_stubs.AsconAed):
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    
    while dut.finished_o.value != 1:
        await dut.clk_i.rising_edge

        if dut.ascon_core_inst.curr_state.value == "00000001":
            try:
                if debugPerm: logger.info("Const: " + "   " + split320(hex(dut.ascon_core_inst.constant_addition.value)[2:]))
                if debugPerm: logger.info("Nonlinear: " + "   " + split320(hex(dut.ascon_core_inst.nonlinear_substition.value)[2:]))
                if debugPerm: logger.info("Linear: " + "   " + split320(hex(dut.ascon_core_inst.linear_diffusion.value)[2:]))
            except:
                pass



async def log_core_input(dut : copra_stubs.AsconAed):
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    
    while dut.finished_o.value != 1:
        await dut.start_core.rising_edge
        #if debug: logger.info("Core input: " + "   " + split(pad_zeroes(hex(dut.core_in.value))))
        if debug: logger.info("Core input: " + "   " + split(pad_zeroes(hex(dut.core_in.value)[2:], 80)))
        if debug: logger.info("Debug clock at: " + str(int(str(dut.debug_clock.value), 2)))


        await dut.core_finished.rising_edge
        if debug: logger.info("Core output: " + "   " + split(pad_zeroes(hex(dut.core_out.value)[2:], 80)))
        if debug: logger.info("Debug clock at: " + str(int(str(dut.debug_clock.value), 2)))


        


async def test_for_hex(dut : copra_stubs.AsconAed, key, nonce, pt, ad, ciphertext):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

   
    dut.start_i.value = 0
    dut.reset_i.value = 1
        
    await Timer(60, unit="ns")
    
    dut.reset_i.value = 0

    dut.start_i.value = 1

    cocotb.start_soon(generate_input(dut, key, nonce, pt, ad))

    await Timer(60, unit="ns")
    dut.start_i.value = 0
    
    #await Timer(1000, unit="ns")
    #return
    
    while dut.finished_o.value != 1:
        await Timer(10, unit="ns")
    correct_result = ciphertext.lower()

    #if debug: logger.info(f"Finished with: {output} :  {tag}")


    output = invert_bytes_per_word(outp)

    raw_tag_hex = hex(dut.t_o.value)[2:].zfill(32)
    tag = invert_bytes_per_word(raw_tag_hex)

    actual_result = output + tag

    if debug: logger.info(f"Finished with tag:  {tag}")

    if debug: logger.info("Finished with: %s" % actual_result)
    if debug: logger.info("Correct solution: " + correct_result)

    assert actual_result == correct_result
    
    #if debug: logger.info("Finished with: %s" % output)
    #if debug: logger.info("Tag: " + tag)

    outp = ""
    await Timer(20, unit="ns")
    return

@cocotb.test()
async def test_ascon_aead(dut : copra_stubs.AsconAed):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    
    cocotb.start_soon(generate_clock(dut))
    cocotb.start_soon(log_core_output(dut))
    cocotb.start_soon(log_core(dut))
    cocotb.start_soon(log_core_input(dut))

    KAT_dictionary = parse_aead_encrypt_file("LWC_AEAD_KAT_128_128.txt")
    
    count = 0
    TESTS_TO_RUN = -1 # -1 to perform all tests
    cocotb.start_soon(generate_clock(dut))


    for input_data in KAT_dictionary.keys():
        logger.info("Starting round: %s" % count)
        
        count += 1
        obj = input_data
        await test_for_hex(dut, obj.key, obj.nonce, obj.pt, obj.ad, KAT_dictionary[input_data])
        
        outp = ""
        if count == TESTS_TO_RUN:
            break
