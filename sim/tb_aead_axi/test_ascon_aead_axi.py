import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiBus, AxiMaster


@cocotb.test()
async def test_ascon_aead_axi(dut : AsconAead128):
    # 1. Start the clock on your specific clock port (100 MHz -> 10ns period)
    cocotb.start_soon(Clock(dut.s00_axi_aclk, 10, unit="ns").start())

    axi_master = AxiMaster(AxiBus.from_prefix(dut, "s00_axi"), dut.s00_axi_aclk, dut.s00_axi_aresetn)
    