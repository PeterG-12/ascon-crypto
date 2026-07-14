from cocotb.clock import Clock
import logging
from util.general import split

async def generate_clock(dut):
    c = Clock(dut.clk_i, 10, "ns")
    c.start()

        

async def generate_state_log(dut):
    logger = logging.getLogger("my_testbench")
    logger.warning("This is an info message")

    curr_state = dut.curr_state.value

    while dut.finished_o.value != 1:
        await dut.clk_i.rising_edge

        if curr_state != dut.curr_state.value:
            curr_state = dut.curr_state.value
            logger.warning("State  changed!")


        if dut.start_core.value == 1:
            logger.warning("Starting core with: %s" % split(hex(dut.core_in.value)))

        if dut.core_finished.value == 1:
            logger.warning("Core finished with: %s" % split(hex(dut.core_out.value)))