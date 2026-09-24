"""SPI interface and register file tests.

These cover the parts of digital_tb.v that actually checked something,
plus the cases it did not reach:  auto-increment, read-back of written
values, and that CSB genuinely resets the SPI state machine.
"""

import cocotb
from cocotb.triggers import Timer

from harness import (
    REG, MFGR_ID, PROD_ID,
    CMD_READ, CMD_WRITE, CMD_NOP,
    reset,
)


@cocotb.test()
async def test_identity_registers(dut):
    """The fixed ID registers read back their hard-coded values."""
    spi = await reset(dut)

    prod = await spi.read_reg(REG["prod_id"])
    assert prod == PROD_ID, f"product ID = 0x{prod:02x}, expected 0x{PROD_ID:02x}"

    hi = await spi.read_reg(REG["mfgr_id_hi"])
    lo = await spi.read_reg(REG["mfgr_id_lo"])
    mfgr = ((hi & 0x0F) << 8) | lo
    assert mfgr == MFGR_ID, f"manufacturer ID = 0x{mfgr:03x}, expected 0x{MFGR_ID:03x}"

    status = await spi.read_reg(REG["spi_status"])
    assert status == 0x00, f"SPI status = 0x{status:02x}, expected 0x00"


@cocotb.test()
async def test_mask_rev_passthrough(dut):
    """mask_rev_in is metal-programmed and must read back byte for byte.

    digital_tb.v drove 0xdeadbeef but never checked it came back.
    """
    spi = await reset(dut)
    dut.mask_rev_in.value = 0xDEADBEEF
    await Timer(100, unit="ns")

    got = await spi.read_regs(REG["mask_rev_3"], 4)
    word = (got[0] << 24) | (got[1] << 16) | (got[2] << 8) | got[3]
    assert word == 0xDEADBEEF, f"mask_rev read back 0x{word:08x}, expected 0xdeadbeef"


@cocotb.test()
async def test_register_write_readback(dut):
    """Writable registers hold what is written to them."""
    spi = await reset(dut)

    cases = [
        ("seq_prescaler", 0x5A),
        ("pat_prescaler", 0xA5),
        ("seq_start_lo",  0x34),
        ("seq_start_hi",  0x12),
        ("seq_stop_lo",   0x78),
        ("seq_stop_hi",   0x56),
        ("idac1",         0x15),   # 5 bits
        ("idac2",         0x0A),
    ]
    for name, value in cases:
        await spi.write_reg(REG[name], value)

    for name, value in cases:
        got = await spi.read_reg(REG[name])
        assert got == value, f"{name}: wrote 0x{value:02x}, read 0x{got:02x}"


@cocotb.test()
async def test_address_autoincrement(dut):
    """A write stream walks consecutive addresses, and so does a read."""
    spi = await reset(dut)

    # seq_start (0x12,0x13) and seq_stop (0x14,0x15) are four adjacent
    # writable bytes, so one stream covers them.
    payload = [0x11, 0x22, 0x33, 0x44]
    await spi.write_regs(REG["seq_start_lo"], payload)

    got = await spi.read_regs(REG["seq_start_lo"], 4)
    assert got == payload, f"auto-increment: wrote {payload}, read {got}"


@cocotb.test()
async def test_csb_resets_spi(dut):
    """Raising CSB mid-transaction resets the state machine.

    An aborted transfer must not leave the SPI mid-stream such that the
    next command byte is mistaken for address or data.  digital_tb.v
    never exercised this.
    """
    spi = await reset(dut)
    await spi.write_reg(REG["seq_prescaler"], 0x3C)

    # Begin a write to seq_prescaler, then abandon it after the address
    # byte without sending data.
    await spi.start()
    await spi.write_byte(CMD_WRITE)
    await spi.write_byte(REG["seq_prescaler"])
    await spi.end()

    # The abandoned transfer must not have altered the register...
    got = await spi.read_reg(REG["seq_prescaler"])
    assert got == 0x3C, f"aborted write changed the register to 0x{got:02x}"

    # ...and the interface must still work normally afterwards.
    prod = await spi.read_reg(REG["prod_id"])
    assert prod == PROD_ID, f"SPI broken after abort: prod_id = 0x{prod:02x}"


@cocotb.test()
async def test_nop_command(dut):
    """A no-op command leaves the register file alone."""
    spi = await reset(dut)
    await spi.write_reg(REG["pat_prescaler"], 0x77)

    await spi.start()
    await spi.write_byte(CMD_NOP)
    await spi.write_byte(REG["pat_prescaler"])
    await spi.write_byte(0x00)
    await spi.end()

    got = await spi.read_reg(REG["pat_prescaler"])
    assert got == 0x77, f"NOP command wrote the register: 0x{got:02x}"
