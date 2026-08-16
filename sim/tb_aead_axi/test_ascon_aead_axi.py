import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiLiteBus, AxiLiteMaster
from util.parseandpad import parse, pad, split320
from util.parsefile import parse_aead_encrypt_file, AeadEncrypt
from util.general import pad_zeroes, split, invert_bytes_per_word
from util.simuutil import generate_clock, generate_state_log
import logging
from cocotb.triggers import Timer, Edge, with_timeout, First
from typing import TYPE_CHECKING

ADDR_CTRL       = 0x00
ADDR_STATUS     = 0x04
ADDR_KEY        = 0x08
ADDR_NONCE      = 0x18
ADDR_ASSOC_DATA = 0x28
ADDR_TEXT_IN    = 0x38
ADDR_TEXT_LEN   = 0x48
ADDR_TEXT_OUT   = 0x4C
ADDR_TAG_OUT    = 0x5C

debug = False
debugValue = False

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

class AxiAsconDriver:
    def __init__(self, axi_master):

        self.axi = axi_master

    async def write_32(self, addr: int, val: int):
        await self.axi.write(addr, val.to_bytes(4, byteorder='little'))


    async def read_32(self, addr: int) -> int:
        res = await self.axi.read(addr, 4)
        return int.from_bytes(res.data, byteorder='little')

    async def write_128(self, base_addr: int, val: int):
        for i in range(4):
            word = (val >> (i * 32)) & 0xFFFFFFFF
            await self.write_32(base_addr + (i * 4), word)

    async def read_128(self, base_addr: int) -> int:
        val = 0
        for i in range(4):
            word = await self.read_32(base_addr + (i * 4))
            val |= (word << (i * 32))
        return val

async def write_control_register(driver : AxiAsconDriver,  start, plaintext_word_left, associated_data_word_left, encrypt_mode, input_ready, text_read):
    
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    
    if debug:
        logger.info(f"Writing status register value: {associated_data_word_left}")
    ctrl_data = (start << 0) | (associated_data_word_left << 1) | (plaintext_word_left << 2) | (encrypt_mode << 3) | (input_ready << 4) | (text_read << 5)
    await driver.write_32(ADDR_CTRL, ctrl_data)

async def read_status_register(driver : AxiAsconDriver):
    status_data = await driver.read_32(ADDR_STATUS)
    logger = cocotb.log
    logger.setLevel(logging.INFO)
    if debug:
        logger.info(f"Reading status register value: {status_data}")
    return status_data & (1 << 0), (status_data & (1 << 1)) // 2, (status_data & (1 << 2) ) // 4

plen = 0
outp = ""


async def log_tag(dut: copra_stubs.Asconaead128, driver):
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    finished = 0
    while not finished:
        finished, c_ready, word_processed = await read_status_register(driver)



async def generate_input(dut: copra_stubs.Asconaead128, key, nonce, pt, ad, driver : AxiAsconDriver, encrypt_mode):
    global plen
    global outp
    logger = cocotb.log
    logger.setLevel(logging.INFO)


    if debug: logger.info("Started generate input")


    if debugValue:
        logger.info("Key: " + key)
    if debugValue:
        logger.info("Nonce: " + nonce)
    if debugValue:
        logger.info("Pt: " + pt)
    if debugValue:
        logger.info("Ad: " + ad)

    i_associated_data = 0
    i_text = 0

    key = invert_bytes_per_word(key)
    nonce = invert_bytes_per_word(nonce)

    await driver.write_128(ADDR_KEY, int(key, 16))
    await driver.write_128(ADDR_NONCE, int(nonce, 16))
    
    text_list, assoc_data_list, count_text, count_assoc_data, p_last_word_len = (
        input_lists(ad, pt)
    )

    start_ctrl = 0
    plaintext_word_left_ctrl = 1
    associated_data_word_left_ctrl = 0
    input_ready_ctrl = 0
    encrypt_mode_ctrl = encrypt_mode
    
    await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 0, 0)
    if debug: logger.info("Control register written")
    
    plen = 128

    if debug:
        logger.info(f"Associated data: {assoc_data_list}")
        logger.info(f"Associated len: {count_assoc_data}")
    if debug:
        logger.info(f"Plaintext data: {text_list}")
        logger.info(f"Plaintext len: {count_text}")
        
    if count_assoc_data == 0:
        associated_data_word_left_ctrl = 0
        await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 0, 0)
        await driver.write_128(ADDR_TEXT_IN, int(text_list[0], 16))
    else:
        associated_data_word_left_ctrl = 1
        await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 0, 0)
        await driver.write_128(ADDR_ASSOC_DATA, int(assoc_data_list[0], 16))
        if debug:
            logger.info("Associated data input: " + assoc_data_list[i_associated_data])

    if count_text <= 1:
        plen = p_last_word_len
        plaintext_word_left_ctrl = 0
        await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 0, 0)
        await driver.write_128(ADDR_TEXT_IN, int(text_list[0], 16))

    # logger.warning(f"plen: {plen}   lastwordlen {p_last_word_len}")

    if debug: logger.info(f"Entering loop with: {associated_data_word_left_ctrl}")

    start_ctrl = 1
    await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 1, 0)
    finished = 0
    finished, c_ready, word_processed = await read_status_register(driver)
    if debug: logger.info("Reading status loop")
    start_ctrl = 0
    await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 0, 0)

    while finished != 1:

        word_processed_old = 0
        finished, c_ready, word_processed = await read_status_register(driver)
        if word_processed != 1:
            while not (word_processed_old == 0 and word_processed == 1):
                word_processed_old = word_processed
                finished, c_ready, word_processed = await read_status_register(driver)
                await RisingEdge(dut.s00_axi_aclk)

        
        await driver.write_32(ADDR_TEXT_LEN, plen)


        if debug:
            logger.info(
                f"Count_a: {count_assoc_data} i_a: {i_associated_data}  Count_p: {count_text} i_p: {i_text} "
            )

        # More than 1 64-bit word total
        if count_assoc_data > 0 and i_associated_data < count_assoc_data:
            associated_data_word_left_ctrl = 1
            plaintext_word_left_ctrl = 1
            await driver.write_128(ADDR_ASSOC_DATA, int(assoc_data_list[i_associated_data], 16))

            i_associated_data += 1

        elif i_text < count_text:
            if i_text == count_text - 1:
                plen = p_last_word_len

                await driver.write_32(ADDR_TEXT_LEN, plen)

                plaintext_word_left_ctrl = 0
        
            else:
                plaintext_word_left_ctrl = 1

            associated_data_word_left_ctrl = 0
            
            await driver.write_128(ADDR_TEXT_IN, int(text_list[i_text], 16))
            i_text += 1
        else:
            associated_data_word_left_ctrl = 0
            plaintext_word_left_ctrl = 0
        
        if debug:
            logger.info(f"Writing pleft: {plaintext_word_left_ctrl} adleft: {associated_data_word_left_ctrl}")
        await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 1, 0)

        c_ready_old = c_ready
        
        
        finished, c_ready, word_processed = await read_status_register(driver)
        
        if debug:
            logger.info(f"Vals: {c_ready}   {c_ready_old}")
        
        if c_ready_old == 0 and c_ready == 1:
            text_out = await driver.read_128(ADDR_TEXT_OUT)
            if debug:
                logger.info(f"TEXT_OUT: {text_out} Plen: {plen}")

            output = invert_bytes_per_word(hex(text_out)[2:].zfill(32))[
                0 : (int(plen) // 4)
            ]
            if debug:
                logger.info("Current Output: " + "   " + invert_bytes_per_word(output) + "  " + str(plen))
            outp = outp + output
            if debug:
                logger.info("ADDED Outp: " + outp)

            await write_control_register(driver, start_ctrl, plaintext_word_left_ctrl, associated_data_word_left_ctrl, encrypt_mode_ctrl, 0, 1)

        if debug:
            logger.info(f"Finished: {finished}")




async def generate_clock(dut):
    c = Clock(dut.s00_axi_aclk, 10, unit="ns")
    c.start()

async def test_for_hex(dut: copra_stubs.Asconaead128, key, nonce, pt, ad, ciphertext, driver):
    global outp

    outp = ""
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    if debugValue:
        logger.info(f"AD: {ad}")
        logger.info(f"PT: {pt}")

    encrypt_mode = 1
    encryption_task = cocotb.start_soon(generate_input(dut, key, nonce, pt, ad, driver, 1))

    await Timer(1000, unit="ns")

    finished, c_ready, word_processed = await read_status_register(driver)

    while finished != 1:
        await RisingEdge(dut.s00_axi_aclk)
        finished, c_ready, word_processed = await read_status_register(driver)


    correct_result = ciphertext.lower()



    tag = await driver.read_128(ADDR_TAG_OUT)
    raw_tag_hex = hex(tag)[2:].zfill(32)
    inv_tag = invert_bytes_per_word(raw_tag_hex)
    
    actual_result = outp + raw_tag_hex

    if debug:
        logger.info(f"Finished with tag:  {tag}")
    if debug:
        logger.info("Finished with: %s" % actual_result)
    if debug:
        logger.info("Correct solution: " + correct_result)


    if debug:
        logger.info("Final outp: " + outp)
    if debug:
        logger.info("Tag: " + inv_tag)
    
    final_result = outp + inv_tag
    assert final_result == ciphertext.lower(), "Encryption incorrect"

    if debug:
        logger.warning(f"Finished encryption test starting decryption")

    encryption_task.cancel()

    outp = ""

    
    await write_control_register(driver, 0, 0, 0, 0, 0, 0)
    dut.s00_axi_aresetn.value = 0
    await RisingEdge(dut.s00_axi_aclk)
    await RisingEdge(dut.s00_axi_aclk)
    dut.s00_axi_aresetn.value = 1

    await Timer(60, unit="ns")

    text = ciphertext[:-32]
    correct_tag = ciphertext[-32:]

    if debug:
        logger.info(f"Text {ciphertext}   {text}")

    decryption_task = cocotb.start_soon(generate_input(dut, key, nonce, text, ad, driver, 0))

    finished, c_ready, word_processed = await read_status_register(driver)

    while finished != 1:
        await RisingEdge(dut.s00_axi_aclk)
        finished, c_ready, word_processed = await read_status_register(driver)

    await write_control_register(driver, 0, 0, 0, 0, 0, 0)

    if debug:
        logger.info(f"ct: {ciphertext}")

    correct_result = ciphertext.lower()




    output = outp

    tag = await driver.read_128(ADDR_TAG_OUT)
    raw_tag_hex = hex(tag)[2:].zfill(32)
    inv_tag = invert_bytes_per_word(raw_tag_hex)


    if debug: logger.info(f"Finished with: {output} :  {inv_tag}")

    assert inv_tag == correct_tag, "Incorrect tag!"
    assert output == pt, "Incorrect plaintext"

    await Timer(20, unit="ns")
    decryption_task.cancel()
    return



@cocotb.test(timeout_time=5000, timeout_unit="us")
async def test_ascon_aead_single(dut):
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
    
    logging.getLogger("cocotb.asconaead128.s00_axi").setLevel(logging.WARNING)
    driver = AxiAsconDriver(axi_master)
    dut.s00_axi_aresetn.value = 1
    
    await RisingEdge(dut.s00_axi_aclk)

    KAT_dictionary = parse_aead_encrypt_file("LWC_AEAD_KAT_128_128.txt")

    count = 0
    TESTS_TO_RUN = -1 # -1 to perform all tests

    for input_data in KAT_dictionary.keys():
        
        logger.info("Starting round: %s" % count)
        
        count += 1

        obj = input_data
        key = obj.key
        nonce = obj.nonce
        ad = obj.ad
        pt  = obj.pt
        ciphertext = KAT_dictionary[input_data]

        await test_for_hex(dut, key, nonce, pt, ad, ciphertext, driver)

        if count == TESTS_TO_RUN:
            break

    

