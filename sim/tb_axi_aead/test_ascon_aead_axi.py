import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiLiteBus, AxiLiteMaster
from util.parseandpad import parse, pad
from util.parsefile import parse_aead_encrypt_file
from util.general import invert_bytes_per_word
import logging
from cocotb.triggers import Timer
from typing import TYPE_CHECKING
from cocotb.utils import get_sim_time

# Base address of the Axi periphreal used in Vivado
# Needed for configuring the logs correctly
FPGA_MMAP_BASE = 0x44A0_0000


ADDR_CTRL = 0x00
ADDR_STATUS = 0x04
ADDR_KEY = 0x08
ADDR_NONCE = 0x18
ADDR_ASSOC_DATA = 0x28
ADDR_TEXT_IN = 0x38
ADDR_TEXT_LEN = 0x48
ADDR_TEXT_OUT = 0x4C
ADDR_TAG_OUT = 0x5C


SHIFT_CTRL_START = 0
SHIFT_CTRL_AD_LEFT = 1
SHIFT_CTRL_PT_LEFT = 2
SHIFT_CTRL_ENCRYPT_MODE = 3
SHIFT_CTRL_INPUT_READY = 4
SHIFT_CTRL_TEXT_READ = 5

MASK_STATUS_FINISHED = 1 << 0
MASK_STATUS_TEXT_READY = 1 << 1
MASK_STATUS_WORD_PROCESSED = 1 << 2

if TYPE_CHECKING:
    import copra_stubs


def input_lists(assoc_data: str, text: str):
    text_tuple = parse(text, 16)
    text_list = text_tuple[0]
    text_list[-1] = pad(text_list[-1], 16)
    for i in range(0, len(text_list)):
        text_list[i] = bytes.fromhex(text_list[i])
    last_word_len = text_tuple[1]

    ad_tuple = parse(assoc_data, 16)
    assoc_data_list = ad_tuple[0]

    if len(assoc_data_list) > 0:
        assoc_data_list[-1] = pad(assoc_data_list[-1], 16)
    for i in range(0, len(assoc_data_list)):
        assoc_data_list[i] = bytes.fromhex(assoc_data_list[i])

    count_assoc_data = 0
    count_text = 0

    if assoc_data != "":
        count_assoc_data = len(assoc_data_list)
    if text != "":
        count_text = len(text_list)

    return text_list, assoc_data_list, count_text, count_assoc_data, last_word_len


class ControlSignals:
    def __init__(self) -> None:
        self.start = 0
        self.text_word_left = 0
        self.associated_data_word_left = 0
        self.encrypt_mode = 0
        self.input_ready = 0
        self.text_read = 0


class AxiAsconDriver:
    def __init__(self, axi_master):
        self.transactions = []
        self.axi = axi_master
        self.recording = True

    async def write_32(self, addr: int, val: int):
        sim_time = get_sim_time(unit="ns")
        self.transactions.append(
            {"time": sim_time, "op": "write", "addr": addr, "data": val & 0xFFFFFFFF}
        )
        await self.axi.write(addr, val.to_bytes(4, byteorder="little"))

    async def read_32(self, addr: int) -> int:
        res = await self.axi.read(addr, 4)
        sim_time = get_sim_time(unit="ns")
        val = int.from_bytes(res.data, byteorder="little")
        self.transactions.append(
            {"time": sim_time, "op": "read", "addr": addr, "data": val & 0xFFFFFFFF}
        )
        return val

    async def write_128(self, base_addr: int, val: bytes):
        for i in range(4):
            chunk = val[i * 4 : (i+1) * 4]
            word = int.from_bytes(chunk, byteorder="little")
            await self.write_32(base_addr + (i * 4), word)

    async def read_128(self, base_addr: int) -> bytes:
        val = 0
        res = bytearray()
        for i in range(4):
            word = await self.read_32(base_addr + (i * 4))
            word_bytes = word.to_bytes(4, byteorder="little")
            res += bytearray(word_bytes)
        return bytes(res)



async def write_control_register(driver: AxiAsconDriver, control: ControlSignals):
    ctrl_data = (
        (control.start << SHIFT_CTRL_START)
        | (control.associated_data_word_left << SHIFT_CTRL_AD_LEFT)
        | (control.text_word_left << SHIFT_CTRL_PT_LEFT)
        | (control.encrypt_mode << SHIFT_CTRL_ENCRYPT_MODE)
        | (control.input_ready << SHIFT_CTRL_INPUT_READY)
        | (control.text_read << SHIFT_CTRL_TEXT_READ)
    )
    await driver.write_32(ADDR_CTRL, ctrl_data)


async def read_status_register(driver: AxiAsconDriver):
    status_data = await driver.read_32(ADDR_STATUS)
    finished = (status_data & MASK_STATUS_FINISHED) >> 0
    text_ready = (status_data & MASK_STATUS_TEXT_READY) >> 1
    word_processed = (status_data & MASK_STATUS_WORD_PROCESSED) >> 2
    return finished, text_ready, word_processed


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

    await write_control_register(driver, control)

    control.start = 1
    control.input_ready = 1
    await write_control_register(driver, control)
    control.input_ready = 0

    finished = 0
    finished, text_ready, word_processed = await read_status_register(driver)
    logger.debug("Reading status loop")

    control.start = 0
    await write_control_register(driver, control)

    while finished != 1:

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

        logger.debug(
            f"Writing pleft: {control.text_word_left} adleft: {control.associated_data_word_left}"
        )
        control.input_ready = 1
        await write_control_register(
            driver,
            control
        )
        control.input_ready = 0

        text_ready_old = text_ready

        finished, text_ready, word_processed = await read_status_register(driver)

        logger.debug(f"Vals: {text_ready}   {text_ready_old}")

        if text_ready_old == 0 and text_ready == 1:
            text_out = await driver.read_128(ADDR_TEXT_OUT)
            logger.debug(f"TEXT_OUT: {text_out} Plen: {plen}")

            output = text_out.hex().zfill(32)[
                0 : (int(plen) // 4)
            ]
            logger.debug(
                "Current Output: "
                + "   "
                + invert_bytes_per_word(output)
                + "  "
                + str(plen)
            )
            outp = outp + output
            logger.debug("ADDED Outp: " + outp)

            control.text_read = 1
            await write_control_register(
                driver,
                control
            )
            control.text_read = 0

        logger.debug(f"Finished: {finished}")


async def generate_clock(dut):
    c = Clock(dut.s00_axi_aclk, 10, unit="ns")
    c.start()


async def test_for_hex(
    dut: copra_stubs.Asconaead128, key, nonce, pt, ad, ciphertext, driver
):
    global outp

    outp = ""
    logger = cocotb.log
    logger.setLevel(logging.INFO)

    logger.debug(f"AD: {ad}")
    logger.debug(f"PT: {pt}")

    encrypt_mode = 1

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

    assert tag_bytes.hex() == correct_tag, "Incorrect tag!"
    assert output == pt, "Incorrect plaintext"

    return


@cocotb.test(timeout_time=8000, timeout_unit="us")
async def test_ascon_aead_single(dut):
    logging.getLogger("cocotb.asconaead128.s00_axi").setLevel(logging.WARNING)
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

    driver = AxiAsconDriver(axi_master)
    dut.s00_axi_aresetn.value = 1

    await RisingEdge(dut.s00_axi_aclk)

    KAT_dictionary = parse_aead_encrypt_file("LWC_AEAD_KAT_128_128.txt")

    count = 0
    TESTS_TO_RUN = -1  # -1 to perform all tests

    for input_data in KAT_dictionary.keys():


        count += 1

        obj = input_data
        key = obj.key
        nonce = obj.nonce
        ad = obj.ad
        pt = obj.pt

        logger.warning(f"{ad}   {pt}")
        logger.info("Starting round: %s" % count)


        ciphertext = KAT_dictionary[input_data]

        await test_for_hex(dut, key, nonce, pt, ad, ciphertext, driver)

        if count == TESTS_TO_RUN:
            break