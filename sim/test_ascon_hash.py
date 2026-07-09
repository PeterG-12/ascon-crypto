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

async def generate_clock(dut : copra_stubs.AsconHash256):

    count = 0

    """Generate clock pulses."""
    for _ in range(10000):
        dut.clk_i.value = 0
        await Timer(5, unit="ns")
        dut.clk_i.value = 1
        await Timer(5, unit="ns")

        if dut.word_processed_o.value == 1:
            if count == 2:
                dut.m_i.value = 1
            else:
                dut.m_i.value = 0
            if count == 0:
                dut.m_i.value = int(0x0000000000000001)
                dut.word_left.value = 0
            count -= 1

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


@cocotb.test()
async def test_ascon_hash(dut : copra_stubs.AsconHash256):
    logger = logging.getLogger("my_testbench")
    logger.warning("This is an info message")
    dut.m_i.value = int(0x0706050403020100)
    dut.start_i.value = 1
    dut.word_left.value = 1

    cocotb.start_soon(generate_clock(dut))
    cocotb.start_soon(generate_log(dut))


    

    while dut.finished_o.value != 1:
        await Timer(10, unit="ns")

    logger.warning("Finished with: %s" % hex(dut.state_o.value)[2:])

    await Timer(20, unit="ns")





