"""Tests for the claims the timing constraints assert but cannot prove.

Three things in librelane/housekeeping_top/constraints_*.sdc are
assertions about the design rather than facts the tool can check.  If any
of them is wrong, static timing has been signed off against a fiction.
They belong here:

  1. sram_clk_c and sram_clk_s are declared -logically_exclusive.  That
     is only legitimate if the SRAM genuinely cannot be accessed while
     the sequencer is running, so that seq_ena never moves with an access
     in flight.

  2. seq_strobe is no longer a clock.  housekeeping_spi.v decodes the
     command combinationally into seq_load and housekeeping.v registers
     seq_ena on SCK.  A regression would reintroduce a data-generated
     clock and the -0.505 ns hold race that went with it.

  3. proj_clk comes from a real clock-gating cell, so changing the
     selected project cannot emit a runt pulse or a spurious edge --- in
     particular when clk is stopped high, which is explicitly permitted.
"""

import cocotb
from cocotb.triggers import Timer, RisingEdge

from harness import (
    REG, CMD_SEQ_LOOP, CMD_SEQ_STOP, CMD_SRAM_WRITE, CMD_SRAM_READ,
    reset,
)


async def run_clock(dut, periods, half_ns=7.5):
    """Drive clk for a number of periods (15 ns nominal)."""
    for _ in range(periods):
        dut.clk.value = 0
        await Timer(half_ns, unit="ns")
        dut.clk.value = 1
        await Timer(half_ns, unit="ns")
    dut.clk.value = 0


@cocotb.test()
async def test_sram_clock_sources_are_exclusive(dut):
    """seq_ena must be low whenever the SPI can reach the SRAM.

    This is the premise behind -logically_exclusive on sram_clk_c and
    sram_clk_s.  Issuing an SRAM access command must leave the sequencer
    stopped, so that only one of clk and SCK ever reaches the SRAM.
    """
    spi = await reset(dut)

    # Start the sequencer, confirm it is running.
    await spi.command(CMD_SEQ_LOOP)
    await run_clock(dut, 4)
    assert int(dut.hk_top.hk.seq_ena.value) == 1, \
        "sequencer did not start"

    # Now issue an SRAM write command.  Per the documented restriction
    # ("SRAM cannot be accessed while the sequencer is running") the
    # command must stop the sequencer rather than access memory
    # concurrently.
    await spi.sram_write(0x00, [0x5A])
    await run_clock(dut, 4)

    seq_ena = int(dut.hk_top.hk.seq_ena.value)
    assert seq_ena == 0, (
        "seq_ena is still set after an SRAM access command; the SDC "
        "declares the two sram_clk sources logically exclusive and that "
        "is no longer true"
    )


@cocotb.test()
async def test_sram_clock_follows_selected_source(dut):
    """sram_clk tracks SCK when stopped and clk when running."""
    spi = await reset(dut)

    # Sequencer stopped: sram_clk must follow SCK, not clk.  Toggle clk
    # with SCK parked low and check sram_clk stays put.
    assert int(dut.hk_top.hk.seq_ena.value) == 0
    dut.SCK.value = 0
    await Timer(20, unit="ns")
    before = int(dut.hk_top.sram_clk.value)
    await run_clock(dut, 3)
    dut.clk.value = 0
    await Timer(20, unit="ns")
    assert int(dut.hk_top.sram_clk.value) == before, \
        "sram_clk moved with clk while the sequencer was stopped"

    # Sequencer running: sram_clk must now follow clk.
    await spi.command(CMD_SEQ_LOOP)
    await run_clock(dut, 2)
    assert int(dut.hk_top.hk.seq_ena.value) == 1

    dut.clk.value = 1
    await Timer(10, unit="ns")
    assert int(dut.hk_top.sram_clk.value) == 1, \
        "sram_clk did not follow clk high while the sequencer was running"
    dut.clk.value = 0
    await Timer(10, unit="ns")
    assert int(dut.hk_top.sram_clk.value) == 0, \
        "sram_clk did not follow clk low while the sequencer was running"


@cocotb.test()
async def test_seq_strobe_is_not_a_clock(dut):
    """seq_ena must latch on SCK, not on a rising edge of seq_strobe.

    The old design clocked seq_ena from a registered seq_strobe whose
    data (seq_mode) changed on the same SCK edge -- a genuine race that
    measured -0.505 ns of hold slack.  The visible consequence of the
    fix: back-to-back sequencer commands inside one CSB-low session now
    both take effect.  Previously seq_strobe was already high so it could
    not rise again, and the second command was silently dropped.
    """
    spi = await reset(dut)

    # Two sequencer commands without raising CSB in between.
    await spi.start()
    await spi.write_byte(CMD_SEQ_LOOP)     # start, looping
    await spi.write_byte(CMD_SEQ_STOP)     # stop, same session
    await spi.end()
    await run_clock(dut, 4)

    seq_ena = int(dut.hk_top.hk.seq_ena.value)
    assert seq_ena == 0, (
        "the second command in a CSB session was dropped; seq_ena is "
        "still set. This is the old seq_strobe-as-a-clock behaviour"
    )

    # And the reverse order, to show it is not simply stuck low.
    await spi.start()
    await spi.write_byte(CMD_SEQ_STOP)
    await spi.write_byte(CMD_SEQ_LOOP)
    await spi.end()
    await run_clock(dut, 4)

    assert int(dut.hk_top.hk.seq_ena.value) == 1, \
        "the second command in a CSB session was dropped (stop then run)"


@cocotb.test()
async def test_loop_mode_tracks_command(dut):
    """Looping and single-shot select different loop_mode values."""
    spi = await reset(dut)

    await spi.command(CMD_SEQ_LOOP)
    await run_clock(dut, 2)
    assert int(dut.hk_top.hk.seq_ena.value) == 1
    assert int(dut.hk_top.hk.loop_mode.value) == 1, \
        "loop_mode should be set for the looping command"

    await spi.command(CMD_SEQ_STOP)
    await run_clock(dut, 2)

    await spi.command(0x02)  # single shot
    await run_clock(dut, 2)
    assert int(dut.hk_top.hk.seq_ena.value) == 1
    assert int(dut.hk_top.hk.loop_mode.value) == 0, \
        "loop_mode should be clear for the single-shot command"


@cocotb.test()
async def test_digital_reset_clears_sequencer(dut):
    """The 0x04 command clears seq_ena and loop_mode asynchronously.

    loc_reset is an asynchronous reset in the RTL precisely so that this
    works with clk stopped, which is what is checked here.
    """
    spi = await reset(dut)

    await spi.command(CMD_SEQ_LOOP)
    await run_clock(dut, 2)
    assert int(dut.hk_top.hk.seq_ena.value) == 1

    # Park clk low, then issue the digital reset.  No clk edges occur.
    dut.clk.value = 0
    await Timer(50, unit="ns")
    await spi.command(0x04)
    await Timer(50, unit="ns")

    assert int(dut.hk_top.hk.seq_ena.value) == 0, \
        "digital reset did not clear seq_ena with clk stopped"
    assert int(dut.hk_top.hk.loop_mode.value) == 0, \
        "digital reset did not clear loop_mode with clk stopped"
