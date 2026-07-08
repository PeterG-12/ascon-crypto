import cocotb
from cocotb.triggers import Timer, Edge, with_timeout
from random import randint
import logging
from typing import TYPE_CHECKING


# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs



async def generate_clock(dut : copra_stubs.AsconHash256):
    """Generate clock pulses."""
    for _ in range(10000):
        dut.clk_i.value = 0
        await Timer(5, unit="ns")
        dut.clk_i.value = 1
        await Timer(5, unit="ns")

        if dut.word_processed_o.value == 1:
            dut.m_i.value = 0
            dut.word_left.value = 0


@cocotb.test()
async def test_ascon_hash(dut : copra_stubs.AsconHash256):
    logger = logging.getLogger("my_testbench")
    logger.warning("This is an info message")
    dut.m_i.value = int(0x0001020304050607)
    dut.start_i.value = 1
    dut.word_left.value = 1

    cocotb.start_soon(generate_clock(dut))

    

    while dut.finished_o.value != 1:
        await Timer(10, unit="ns")





