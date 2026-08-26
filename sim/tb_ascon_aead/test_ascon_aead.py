import string
import cocotb
from cocotb.triggers import Timer, Edge, with_timeout, First
from cocotb.clock import Clock
from random import randint
import logging
from typing import TYPE_CHECKING
from util.parseandpad import parse, pad, split320
from util.parsefile import parse_aead_encrypt_file, AeadEncrypt
from util.general import pad_zeroes, split, invert_bytes_per_word
from util.simuutil import generate_clock, generate_state_log
from reference.ascon import ascon_encrypt, ascon_decrypt, get_random_bytes
from random import randint

outp = ""
plen = 0

# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs


def input_lists(assoc_data: str, text: str):
    text_tuple = parse(text, 16)
    text_list = text_tuple[0]
    text_list[-1] = pad(text_list[-1], 16)
    for i in range(0, len(text_list)):
        text_list[i] = invert_bytes_per_word(text_list[i])
    last_word_len = text_tuple[1]

    ad_tuple = parse(assoc_data, 16)
    assoc_data_list = ad_tuple[0]

    if len(assoc_data_list) > 0:
        assoc_data_list[-1] = pad(assoc_data_list[-1], 16)
    for i in range(0, len(assoc_data_list)):
        assoc_data_list[i] = invert_bytes_per_word(assoc_data_list[i])

    count_assoc_data = 0
    count_text = 0

    if assoc_data != "":
        count_assoc_data = len(assoc_data_list)
    if text != "":
        count_text = len(text_list)

    return text_list, assoc_data_list, count_text, count_assoc_data, last_word_len


async def generate_input(dut: copra_stubs.AsconAed, key, nonce, pt, ad):
    global plen
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    dut.input_ready_i.value = 1
    logger.debug("Key: " + key)
    logger.debug("Nonce: " + nonce)
    logger.debug("Pt: " + pt)
    logger.debug("Ad: " + ad)

    i_associated_data = 0
    i_text = 0

    key = invert_bytes_per_word(key)
    nonce = invert_bytes_per_word(nonce)

    dut.key_i.value = int(key, 16)
    dut.nonce_i.value = int(nonce, 16)

    text_list, assoc_data_list, count_text, count_assoc_data, p_last_word_len = (
        input_lists(ad, pt)
    )

    dut.plaintext_word_left_i.value = 1
    plen = 128

    logger.debug(f"Associated data: {assoc_data_list}")
    logger.debug(f"Associated len: {count_assoc_data}")
    logger.debug(f"Plaintext data: {text_list}")
    logger.debug(f"Plaintext len: {count_text}")

    if count_assoc_data == 0:
        dut.associated_data_word_left_i.value = 0
        dut.text_i.value = int(text_list[0], 16)
    else:
        dut.associated_data_word_left_i.value = 1
        dut.assoc_data_i.value = int(assoc_data_list[0], 16)
        logger.debug("Associated data input: " + assoc_data_list[i_associated_data])

    if count_text <= 1:
        plen = p_last_word_len
        dut.text_i.value = int(text_list[0], 16)
        dut.plaintext_word_left_i.value = 0

    # logger.warning(f"plen: {plen}   lastwordlen {p_last_word_len}")

    await dut.start_i.rising_edge
    
    while dut.finished_o.value != 1:
        await dut.core_finished.rising_edge
        dut.text_len_i.value = plen
        logger.debug(
            f"Count_a: {count_assoc_data} i_a: {i_associated_data}  Count_p: {count_text} i_p: {i_text} "
        )

        # More than 1 64-bit word total
        if count_assoc_data > 0 and i_associated_data < count_assoc_data:
            dut.associated_data_word_left_i.value = 1
            dut.plaintext_word_left_i.value = 1
            dut.assoc_data_i.value = int(assoc_data_list[i_associated_data], 16)
            i_associated_data += 1

        elif i_text < count_text:
            if i_text == count_text - 1:
                plen = p_last_word_len
                dut.text_len_i.value = plen
                dut.plaintext_word_left_i.value = 0
            else:
                dut.plaintext_word_left_i.value = 1

            dut.associated_data_word_left_i.value = 0
            dut.text_i.value = int(text_list[i_text], 16)
            i_text += 1
        else:
            dut.associated_data_word_left_i.value = 0
            dut.plaintext_word_left_i.value = 0
        await dut.clk_i.rising_edge


async def log_core_output(dut: copra_stubs.AsconAed):
    global outp
    global plen
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    logger.debug("Output: started")

    while dut.finished_o.value != 1:
        await dut.text_ready_o.rising_edge
        output = invert_bytes_per_word(hex(dut.text_o.value)[2:].zfill(32))[
            0 : (int(plen) // 4)
        ]
        logger.debug("Output: " + "   " + output + "  " + str(plen))
        outp += invert_bytes_per_word(output)


async def log_tag(dut: copra_stubs.AsconAed):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    await dut.finished_o.rising_edge


async def log_core(dut: copra_stubs.AsconAed):
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    while dut.finished_o.value != 1:
        await dut.clk_i.rising_edge

        try:
            logger.debug(
                "Const: "
                + "   "
                + split320(hex(dut.ascon_core_inst.constant_addition.value)[2:])
            )
            logger.debug(
                "Nonlinear: "
                + "   "
                + split320(hex(dut.ascon_core_inst.nonlinear_substition.value)[2:])
            )
            logger.debug(
                "Linear: "
                + "   "
                + split320(hex(dut.ascon_core_inst.linear_diffusion.value)[2:])
            )
        except:
            pass


async def log_core_input(dut: copra_stubs.AsconAed):
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    while dut.finished_o.value != 1:
        await dut.start_core.rising_edge
        # if debug: logger.info("Core input: " + "   " + split(pad_zeroes(hex(dut.core_in.value))))
        logger.debug(
            "Core input: "
            + "   "
            + split(pad_zeroes(hex(dut.core_in.value)[2:], 80))
        )
        logger.debug("Plen " + "   " + str(plen))

        await dut.core_finished.rising_edge
        logger.debug(
            "Core output: "
            + "   "
            + split(pad_zeroes(hex(dut.core_out.value)[2:], 80))
        )


async def test_for_hex(dut: copra_stubs.AsconAed, key, nonce, pt, ad, ciphertext):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    outp = ""
    dut.encrypt_mode_i.value = 1
    dut.start_i.value = 0
    dut.reset_i.value = 1
    await Timer(60, unit="ns")

    dut.reset_i.value = 0

    dut.start_i.value = 1

    encryption_task = cocotb.start_soon(generate_input(dut, key, nonce, pt, ad))

    await Timer(60, unit="ns")
    dut.start_i.value = 0

    # await Timer(1000, unit="ns")
    # return

    while dut.finished_o.value != 1:
        await Timer(10, unit="ns")
    correct_result = ciphertext.lower()

    logger.debug(f"Before invert: {outp}")
    output = invert_bytes_per_word(outp)

    raw_tag_hex = hex(dut.tag_o.value)[2:].zfill(32)
    logger.debug(f"Before invert: {raw_tag_hex}")
    tag = invert_bytes_per_word(raw_tag_hex)

    actual_result = output + tag

    logger.debug(f"Finished with tag:  {tag}")

    logger.debug("Finished with: %s" % actual_result)
    logger.debug("Correct solution: " + correct_result)

    assert actual_result == correct_result, "Encryption incorrect"

    # if debug: logger.info("Finished with: %s" % output)
    # if debug: logger.info("Tag: " + tag)

    # return

    logger.debug(f"Finished encryption test starting decryption")
    encryption_task.cancel()
    # cocotb.start_soon(log_core_output(dut))
    # cocotb.start_soon(log_core(dut))
    # cocotb.start_soon(log_core_input(dut))

    outp = ""

    dut.start_i.value = 0
    dut.reset_i.value = 1
    dut.encrypt_mode_i.value = 0

    await Timer(60, unit="ns")

    dut.reset_i.value = 0

    text = ciphertext[:-32]
    correct_tag = ciphertext[-32:]

    logger.debug(f"Text {ciphertext}   {text}")

    decryption_task = cocotb.start_soon(generate_input(dut, key, nonce, text, ad))
    dut.start_i.value = 1

    if dut.finished_o.value != 1:
        await dut.finished_o.rising_edge

    dut.start_i.value = 0

    logger.debug(f"ct: {ciphertext}")

    correct_result = ciphertext.lower()

    # if debug: logger.info(f"Finished with: {output} :  {tag}")

    output = invert_bytes_per_word(outp)

    raw_tag_hex = hex(dut.tag_o.value)[2:].zfill(32)
    tag = invert_bytes_per_word(raw_tag_hex)

    assert tag == correct_tag, "Incorrect tag!"
    assert output == pt, "Incorrect plaintext"

    await Timer(20, unit="ns")
    decryption_task.cancel()
    return


def setup_testbench(dut: copra_stubs.AsconAed):
    dut.encrypt_mode_i.value = 1
    cocotb.start_soon(generate_clock(dut))
    cocotb.start_soon(log_core_output(dut))
    cocotb.start_soon(log_core(dut))
    cocotb.start_soon(log_core_input(dut))


@cocotb.test()
async def test_ascon_aead_kat(dut: copra_stubs.AsconAed):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    setup_testbench(dut)

    KAT_dictionary = parse_aead_encrypt_file("LWC_AEAD_KAT_128_128.txt")

    count = 0
    TESTS_TO_RUN = -1  # -1 to perform all tests

    for input_data in KAT_dictionary.keys():
        logger.info("Starting round: %s" % count)

        count += 1
        obj = input_data
        await test_for_hex(
            dut, obj.key, obj.nonce, obj.pt, obj.ad, KAT_dictionary[input_data]
        )

        outp = ""
        if count == TESTS_TO_RUN:
            break


@cocotb.test()
async def test_ascon_aead_random(dut: copra_stubs.AsconAed):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    setup_testbench(dut)

    KAT_dictionary = dict()
    count = 0

    for i in range(250):
        key = get_random_bytes(16)
        nonce = get_random_bytes(16)

        ad = get_random_bytes(randint(0, 24))
        pt = get_random_bytes(randint(0, 24))

        ciphertext = ascon_encrypt(key, nonce, ad, pt, "Ascon-AEAD128")

        obj = AeadEncrypt(key.hex(), nonce.hex(), pt.hex(), ad.hex())
        KAT_dictionary[obj] = ciphertext.hex()

    for input_data in KAT_dictionary.keys():
        logger.info("Starting round: %s" % count)

        obj = input_data
        await test_for_hex(
            dut, obj.key, obj.nonce, obj.pt, obj.ad, KAT_dictionary[input_data]
        )

        outp = ""
        count += 1


@cocotb.test()
async def test_ascon_aead_extra_length(dut: copra_stubs.AsconAed):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    setup_testbench(dut)

    KAT_dictionary = dict()
    count = 0

    for i in range(100):
        key = get_random_bytes(16)
        nonce = get_random_bytes(16)

        ad = get_random_bytes(randint(25, 250))
        pt = get_random_bytes(randint(25, 250))

        ciphertext = ascon_encrypt(key, nonce, ad, pt, "Ascon-AEAD128")

        obj = AeadEncrypt(key.hex(), nonce.hex(), pt.hex(), ad.hex())
        KAT_dictionary[obj] = ciphertext.hex()

    for input_data in KAT_dictionary.keys():
        logger.info("Starting round: %s" % count)

        obj = input_data
        await test_for_hex(
            dut, obj.key, obj.nonce, obj.pt, obj.ad, KAT_dictionary[input_data]
        )

        outp = ""
        count += 1