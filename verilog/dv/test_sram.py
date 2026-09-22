"""SRAM access over SPI.

digital_tb.v wrote four bytes and read them back.  These add the cases
that matter for the documented interface, in particular the address
behaviour:  the SPI address phase is only eight bits, so the register map
states that "only addresses 0 to 255 are individually addressible.
Addresses up to 1023 are accessible by continuous reading or writing with
auto-increment."  That carry out of the low byte is the part most likely
to be wrong and was never tested.
"""

import cocotb
from cocotb.triggers import Timer

from harness import REG, reset


@cocotb.test()
async def test_sram_write_read(dut):
    """Bytes written to the SRAM read back unchanged."""
    spi = await reset(dut)

    payload = [0x55, 0xAA, 0x3C, 0xC3]
    await spi.sram_write(0xFF, payload)
    got = await spi.sram_read(0xFF, len(payload))

    assert got == payload, (
        f"SRAM readback mismatch: wrote {[hex(v) for v in payload]}, "
        f"read {[hex(v) for v in got]}"
    )


@cocotb.test()
async def test_sram_autoincrement_across_256(dut):
    """Auto-increment must carry out of the low address byte.

    The SPI sends an 8-bit address, and housekeeping_spi widens it to the
    SRAM's 10 bits with the top two bits zero.  Only the increment in the
    DATA state can reach addresses above 255.  Writing a run that starts
    below 0xFF and continues past it therefore exercises the only path to
    the upper three quarters of the memory.
    """
    spi = await reset(dut)

    # 0xFC .. 0x103 -- eight bytes straddling the byte boundary.
    payload = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88]
    await spi.sram_write(0xFC, payload)

    got = await spi.sram_read(0xFC, len(payload))
    assert got == payload, (
        f"auto-increment across 0xFF failed: wrote {[hex(v) for v in payload]}, "
        f"read {[hex(v) for v in got]}. If the last four differ, the address "
        f"wrapped to 0x00 instead of carrying to 0x100"
    )


@cocotb.test()
async def test_sram_high_addresses_are_distinct(dut):
    """0x100 must be a different location from 0x00.

    A wrap rather than a carry would make these alias, and the previous
    test would still pass if both reads came from the same wrapped
    location.  This pins it down.
    """
    spi = await reset(dut)

    # Write a marker at 0x00..0x03 directly.
    await spi.sram_write(0x00, [0xDE, 0xAD, 0xBE, 0xEF])

    # Reach 0x100..0x103 by running a stream from 0xFE.
    await spi.sram_write(0xFE, [0x00, 0x00, 0x01, 0x02, 0x03, 0x04])

    low = await spi.sram_read(0x00, 4)
    assert low == [0xDE, 0xAD, 0xBE, 0xEF], (
        f"writing through 0x100 corrupted 0x00: read {[hex(v) for v in low]}; "
        f"the address wrapped instead of carrying"
    )


@cocotb.test()
async def test_sram_walking_ones(dut):
    """A walking-ones pattern, as the pattern generator would hold.

    Exercises every data bit independently, which the four-byte test in
    digital_tb.v did not.
    """
    spi = await reset(dut)

    payload = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80]
    await spi.sram_write(0x00, payload)
    got = await spi.sram_read(0x00, len(payload))

    assert got == payload, (
        f"walking ones mismatch: wrote {[hex(v) for v in payload]}, "
        f"read {[hex(v) for v in got]}"
    )

    # And walking zeros, to catch a bit stuck high.
    payload = [0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F]
    await spi.sram_write(0x10, payload)
    got = await spi.sram_read(0x10, len(payload))

    assert got == payload, (
        f"walking zeros mismatch: wrote {[hex(v) for v in payload]}, "
        f"read {[hex(v) for v in got]}"
    )


@cocotb.test()
async def test_sram_read_does_not_disturb(dut):
    """Reading a location leaves it and its neighbours intact."""
    spi = await reset(dut)

    payload = [0xA0, 0xA1, 0xA2, 0xA3]
    await spi.sram_write(0x40, payload)

    for _ in range(3):
        got = await spi.sram_read(0x40, 4)
        assert got == payload, (
            f"repeated read changed the contents: {[hex(v) for v in got]}"
        )


@cocotb.test()
async def test_register_access_after_sram_access(dut):
    """The SPI returns to the register map after an SRAM stream.

    sram_ena gates the readback mux, so a failure to clear it would make
    every later register read return SRAM data instead.
    """
    spi = await reset(dut)

    await spi.sram_write(0x00, [0x5A, 0x5A])
    await spi.sram_read(0x00, 2)

    # A fixed register with a known value proves the mux is back.
    from harness import PROD_ID
    prod = await spi.read_reg(REG["prod_id"])
    assert prod == PROD_ID, (
        f"after SRAM access, prod_id read 0x{prod:02x} instead of "
        f"0x{PROD_ID:02x}; sram_ena may not have cleared"
    )
