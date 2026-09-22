"""SPI driver and register map for the Chipalooza harness housekeeping block.

The SPI timing here mirrors the tasks in verilog/rtl/digital_tb.v exactly:
a quarter-period of 50 ns, so one SCK cycle is 200 ns (5 MHz).  That sits
inside the 10 MHz ceiling the interface is specified for.

Everything in REG below was read out of the odata mux in housekeeping.v
rather than copied from the documentation, so that a divergence between
RTL and documentation shows up as a failing test rather than a test that
agrees with the wrong thing.
"""

from cocotb.triggers import Timer

# SPI quarter-period.  write_byte/read_byte below reproduce the Verilog
# tasks cycle for cycle.
QUARTER_NS = 50

# ---------------------------------------------------------------------
# SPI commands
# ---------------------------------------------------------------------
CMD_NOP         = 0x00
CMD_WRITE       = 0x80  # write stream until CSB raised
CMD_READ        = 0x40  # read stream until CSB raised
CMD_READWRITE   = 0xC0
CMD_SRAM_WRITE  = 0x20
CMD_SRAM_READ   = 0x10
CMD_SRAM_RW     = 0x30
CMD_SEQ_LOOP    = 0x01  # run sequencer, looping
CMD_SEQ_SINGLE  = 0x02  # run sequencer, single shot
CMD_SEQ_STOP    = 0x03
CMD_DIG_RESET   = 0x04

# ---------------------------------------------------------------------
# Register map (from the odata mux in housekeeping.v)
# ---------------------------------------------------------------------
REG = {
    "spi_status":      0x00,
    "mfgr_id_hi":      0x01,
    "mfgr_id_lo":      0x02,
    "prod_id":         0x03,
    "mask_rev_3":      0x04,   # [31:24]
    "mask_rev_2":      0x05,
    "mask_rev_1":      0x06,
    "mask_rev_0":      0x07,   # [7:0]
    "seq_prescaler":   0x0E,
    "pat_prescaler":   0x0F,
    "seq_mode":        0x10,
    "sram_mode":       0x11,
    "seq_start_lo":    0x12,
    "seq_start_hi":    0x13,
    "seq_stop_lo":     0x14,
    "seq_stop_hi":     0x15,
    "pat_stop_lo":     0x16,
    "pat_stop_hi":     0x17,
    "biasgen":         0x18,
    "idac1":           0x19,
    "idac2":           0x1A,
    "voltgen":         0x1B,
    "bandgap":         0x1C,
    "bandgap_sink":    0x1D,
    "voltgen_sink":    0x1E,
    "voltgen_source":  0x1F,
    "in_route_0":      0x20,   # .. 0x37, one nibble each, 24 entries
    "out_route_0":     0x38,   # .. 0x43
    "sram_monitor":    0x4C,
    "strobe_monitor":  0x4D,
    "proj_sel":        0x50,
    "proj_config":     0x51,
    "proj_bias":       0x52,
}

# Expected fixed values, also from housekeeping.v.
MFGR_ID = 0x567
PROD_ID = 0x18


class SPI:
    """Bit-banged SPI master, matching digital_tb.v's tasks."""

    def __init__(self, dut):
        self.dut = dut

    async def _idle(self):
        self.dut.SCK.value = 0
        self.dut.SDI.value = 0

    async def start(self):
        """Assert CSB low and settle."""
        await self._idle()
        self.dut.CSB.value = 0
        await Timer(QUARTER_NS, unit="ns")

    async def end(self):
        """Raise CSB, which also resets the SPI state machine."""
        await self._idle()
        self.dut.CSB.value = 1
        await Timer(QUARTER_NS, unit="ns")

    async def write_byte(self, value):
        """Shift one byte out, MSB first."""
        self.dut.SCK.value = 0
        for i in range(7, -1, -1):
            await Timer(QUARTER_NS, unit="ns")
            self.dut.SDI.value = (value >> i) & 1
            await Timer(QUARTER_NS, unit="ns")
            self.dut.SCK.value = 1
            await Timer(2 * QUARTER_NS, unit="ns")
            self.dut.SCK.value = 0

    async def read_byte(self, allow_x=False):
        """Shift one byte in, MSB first.

        SDO is sampled before the rising edge, because housekeeping_spi
        launches it on the falling edge so that it is stable across the
        rising edge the host captures on.

        An X on SDO is an error by default and raises with the bit
        position, because on a data byte it means the design drove
        something undefined.  allow_x is for the SRAM dummy byte, where X
        is expected.
        """
        value = 0
        self.dut.SCK.value = 0
        self.dut.SDI.value = 0
        for i in range(7, -1, -1):
            await Timer(QUARTER_NS, unit="ns")
            bit = self.dut.SDO.value
            try:
                value |= (int(bit) & 1) << i
            except ValueError:
                if not allow_x:
                    raise AssertionError(
                        f"SDO is {bit} at bit {i}. On a register read this "
                        f"means the readback mux drove X;  on an SRAM read it "
                        f"usually means the location was never written."
                    ) from None
            await Timer(QUARTER_NS, unit="ns")
            self.dut.SCK.value = 1
            await Timer(2 * QUARTER_NS, unit="ns")
            self.dut.SCK.value = 0
        return value

    # -----------------------------------------------------------------
    # Transactions
    # -----------------------------------------------------------------
    async def command(self, cmd):
        """A short command: no address, no data."""
        await self.start()
        await self.write_byte(cmd)
        await self.end()

    async def write_regs(self, addr, values):
        """Write consecutive registers starting at addr (auto-increment)."""
        await self.start()
        await self.write_byte(CMD_WRITE)
        await self.write_byte(addr)
        for v in values:
            await self.write_byte(v)
        await self.end()

    async def read_regs(self, addr, count=1):
        """Read consecutive registers starting at addr (auto-increment)."""
        await self.start()
        await self.write_byte(CMD_READ)
        await self.write_byte(addr)
        out = [await self.read_byte() for _ in range(count)]
        await self.end()
        return out

    async def write_reg(self, addr, value):
        await self.write_regs(addr, [value])

    async def read_reg(self, addr):
        return (await self.read_regs(addr, 1))[0]

    async def sram_write(self, addr, values):
        """Write bytes to SRAM from addr, with auto-increment.

        Note the address byte is only 8 bits, so addresses above 255 are
        reachable only by continuing a stream past 0xFF.
        """
        await self.start()
        await self.write_byte(CMD_SRAM_WRITE)
        await self.write_byte(addr & 0xFF)
        for v in values:
            await self.write_byte(v)
        await self.end()

    async def sram_read(self, addr, count):
        """Read bytes from SRAM starting at addr, with auto-increment.

        THE FIRST BYTE OUT IS A DUMMY AND IS DISCARDED HERE.  The SRAM
        cannot latch the full address by the next SCK edge, so read data
        lags by one byte: the byte shifted out during transfer k+1 is the
        contents of address k, and the byte shifted out during transfer 0
        is whatever happened to be on A_DOUT beforehand (X after reset).
        The note above the read in digital_tb.v records the same quirk.

        Callers therefore get exactly `count` bytes starting at `addr`,
        and do not need to know about the pipeline.
        """
        await self.start()
        await self.write_byte(CMD_SRAM_READ)
        await self.write_byte(addr & 0xFF)
        await self.read_byte(allow_x=True)          # dummy
        out = [await self.read_byte() for _ in range(count)]
        await self.end()
        return out


NAN = float("nan")

# The four shared analog pads, as digital_top exports them.  Each pad is
# two ports because a real cannot be an inout;  see the header comment on
# the port list.
ANALOG_PINS = 4


def drive_pad(dut, pin, value):
    """Drive one of the four shared analog pads from outside the chip.

    NaN means nothing is connected, which is the default.  Anything else
    is a voltage that the on-chip switches can route to a project.
    """
    getattr(dut, f"analog_pin{pin}_in").value = value


def read_pad(dut, pin):
    """The resolved value on one of the four shared analog pads."""
    return float(getattr(dut, f"analog_pin{pin}_out").value)


# How long the POR model holds reset after a power-up, in ns.  This is
# sg13cmos5l_ocd_ip__por's POR_DELAY_NS default;  silicon is ~40 ms, and
# the model is deliberately many orders of magnitude faster.
POR_DELAY_NS = 1000


async def reset(dut, clk_running=True):
    """Bring the DUT up in a known state.

    THERE IS NO porb PORT ANY MORE.  porb is generated on chip by
    sg13cmos5l_ocd_ip__por, so a testbench cannot simply drive it.

    The POR is a ONE-SHOT, not a brown-out detector:  its trickle
    current only ever charges the capacitor, so once the Schmitt trigger
    has tripped, nothing the testbench can do to ena or the supply will
    produce a second reset pulse.  Silicon gets one by being unpowered
    long enough for the capacitor to leak away, and the discharge is not
    characterised, so the model cannot derive it.

    cocotb runs the whole suite in ONE simulation, so without help only
    the first test would see a reset at all.  The deposit below is that
    help:  it puts the POR model back into its asserted state, which
    models "the part has been off long enough to forget", and the model
    then serves a full POR_DELAY_NS before releasing.  It is an explicit
    testbench affordance, and the model documents it as such.
    """
    dut.por.por_int.value = 1
    dut.SCK.value = 0
    dut.SDI.value = 0
    dut.CSB.value = 1
    dut.clk.value = 0
    dut.mask_rev_in.value = 0xDEADBEEF
    dut.io_in.value = 0

    # The shared analog pads start DISCONNECTED, which is NaN and not
    # 0.0.  An undriven "input real" reads 0.0, and 0.0 is a legitimate
    # voltage, so leaving these alone would tell the design that
    # something outside is holding all four pins at ground.
    for pin in range(ANALOG_PINS):
        drive_pad(dut, pin, NAN)

    # Let the deposit take effect, then wait out the POR, then let the
    # released reset propagate.
    await Timer(1, unit="ns")
    await Timer(POR_DELAY_NS, unit="ns")
    await Timer(1000, unit="ns")

    assert int(dut.porb.value) == 1, (
        f"porb is {dut.porb.value} after waiting out the POR.  If it is 0 "
        f"the part never came out of reset, which usually means the POR's "
        f"'ena' is not tied high;  if it is x, ena is undriven."
    )

    return SPI(dut)

# ---------------------------------------------------------------------
# Field encodings, taken from the register write cases in housekeeping.v
# ---------------------------------------------------------------------

def proj_config(proj_ena=0, pwr_3v3=0, pwr_1v2=0, dig_ena=0, analog_bus=0):
    """Register 0x51."""
    return ((proj_ena & 1) | ((pwr_3v3 & 1) << 1) | ((pwr_1v2 & 1) << 2) |
            ((dig_ena & 1) << 3) | ((analog_bus & 0xF) << 4))


def proj_bias(ibias=0, vbias=0):
    """Register 0x52."""
    return (ibias & 0x3) | ((vbias & 1) << 2)


def bandgap_cfg(ena=0, trim=0):
    """Register 0x1C."""
    return (ena & 1) | ((trim & 0x1F) << 1)


def biasgen_cfg(ena=0, coarse=0, fine=0, ref_vbg=0):
    """Register 0x18."""
    return ((ena & 1) | ((coarse & 1) << 1) | ((fine & 1) << 2) |
            ((ref_vbg & 1) << 3))


def voltgen_cfg(ena=0, high=0, value=0):
    """Register 0x1B.  ena is three bits."""
    return (ena & 0x7) | ((high & 1) << 3) | ((value & 0x7) << 4)


def isnan(x):
    """True if a real-valued signal is the NaN "not connected" sentinel."""
    return float(x) != float(x)


# ---------------------------------------------------------------------
# Router input routing (registers 0x20..0x37, one nibble each)
# ---------------------------------------------------------------------
IN_ROUTE_BASE  = 0x20      # dbus_out[k] is configured by 0x20 + k
OUT_ROUTE_BASE = 0x38      # dbus_in[k]  is configured by 0x38 + k

ROUTE_PIN_0    = 0x0       # .. 0xB select io_in[0] .. io_in[11]
ROUTE_CONST_0  = 0xD
ROUTE_CONST_1  = 0xE
ROUTE_SPECIAL  = 0xF       # seq_out[k] for k < 16, sram_out[k-16] above

# NOTE the reset default is 0x0, which routes EVERY one of the 24 bits to
# io_in[0].  There is no "unconnected" code:  0xC is undecoded and falls
# through to the same 1'b0 as 0xD.  So a test that wants a known pattern
# on the shared bus has to program all 24 nibbles, which is what
# set_dbus_pattern does.


async def set_dbus_pattern(spi, value):
    """Drive a fixed 24-bit pattern onto the shared digital input bus.

    Programs each of the 24 input-route nibbles to the constant-0 or
    constant-1 code, so the pattern is independent of io_in and of the
    sequencer.  One auto-incrementing write stream.
    """
    nibbles = [ROUTE_CONST_1 if (value >> k) & 1 else ROUTE_CONST_0
               for k in range(24)]
    await spi.write_regs(IN_ROUTE_BASE, nibbles)


# ---------------------------------------------------------------------
# Bias generator settings
# ---------------------------------------------------------------------
# Every trim in the bias generator is an integer count of unit currents.
# The unit is set by the biasgen configuration and is 250 nA under the
# settings below, so 1 uA is a count of 4, placed in whichever bit field
# the register assigns.  (The bit field positions are in housekeeping.v;
# the main document currently records only the register value to write.)
BIAS_UNIT_A = 250e-9

# The working settings, as supplied.  Written as the register value that
# the documentation gives users, with the decode alongside, so that a
# change to either the document or the RTL shows up as a mismatch here.
BIAS_DEFAULTS = [
    # (register,        value, what it means)
    (REG["biasgen"],        9, "biasgen enable | stabilize with bandgap"),
    (REG["bandgap_sink"],  12, "bandgap sink2 = 1 unit, sink1 = 4 units"),
    (REG["voltgen_sink"],  36, "voltgen sink2 = 4 units, sink1 = 4 units"),
    (REG["voltgen_source"], 4, "voltgen source = 4 units"),
]

# The currents those settings are meant to produce, in amperes, as the
# analog models name them.  Sinks are negative and sources positive by
# the convention in biasgen2, so that the polarity can be checked at the
# destination rather than assumed.
BIAS_EXPECTED = {
    "bandgap_sink1": -4 * BIAS_UNIT_A,      # -1 uA
    "bandgap_sink2": -1 * BIAS_UNIT_A,      # -250 nA
    "voltgen_sink1": -4 * BIAS_UNIT_A,      # -1 uA
    "voltgen_sink2": -4 * BIAS_UNIT_A,      # -1 uA
    "voltgen_source": 4 * BIAS_UNIT_A,      # +1 uA
}


async def apply_bias_defaults(spi):
    """Program the bias generator to its documented working settings."""
    for addr, value, _ in BIAS_DEFAULTS:
        await spi.write_reg(addr, value)
