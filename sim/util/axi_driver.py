
from util.parseandpad import parse, pad
from cocotbext.axi import AxiLiteBus, AxiLiteMaster
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame
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
SHIFT_CTRL_WORD_RDY_EN = 6
SHIFT_CTRL_FINISH_RDY_EN = 7

MASK_STATUS_FINISHED = 1 << 0
MASK_STATUS_TEXT_READY = 1 << 1
MASK_STATUS_WORD_PROCESSED = 1 << 2
MASK_STATUS_WORD_INT = 1 << 3
MASK_STATUS_FINISHED_INT = 1 << 4

USE_INTERRUPTS = 0



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

class Fifo:
    def __init__(self) -> None:
        self.fifo = []

    def is_full(self) -> bool:
        return (len(self.fifo) >= 16)

    def is_empty(self) -> bool:
        return (len(self.fifo) == 0)

class ControlSignals:
    def __init__(self) -> None:
        self.start = 0
        self.text_word_left = 0
        self.associated_data_word_left = 0
        self.encrypt_mode = 0
        self.input_ready = 0
        self.text_read = 0
        self.word_rdy_en = 0
        self.finish_rdy_en = 0


class AxiAsconDriver:
    def __init__(self, axi_master : AxiLiteMaster, axis_sink : AxiStreamSink, axis_source : AxiStreamSource):
        self.transactions = []
        self.axi : AxiLiteMaster = axi_master
        if axis_sink != None and axis_source != None:
            self.axis_sink : AxiStreamSink = axis_sink
            self.axis_source : AxiStreamSource = axis_source
        self.recording = False

    async def write_32(self, addr: int, val: int):
        await self.axi.write(addr, val.to_bytes(4, byteorder="little"))

    async def read_32(self, addr: int) -> int:
        res = await self.axi.read(addr, 4)
        val = int.from_bytes(res.data, byteorder="little")
        return val

    async def write_128(self, base_addr: int, val: bytes):
        for i in range(4):
            chunk = val[i * 4 : (i+1) * 4]
            word = int.from_bytes(chunk, byteorder="little")
            await self.write_32(base_addr + (i * 4), word)

    async def read_128(self, base_addr: int) -> bytes:
        res = bytearray()
        for i in range(4):
            word = await self.read_32(base_addr + (i * 4))
            word_bytes = word.to_bytes(4, byteorder="little")
            res += bytearray(word_bytes)
        return bytes(res)

    async def write_stream(self, crypto_word_list):
        write_queue = []
        for crypto_word in crypto_word_list:
            for i in range(4):
                chunk = crypto_word[i * 4 : (i+1) * 4]
                word = int.from_bytes(chunk, byteorder="little")
                val = word.to_bytes(4, byteorder="little")
                write_queue.append(val)
        await self.axis_source.write(b"".join(write_queue))
        await self.axis_source.wait()

    async def read_stream(self) -> bytearray:
        res = await self.axis_sink.recv()
        return res.tdata

    async def write_32_stream(self, val):
        to_send = val.to_bytes(4, byteorder="little")
        print(f"Sending: {to_send}")
        await self.axis_source.send(to_send)

    async def read_32_stream(self) -> int:
        print("READIN' 2...")
        res = await self.axis_sink.recv()
        print(f"RECEIVED'... {res.tdata}")
        val = int.from_bytes(res.tdata, byteorder="little")
        return val

    async def write_128_stream(self, val: bytes):
        for i in range(4):
            chunk = val[i * 4 : (i+1) * 4]
            word = int.from_bytes(chunk, byteorder="little")
            await self.write_32_stream(word)

    async def read_128_stream(self) -> bytes:
        print("READIN' 1...")
        res = bytearray()
        for _ in range(4):
            word = await self.read_32_stream()
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
        | (control.word_rdy_en << SHIFT_CTRL_WORD_RDY_EN)
        | (control.finish_rdy_en << SHIFT_CTRL_FINISH_RDY_EN)
    )
    await driver.write_32(ADDR_CTRL, ctrl_data)


async def read_status_register(driver: AxiAsconDriver):
    status_data = await driver.read_32(ADDR_STATUS)
    finished = (status_data & MASK_STATUS_FINISHED) >> 0
    text_ready = (status_data & MASK_STATUS_TEXT_READY) >> 1
    word_processed = (status_data & MASK_STATUS_WORD_PROCESSED) >> 2
    return finished, text_ready, word_processed


async def read_word_interrupt_status(driver: AxiAsconDriver):
    status_data = await driver.read_32(ADDR_STATUS)

    return (status_data & MASK_STATUS_WORD_INT) >> 3


async def read_finished_interrupt_status(driver: AxiAsconDriver):
    status_data = await driver.read_32(ADDR_STATUS)
    return (status_data & MASK_STATUS_FINISHED_INT) >> 4

async def clear_word_interrupt(driver: AxiAsconDriver):
    await driver.write_32(ADDR_STATUS, 1 << 3)

async def clear_finished_interrupt(driver: AxiAsconDriver):
    await driver.write_32(ADDR_STATUS, 1 << 4)