"""The current bias generator, and the biases it hands the analog blocks.

Everything here is driven from the documented working settings in
harness.BIAS_DEFAULTS rather than from values invented for the test, so
that the suite checks the configuration users will actually be told to
write.  Every trim is an integer count of unit currents;  the unit is
250 nA under these settings, so 1 uA is a count of 4.

These tests do NOT depend on the bandgap trim equation.  They check the
currents, which are exact rational multiples of the unit and will not
move when the bandgap curve is refitted.
"""

import cocotb
from cocotb.triggers import Timer

from harness import (
    REG, reset, isnan, proj_config, proj_bias,
    apply_bias_defaults, bandgap_cfg, biasgen_cfg, voltgen_cfg,
    BIAS_UNIT_A, BIAS_DEFAULTS, BIAS_EXPECTED,
)

SETTLE_NS = 100

# Currents are exact multiples of the unit in this model, so the
# tolerance only has to absorb binary floating point.
ATOL_A = 1e-15


def approx(got, want):
    return abs(got - want) <= ATOL_A + 1e-9 * abs(want)


@cocotb.test()
async def test_bias_defaults_produce_the_documented_currents(dut):
    """The five internal biases come out at their nominal values.

    This is the test that pins the register settings to the currents the
    analog blocks were characterised at.  If a register bit field moves
    in housekeeping.v, or a document value changes, the mismatch lands
    here rather than in a silicon measurement.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)
    await Timer(SETTLE_NS, unit="ns")

    for name, want in BIAS_EXPECTED.items():
        got = float(getattr(dut, f"{name}_ibias").value)
        assert not isnan(got), f"{name} reads NaN with the biasgen enabled"
        assert approx(got, want), (
            f"{name} = {got:g} A, expected {want:g} A "
            f"({want / BIAS_UNIT_A:.0f} units of {BIAS_UNIT_A:g} A)"
        )


@cocotb.test()
async def test_bias_range_checks_pass_with_the_documented_settings(dut):
    """The bandgap and voltgen both accept the biases they are given.

    Both models carry a range check saying their behaviour has only been
    characterised at specific bias currents.  With the documented
    settings programmed, both must be satisfied --- otherwise every
    output either model produces is a number the model is not entitled
    to.

    This is the check that caught the bandgap bias crossing in
    digital_top:  biasgen numbers its bandgap sinks 1 = 1 uA, 2 = 250 nA,
    while the bandgap numbers its inputs 1 = 250 nA, 2 = 1 uA, so pairing
    them by ordinal delivered each one a factor of four off.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)
    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=8))
    await spi.write_reg(REG["voltgen"], voltgen_cfg(ena=0b111, value=0))
    await Timer(SETTLE_NS, unit="ns")

    assert int(dut.bandgap.bias_ok.value) == 1, (
        f"bandgap bias out of range: ibias1_250n = "
        f"{float(dut.bandgap.ibias1_250n.value):g} A (wants -250e-9), "
        f"ibias2_1 = {float(dut.bandgap.ibias2_1.value):g} A (wants -1e-6)"
    )
    assert int(dut.voltgen.bias_ok.value) == 1, (
        f"voltgen bias out of range: "
        f"{float(dut.voltgen.ibias1u_1.value):g}, "
        f"{float(dut.voltgen.ibias1u_2.value):g} (want -1e-6 each), "
        f"{float(dut.voltgen.ibias1u_3.value):g} (wants +1e-6)"
    )


@cocotb.test()
async def test_bias_range_check_rejects_a_wrong_setting(dut):
    """The range check is not vacuous:  a mis-set trim must fail it.

    Without this, a check that is accidentally always true would pass the
    test above and prove nothing.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)
    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=8))
    await Timer(SETTLE_NS, unit="ns")
    assert int(dut.bandgap.bias_ok.value) == 1, "precondition failed"

    # 0x1D = 12 is the documented value.  Halve the 1 uA sink trim.
    await spi.write_reg(REG["bandgap_sink"], 8 | 2)
    await Timer(SETTLE_NS, unit="ns")
    assert int(dut.bandgap.bias_ok.value) == 0, (
        "the bandgap accepted a 500 nA bias where 1 uA was specified;  "
        "the range check is not doing anything"
    )

    await spi.write_reg(REG["bandgap_sink"], 12)
    await Timer(SETTLE_NS, unit="ns")
    assert int(dut.bandgap.bias_ok.value) == 1, \
        "restoring the documented setting did not clear the flag"


@cocotb.test()
async def test_biasgen_disabled_zeroes_every_bias(dut):
    """A disabled biasgen sources and sinks nothing.

    Both unit currents are gated by ena, so all seven outputs go to zero
    together.  Zero, not NaN:  the block is present and off, not absent.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)
    await Timer(SETTLE_NS, unit="ns")
    assert float(dut.bandgap_sink1_ibias.value) != 0.0, "precondition failed"

    await spi.write_reg(REG["biasgen"], biasgen_cfg(ena=0, ref_vbg=1))
    await Timer(SETTLE_NS, unit="ns")

    for name in BIAS_EXPECTED:
        got = float(getattr(dut, f"{name}_ibias").value)
        assert not isnan(got), \
            f"{name} is NaN with the biasgen disabled;  it should be 0 A"
        assert got == 0.0, f"{name} = {got:g} A with the biasgen disabled"

    assert float(dut.user_ibias_shared[0].value) == 0.0, \
        "idac1 still sources current with the biasgen disabled"
    assert float(dut.user_ibias_shared[1].value) == 0.0, \
        "idac2 still sources current with the biasgen disabled"


@cocotb.test()
async def test_idac_outputs_scale_with_the_unit_current(dut):
    """idac1 and idac2 are integer counts of the 250 nA unit."""
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    for count in (0, 1, 4, 17, 31):
        await spi.write_reg(REG["idac1"], count)
        await spi.write_reg(REG["idac2"], 31 - count)
        await Timer(SETTLE_NS, unit="ns")

        got1 = float(dut.user_ibias_shared[0].value)
        got2 = float(dut.user_ibias_shared[1].value)
        assert approx(got1, count * BIAS_UNIT_A), (
            f"idac1 = {count}: {got1:g} A, expected "
            f"{count * BIAS_UNIT_A:g} A"
        )
        assert approx(got2, (31 - count) * BIAS_UNIT_A), (
            f"idac2 = {31 - count}: {got2:g} A, expected "
            f"{(31 - count) * BIAS_UNIT_A:g} A"
        )


@cocotb.test()
async def test_idac_current_reaches_a_project_unclamped(dut):
    """The current a project receives is the current the iDAC sourced.

    The bias switches are analog_pswitch_small, whose voltage model
    clamps its output up to a 0.8 V pMOS floor.  On these nets the real
    carries a CURRENT, so that clamp would hand the project 0.8 A in
    place of a microamp --- a wrong number that still looks like a
    number.  The instances are therefore built with CURRENT_MODE(1), and
    this is what checks that they still are.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    slot, i = 5, 4
    await spi.write_reg(REG["idac1"], 4)        # 1 uA
    await spi.write_reg(REG["idac2"], 8)        # 2 uA
    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await spi.write_reg(REG["proj_bias"], proj_bias(ibias=0b11))
    await Timer(SETTLE_NS, unit="ns")

    for bit, want in ((0, 4 * BIAS_UNIT_A), (1, 8 * BIAS_UNIT_A)):
        got = float(dut.user_ibias[i * 2 + bit].value)
        assert not isnan(got), f"ibias{bit} did not reach slot {slot}"
        assert approx(got, want), (
            f"slot {slot} ibias{bit} = {got:g} A, expected {want:g} A.  "
            f"A value near 0.8 means the switch is clamping a current "
            f"against a voltage floor --- CURRENT_MODE is not set"
        )


@cocotb.test()
async def test_bias_polarity_is_preserved_through_the_switches(dut):
    """Sinks stay negative and sources stay positive at the project.

    biasgen signs its outputs deliberately so that a polarity error shows
    up at the destination rather than being assumed correct.  A clamp, an
    absolute value, or a crossed connection would break the sign.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    slot, i = 16, 15
    await spi.write_reg(REG["idac1"], 4)
    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await spi.write_reg(REG["proj_bias"], proj_bias(ibias=0b01))
    await Timer(SETTLE_NS, unit="ns")

    assert float(dut.user_ibias[i * 2].value) > 0.0, \
        "the iDAC output reached the project with the wrong sign"
    for name in ("bandgap_sink1", "bandgap_sink2",
                 "voltgen_sink1", "voltgen_sink2"):
        assert float(getattr(dut, f"{name}_ibias").value) < 0.0, \
            f"{name} is not a sink"
    assert float(dut.voltgen_source_ibias.value) > 0.0, \
        "voltgen_source is not a source"


@cocotb.test()
async def test_bias_registers_read_back(dut):
    """The documented register values survive a write/read round trip."""
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    for addr, value, meaning in BIAS_DEFAULTS:
        got = await spi.read_reg(addr)
        assert got == value, (
            f"register 0x{addr:02x} ({meaning}) read back 0x{got:02x}, "
            f"wrote 0x{value:02x}"
        )
