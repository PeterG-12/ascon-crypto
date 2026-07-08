import cocotb
from cocotb.triggers import Timer, Edge, with_timeout
from random import randint
import logging
from typing import TYPE_CHECKING


# 1. Import the stub ONLY for your IDE, hiding it from the simulator
if TYPE_CHECKING:
    import copra_stubs



async def generate_clock(dut):
    """Generate clock pulses."""
    for _ in range(10000):
        dut.clk.value = 0
        await Timer(5, unit="ns")
        dut.clk.value = 1
        await Timer(5, unit="ns")


@cocotb.test()
async def test_ascon_sbox(dut : copra_stubs.AsconSbox):
    logger = logging.getLogger("my_testbench")

    dut.state_i.value = 0
    dut.clk.value = 1

    await Timer(5, unit="ns")
    logger.warning(dut.clk.value)
    logger.warning(dut.state_o.value)


    logger.warning("This is an info message")




