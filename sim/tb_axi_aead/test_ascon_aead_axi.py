from __future__ import annotations
import re

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from util.axi_driver import *
from util.parsefile import parse_aead_encrypt_file
import logging
from cocotb.triggers import Timer
from typing import TYPE_CHECKING
from cocotb.utils import get_sim_time
from reference.ascon import ascon_encrypt, ascon_decrypt, get_random_bytes
from util.parsefile import parse_aead_encrypt_file, AeadEncrypt
from random import randint
from cocotbext.axi import AxiLiteBus, AxiLiteMaster
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor

if TYPE_CHECKING:
    import copra_stubs


outp = ""

async def generate_input(
    dut: copra_stubs.Asconaead128,
    key,
    nonce,
    pt,
    ad,
    driver: AxiAsconDriver,
    encrypt_mode,
):
    plen = 0
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    logger.debug("Started generate input")

    logger.debug("Key: " + key)
    logger.debug("Nonce: " + nonce)
    logger.debug("Pt: " + pt)
    logger.debug("Ad: " + ad)

    i_associated_data = 0
    i_text = 0

    key = bytes.fromhex(key)
    nonce = bytes.fromhex(nonce)

    await driver.write_128(ADDR_KEY, key)
    await driver.write_128(ADDR_NONCE, nonce)

    text_list, assoc_data_list, count_text, count_assoc_data, p_last_word_len = (
        input_lists(ad, pt)
    )

    control = ControlSignals()

    control.text_word_left = 1
    control.encrypt_mode = encrypt_mode

    await write_control_register(driver, control)
    logger.debug("Control register written")

    plen = 128

    logger.debug(f"Associated data: {assoc_data_list}")
    logger.debug(f"Associated len: {count_assoc_data}")
    logger.debug(f"Plaintext data: {text_list}")
    logger.debug(f"Plaintext len: {count_text}")

    if count_assoc_data == 0:
        control.associated_data_word_left = 0
    else:
        control.associated_data_word_left = 1
        await driver.write_128(ADDR_ASSOC_DATA, assoc_data_list[0])
        #logger.debug("Associated data input: " + assoc_data_list[i_associated_data])

    if count_text <= 1:
        plen = p_last_word_len
        control.text_word_left = 0
        await driver.write_128(ADDR_TEXT_IN, text_list[0])

    #await write_control_register(driver, control)

    control.start = 1
    control.input_ready = 1
    control.finish_rdy_en = 1
    control.word_rdy_en = 1
    await write_control_register(driver, control)
    control.input_ready = 0

    finished = 0
    finished, text_ready, word_processed = await read_status_register(driver)

    control.start = 0
    await write_control_register(driver, control)

    break_finished = 0

    while finished != 1:
        
        if USE_INTERRUPTS:
            if dut.module_interrupt_o.value == 0:
                await RisingEdge(dut.module_interrupt_o)
            word_int = await read_word_interrupt_status(driver)

            if word_int:
                await clear_word_interrupt(driver)

            finished_int = await read_finished_interrupt_status(driver)
            if finished_int:
                await clear_finished_interrupt(driver)
                break_finished = 1

        else:
            word_processed_old = 0
            finished, text_ready, word_processed = await read_status_register(driver)
            if word_processed != 1:
                while not (word_processed_old == 0 and word_processed == 1):
                    word_processed_old = word_processed
                    finished, text_ready, word_processed = await read_status_register(
                        driver
                    )
                    await RisingEdge(dut.s00_axi_aclk)

        await driver.write_32(ADDR_TEXT_LEN, plen)


        logger.debug(
            f"Count_a: {count_assoc_data} i_a: {i_associated_data}  Count_p: {count_text} i_p: {i_text} "
        )

        # More than 1 64-bit word total
        if count_assoc_data > 0 and i_associated_data < count_assoc_data:
            control.associated_data_word_left = 1
            control.text_word_left = 1
            await driver.write_128(
                ADDR_ASSOC_DATA, assoc_data_list[i_associated_data]
            )

            i_associated_data += 1

        elif i_text < count_text:
            if i_text == count_text - 1:
                plen = p_last_word_len
                await driver.write_32(ADDR_TEXT_LEN, plen)
                control.text_word_left = 0
            else:
                control.text_word_left = 1

            control.associated_data_word_left = 0

            await driver.write_128(ADDR_TEXT_IN, text_list[i_text])
            i_text += 1
        else:
            control.associated_data_word_left = 0
            control.text_word_left = 0
        control.input_ready = 1
        await write_control_register(
            driver,
            control
        )
        control.input_ready = 0


        finished, text_ready, word_processed = await read_status_register(driver)


        assert ((text_ready and not control.associated_data_word_left) or (control.associated_data_word_left and not text_ready) or finished), "Assumption incorrect"


        if (not (control.associated_data_word_left) and not finished):
            text_out = await driver.read_128(ADDR_TEXT_OUT)

            output = text_out.hex().zfill(32)[
                0 : (int(plen) // 4)
            ]
            outp = outp + output

            control.text_read = 1
            await write_control_register(
                driver,
                control
            )
            control.text_read = 0

        if break_finished == 1:
            break



async def generate_input_stream(
    dut: copra_stubs.Asconaead128,
    key,
    nonce,
    pt,
    ad,
    driver: AxiAsconDriver,
    encrypt_mode,
):
    plen = 0
    global outp
    logger = cocotb.log
    logger.setLevel(logging.DEBUG)

    logger.debug("Started generate input")

    logger.debug("Key: " + key)
    logger.debug("Nonce: " + nonce)
    logger.debug("Pt: " + pt)
    logger.debug("Ad: " + ad)

    i_associated_data = 0
    i_text = 0

    key = bytes.fromhex(key)
    nonce = bytes.fromhex(nonce)

    await driver.write_128(ADDR_KEY, key)
    await driver.write_128(ADDR_NONCE, nonce)

    text_list, assoc_data_list, count_text, count_assoc_data, p_last_word_len = (
        input_lists(ad, pt)
    )

    control = ControlSignals()

    control.text_word_left = 1
    control.encrypt_mode = encrypt_mode

    await write_control_register(driver, control)
    logger.debug("Control register written")

    plen = 128

    logger.debug(f"Associated data: {assoc_data_list}")
    logger.debug(f"Associated len: {count_assoc_data}")
    logger.debug(f"Plaintext data: {text_list}")
    logger.debug(f"Plaintext len: {count_text}")

    if count_assoc_data == 0:
        control.associated_data_word_left = 0
    else:
        control.associated_data_word_left = 1

    if count_text <= 1:
        plen = p_last_word_len
        control.text_word_left = 0



    await driver.write_32(ADDR_TEXT_LEN, p_last_word_len)


    control.start = 1
    control.input_ready = 1
    control.finish_rdy_en = 1
    control.word_rdy_en = 1
    await write_control_register(driver, control)
    control.input_ready = 0

    finished = 0
    finished, text_ready, word_processed = await read_status_register(driver)

    control.start = 0
    await write_control_register(driver, control)

    await driver.write_stream(assoc_data_list)
    
    await driver.write_stream(text_list)

    logger.warning(f"starting read {get_sim_time(unit="ns")}")
    read_data : bytearray = await driver.read_stream()
    logger.warning(f"OUTPUT {read_data.hex()}")
    logger.warning(f"OUTPUT {read_data.hex()[0:len(text_list)*2*16 - (32 - p_last_word_len//4)]}    tag: {read_data.hex()[-32:]}")
    outp = read_data.hex()[0:len(text_list)*2*16 - (32 - p_last_word_len//4)]


        

async def generate_clock(dut):
    c = Clock(dut.s00_axi_aclk, 10, unit="ns")
    c.start()

async def generate_clock_stream(dut):
    c1 = Clock(dut.s00_axi_aclk, 10, unit="ns")
    c2 = Clock(dut.s00_axis_aclk, 10, unit="ns")
    c3 = Clock(dut.m00_axis_aclk, 10, unit="ns")
    c1.start()
    c2.start()
    c3.start()


async def test_for_hex(
    dut: copra_stubs.Asconaead128, key, nonce, pt, ad, ciphertext, driver, use_stream = False
):
    global outp
    outp = ""
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    logger.debug(f"AD: {ad}")
    logger.debug(f"PT: {pt}")

    encrypt_mode = 1

    if use_stream:
        await generate_input_stream(dut, key, nonce, pt, ad, driver, 1)
    else:
        await generate_input(dut, key, nonce, pt, ad, driver, 1)

    finished, text_ready, word_processed = await read_status_register(driver)

    while finished != 1:
        await RisingEdge(dut.s00_axi_aclk)
        finished, text_ready, word_processed = await read_status_register(driver)
    
    correct_result = ciphertext.lower()

    tag_bytes = await driver.read_128(ADDR_TAG_OUT)
    actual_result = outp + tag_bytes.hex()

    logger.debug(f"Finished with tag:  {tag_bytes.hex()}")
    logger.debug("Finished with: %s" % actual_result)
    logger.debug("Correct solution: " + correct_result)

    logger.debug("Final outp: " + outp)
    logger.debug("Tag: " + tag_bytes.hex())

    final_result = outp + tag_bytes.hex()
    assert final_result == ciphertext.lower(), "Encryption incorrect"

    logger.debug(f"Finished encryption test starting decryption")
    outp = ""

    control = ControlSignals()

    await write_control_register(driver, control)
    dut.s00_axi_aresetn.value = 0
    await RisingEdge(dut.s00_axi_aclk)
    await RisingEdge(dut.s00_axi_aclk)
    dut.s00_axi_aresetn.value = 1

    text = ciphertext[:-32]
    correct_tag = ciphertext[-32:]

    logger.debug(f"Text {ciphertext}   {text}")

    if use_stream:
        await generate_input_stream(dut, key, nonce, text, ad, driver, 0)
    else:
        await generate_input(dut, key, nonce, text, ad, driver, 0)
    

    finished, text_ready, word_processed = await read_status_register(driver)

    while finished != 1:
        await RisingEdge(dut.s00_axi_aclk)
        finished, text_ready, word_processed = await read_status_register(driver)

    await write_control_register(driver, control)

    logger.debug(f"ct: {ciphertext}")

    correct_result = ciphertext.lower()

    output = outp

    tag_bytes = await driver.read_128(ADDR_TAG_OUT)


    logger.debug(f"Finished with: {output} :  {tag_bytes.hex()}")
    assert output == pt, "Incorrect plaintext"
    assert tag_bytes.hex() == correct_tag, "Incorrect tag!"

    return


@cocotb.test(timeout_time=8000, timeout_unit="ns")
async def test_ascon_aead_stream(dut : copra_stubs.Asconaead128Hybrid):
    logging.getLogger("cocotb.asconaead128_hybrid.s00_axi").setLevel(logging.WARNING)
    logging.getLogger("cocotb.asconaead128_hybrid.s00_axis").setLevel(logging.WARNING)
    logging.getLogger("cocotb.asconaead128_hybrid.m00_axis").setLevel(logging.WARNING)
    logging.getLogger("py.warnings").setLevel(logging.ERROR)

    logger = cocotb.log
    logger.setLevel(logging.INFO)

    cocotb.start_soon(generate_clock_stream(dut))

    dut.s00_axi_aresetn.value = 0

    await RisingEdge(dut.s00_axi_aclk)
    await RisingEdge(dut.s00_axi_aclk)
    
    dut.s00_axi_aresetn.value = 1
    dut.s00_axis_aresetn.value = 1
    dut.m00_axis_aresetn.value = 1

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s00_axis"), dut.s00_axis_aclk, dut.s00_axis_aresetn, reset_active_level=False)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m00_axis"), dut.m00_axis_aclk, dut.m00_axis_aresetn, reset_active_level=False)
    axi_master = AxiLiteMaster(
        AxiLiteBus.from_prefix(dut, "s00_axi"),
        dut.s00_axi_aclk,
        dut.s00_axi_aresetn,
        reset_active_level=False,
    )

    driver = AxiAsconDriver(axi_master, axis_sink, axis_source)

    await RisingEdge(dut.s00_axi_aclk)

    KAT_dictionary = parse_aead_encrypt_file("LWC_AEAD_KAT_128_128.txt")

    count = 0
    TESTS_TO_RUN = -1  # -1 to perform all tests

    for input_data in KAT_dictionary.keys():


        count += 1
        if count != 1007:
            continue
        obj = input_data
        key = obj.key
        nonce = obj.nonce
        ad = obj.ad
        pt = obj.pt

        logger.info("Starting round: %s" % count)


        ciphertext = KAT_dictionary[input_data]

        await test_for_hex(dut, key, nonce, pt, ad, ciphertext, driver, True)

        if count == TESTS_TO_RUN:
            break


@cocotb.test(timeout_time=8000, timeout_unit="us")
async def test_ascon_aead_single(dut):
    return
    logging.getLogger("cocotb.asconaead128_hybrid.s00_axi").setLevel(logging.WARNING)
    logging.getLogger("py.warnings").setLevel(logging.ERROR)

    logger = cocotb.log
    logger.setLevel(logging.INFO)

    cocotb.start_soon(generate_clock(dut))

    dut.s00_axi_aresetn.value = 0
    await RisingEdge(dut.s00_axi_aclk)
    await RisingEdge(dut.s00_axi_aclk)

    axi_master = AxiLiteMaster(
        AxiLiteBus.from_prefix(dut, "s00_axi"),
        dut.s00_axi_aclk,
        dut.s00_axi_aresetn,
        reset_active_level=False,
    )

    driver = AxiAsconDriver(axi_master, None, None)
    dut.s00_axi_aresetn.value = 1

    await RisingEdge(dut.s00_axi_aclk)

    KAT_dictionary = parse_aead_encrypt_file("LWC_AEAD_KAT_128_128.txt")

    count = 0
    TESTS_TO_RUN = -1  # -1 to perform all tests

    for input_data in KAT_dictionary.keys():


        count += 1
        if count != 1000:
            continue
        obj = input_data
        key = obj.key
        nonce = obj.nonce
        ad = obj.ad
        pt = obj.pt

        logger.info("Starting round: %s" % count)


        ciphertext = KAT_dictionary[input_data]

        await test_for_hex(dut, key, nonce, pt, ad, ciphertext, driver)

        if count == TESTS_TO_RUN:
            break


@cocotb.test(timeout_time=8000, timeout_unit="us")
async def test_ascon_aead_random(dut):
    return
    logging.getLogger("cocotb.asconaead128.s00_axi").setLevel(logging.WARNING)
    logging.getLogger("py.warnings").setLevel(logging.ERROR)

    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    logger = cocotb.log
    logger.setLevel(logging.INFO)

    cocotb.start_soon(generate_clock(dut))

    dut.s00_axi_aresetn.value = 0
    await RisingEdge(dut.s00_axi_aclk)
    await RisingEdge(dut.s00_axi_aclk)

    axi_master = AxiLiteMaster(
        AxiLiteBus.from_prefix(dut, "s00_axi"),
        dut.s00_axi_aclk,
        dut.s00_axi_aresetn,
        reset_active_level=False,
    )

    driver = AxiAsconDriver(axi_master)
    dut.s00_axi_aresetn.value = 1

    await RisingEdge(dut.s00_axi_aclk)

    KAT_dictionary = {}
    count = 0

    for i in range(100):
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
            dut, obj.key, obj.nonce, obj.pt, obj.ad, KAT_dictionary[input_data], driver
        )

        outp = ""
        count += 1