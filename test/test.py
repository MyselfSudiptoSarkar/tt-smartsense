import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_smartsense(dut):

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    dut.rst_n.value = 0
    await ClockCycles(dut.clk,5)
    dut.rst_n.value = 1

    ###################################################
    # Initial state
    ###################################################

    await ClockCycles(dut.clk,2)

    assert int(dut.uo_out.value & 0b111) == 0

    ###################################################
    # PIR Trigger
    ###################################################

    dut.ui_in.value = 0b00000001

    await ClockCycles(dut.clk,20)

    # Relay outputs should eventually become active
    assert dut.uo_out.value[0] == 1

    ###################################################
    # PIR cleared
    ###################################################

    dut.ui_in.value = 0

    await ClockCycles(dut.clk,30)

    ###################################################
    # Finish
    ###################################################

    dut._log.info("SmartSense test PASSED")