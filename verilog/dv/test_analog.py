"""Structural tests for the analog switch matrix and bias distribution.

Scoped to things that do NOT depend on the bandgap trim equation or on
the final biasgen settings.  The bandgap model says its own curve is
"linearized between the endpoints ... needs to be simulated and
curve-fit", so asserting 0.96688 + j*0.0203 here would only test that
the model still contains today's placeholder.  Structure survives a
recurve;  numbers do not.

READING REAL SIGNALS.  The disconnected state is NaN, and every
comparison against NaN is false --- including NaN == NaN.  Use
harness.isnan(), never ==.

THE FOUR SHARED ANALOG PADS are exported from digital_top as separate
_in and _out ports, because a real cannot be an inout.  harness.reset
leaves every _in at NaN --- disconnected --- so a test that wants to
drive a pad has to say so with harness.drive_pad.  Note that NaN rather
than 0.0 is what "nothing connected" has to be here:  an undriven
"input real" reads 0.0, and 0.0 is a perfectly good voltage.
"""

import cocotb
from cocotb.triggers import Timer

from harness import (
    REG, NAN, reset, isnan, proj_config, proj_bias, bandgap_cfg, voltgen_cfg,
    apply_bias_defaults, drive_pad, read_pad, ANALOG_PINS,
)

SETTLE_NS = 100

# Dedicated analog pins per slot come from the padframe, but every slot
# has the same four shared bus lines, two current biases and one voltage
# bias, so the switch matrix is uniform and indexes as below.
NSLOTS = 18


async def select_slot(spi, slot, **cfg):
    """Select a slot (1..18, or 0 for the diagnostic path) and configure it."""
    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(**cfg))
    await Timer(SETTLE_NS, unit="ns")


# =====================================================================
# Power gating.  These have a real source (avdd_rail / dvdd_rail), so
# both connectivity and value are checkable.
# =====================================================================

@cocotb.test()
async def test_power_gate_reaches_only_selected_slot(dut):
    """The 3.3 V and 1.2 V gates deliver the rail to one slot only."""
    spi = await reset(dut)

    for slot in (1, 7, 18):
        await select_slot(spi, slot, proj_ena=1, pwr_3v3=1, pwr_1v2=1)
        i = slot - 1

        avdd = float(dut.user_avdd[i].value)
        dvdd = float(dut.user_dvdd[i].value)
        assert not isnan(avdd), f"slot {slot}: 3.3 V gate did not turn on"
        assert abs(avdd - 3.3) < 0.01, f"slot {slot}: avdd = {avdd}, want 3.3"
        assert not isnan(dvdd), f"slot {slot}: 1.2 V gate did not turn on"
        assert abs(dvdd - 1.2) < 0.01, f"slot {slot}: dvdd = {dvdd}, want 1.2"

        for other in range(NSLOTS):
            if other == i:
                continue
            assert isnan(dut.user_avdd[other].value), (
                f"slot {slot} selected, but slot {other+1} also has "
                f"avdd = {float(dut.user_avdd[other].value)};  the power "
                f"gate is not one-hot"
            )
            assert isnan(dut.user_dvdd[other].value), (
                f"slot {slot} selected, but slot {other+1} also has "
                f"dvdd = {float(dut.user_dvdd[other].value)}"
            )


@cocotb.test()
async def test_power_gates_independent(dut):
    """The 3.3 V and 1.2 V gates are controlled separately."""
    spi = await reset(dut)
    i = 4                                       # slot 5

    for p3, p1 in ((1, 0), (0, 1), (1, 1), (0, 0)):
        await select_slot(spi, 5, proj_ena=1, pwr_3v3=p3, pwr_1v2=p1)
        assert (not isnan(dut.user_avdd[i].value)) == bool(p3), \
            f"pwr_3v3={p3}: avdd is {dut.user_avdd[i].value}"
        assert (not isnan(dut.user_dvdd[i].value)) == bool(p1), \
            f"pwr_1v2={p1}: dvdd is {dut.user_dvdd[i].value}"


@cocotb.test()
async def test_deselecting_removes_power(dut):
    """Selecting another slot disconnects the previous one."""
    spi = await reset(dut)

    await select_slot(spi, 3, proj_ena=1, pwr_3v3=1, pwr_1v2=1)
    assert not isnan(dut.user_avdd[2].value), "slot 3 not powered"

    await select_slot(spi, 4, proj_ena=1, pwr_3v3=1, pwr_1v2=1)
    assert isnan(dut.user_avdd[2].value), \
        "slot 3 is still powered after slot 4 was selected"
    assert not isnan(dut.user_avdd[3].value), "slot 4 not powered"


@cocotb.test()
async def test_power_is_off_after_reset(dut):
    """No slot is powered out of reset.

    proj_3v3_ena and proj_1v2_ena both clear on porb, and proj_sel
    defaults to 0, so a project cannot come up powered by accident.
    """
    spi = await reset(dut)
    await Timer(SETTLE_NS, unit="ns")

    for i in range(NSLOTS):
        assert isnan(dut.user_avdd[i].value), \
            f"slot {i+1} has 3.3 V applied out of reset"
        assert isnan(dut.user_dvdd[i].value), \
            f"slot {i+1} has 1.2 V applied out of reset"


# =====================================================================
# Bias switch routing.  A real source exists (biasgen / voltgen), so
# connectivity is checkable.  See GAP 2 on why the value is not.
# =====================================================================

@cocotb.test()
async def test_bias_switches_route_to_selected_slot(dut):
    """The two current biases and the voltage bias reach one slot only."""
    spi = await reset(dut)
    slot, i = 12, 11

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await spi.write_reg(REG["proj_bias"], proj_bias(ibias=0b11, vbias=1))
    await Timer(SETTLE_NS, unit="ns")

    assert not isnan(dut.user_ibias[i * 2 + 0].value), "ibias0 not connected"
    assert not isnan(dut.user_ibias[i * 2 + 1].value), "ibias1 not connected"
    assert not isnan(dut.user_vbias[i].value), "vbias not connected"

    for other in range(NSLOTS):
        if other == i:
            continue
        assert isnan(dut.user_ibias[other * 2 + 0].value), \
            f"slot {other+1} also has ibias0 connected"
        assert isnan(dut.user_ibias[other * 2 + 1].value), \
            f"slot {other+1} also has ibias1 connected"
        assert isnan(dut.user_vbias[other].value), \
            f"slot {other+1} also has vbias connected"


@cocotb.test()
async def test_bias_switches_independent(dut):
    """ibias0, ibias1 and vbias are separately controlled."""
    spi = await reset(dut)
    slot, i = 6, 5

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))

    for ib, vb in ((0b01, 0), (0b10, 0), (0b00, 1), (0b11, 1), (0b00, 0)):
        await spi.write_reg(REG["proj_bias"], proj_bias(ibias=ib, vbias=vb))
        await Timer(SETTLE_NS, unit="ns")
        for bit in (0, 1):
            connected = not isnan(dut.user_ibias[i * 2 + bit].value)
            assert connected == bool(ib & (1 << bit)), \
                f"ibias={ib:02b}: bias {bit} connected={connected}"
        connected = not isnan(dut.user_vbias[i].value)
        assert connected == bool(vb), f"vbias={vb}: connected={connected}"


@cocotb.test()
async def test_vbias_follows_voltgen(dut):
    """The voltage bias delivered to a slot is the voltgen output.

    Only the relationship is asserted, not the absolute voltage:  vout1
    is (s + 1) * vbg / (4 - high), so with the bandgap disabled vbg is
    0.0 and the bias is 0.0 whatever the trim.  Enabling the bandgap must
    make it non-zero, and raising the selector must raise it.  All of
    that holds independently of what the bandgap curve turns out to be.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)
    slot, i = 8, 7

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await spi.write_reg(REG["proj_bias"], proj_bias(vbias=1))

    # voltgen enabled, bandgap off:  the reference is 0 V, so is the bias.
    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=0))
    await spi.write_reg(REG["voltgen"], voltgen_cfg(ena=0b001, value=0))
    await Timer(SETTLE_NS, unit="ns")
    v = float(dut.user_vbias[i].value)
    assert not isnan(v), "vbias switch is on but reads NaN"
    assert abs(v) < 1e-9, f"voltgen has no reference but put out {v} V"

    # Bandgap on:  the bias must follow it.
    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=8))
    await Timer(SETTLE_NS, unit="ns")
    base = float(dut.user_vbias[i].value)
    assert base > 0.0, f"voltgen did not follow the bandgap: {base} V"

    # And the selector must move it monotonically upward.
    last = base
    for s in range(1, 8):
        await spi.write_reg(REG["voltgen"], voltgen_cfg(ena=0b001, value=s))
        await Timer(SETTLE_NS, unit="ns")
        v = float(dut.user_vbias[i].value)
        assert v > last, \
            f"voltgen selector {s} gave {v} V, not above {last} V at {s-1}"
        last = v


@cocotb.test()
async def test_voltgen_disabled_is_zero_not_floating(dut):
    """A disabled voltgen outputs 0 V, which is different from NaN.

    0.0 is the correct off value for a generator --- it really does sit
    at ground --- whereas NaN means "not connected".  Confusing the two
    is the whole reason the sentinel exists, so the distinction is worth
    pinning down at the point it reaches a project.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)
    slot, i = 2, 1

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await spi.write_reg(REG["proj_bias"], proj_bias(vbias=1))
    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=16))
    await spi.write_reg(REG["voltgen"], voltgen_cfg(ena=0b000, value=7))
    await Timer(SETTLE_NS, unit="ns")

    v = float(dut.user_vbias[i].value)
    assert not isnan(v), \
        "a disabled voltgen reads NaN;  it should be a connected 0 V"
    assert abs(v) < 1e-9, f"disabled voltgen put out {v} V"


# =====================================================================
# Analog bus switches.
# =====================================================================

@cocotb.test()
async def test_analog_bus_enables_are_one_hot(dut):
    """Only the selected slot's four bus switches are enabled."""
    spi = await reset(dut)

    for slot in (1, 9, 18):
        await select_slot(spi, slot, proj_ena=1, analog_bus=0xF)
        ena = int(dut.user_analog_ena.value)
        want = 0xF << ((slot - 1) * 4)
        assert ena == want, (
            f"slot {slot}: user_analog_ena = 0x{ena:018x}, expected "
            f"0x{want:018x};  another slot's bus switches are also on"
        )


@cocotb.test()
async def test_analog_bus_lines_independent(dut):
    """analog_bus_ena selects the four lines individually, not as a block."""
    spi = await reset(dut)
    slot, i = 2, 1

    for pattern in (0b0001, 0b0010, 0b0100, 0b1000, 0b1010, 0b0000):
        await select_slot(spi, slot, proj_ena=1, analog_bus=pattern)
        got = (int(dut.user_analog_ena.value) >> (i * 4)) & 0xF
        assert got == pattern, (
            f"analog_bus={pattern:04b}: slot {slot} switches are "
            f"{got:04b}"
        )


@cocotb.test()
async def test_analog_bus_is_not_connected_to_any_slot_after_reset(dut):
    """Out of reset no slot touches the four shared analog pins.

    This one is a value check and it works, because NaN is the expected
    answer:  every bus switch is off, so nothing can reach a project
    whatever is on the pins.
    """
    spi = await reset(dut)
    await Timer(SETTLE_NS, unit="ns")

    assert int(dut.user_analog_ena.value) == 0, \
        "an analog bus switch is enabled out of reset"
    for k in range(NSLOTS * 4):
        assert isnan(dut.user_analog[k].value), \
            f"slot {k//4 + 1} bus line {k%4} is connected out of reset"


# =====================================================================
# Project zero:  the diagnostic path onto the four shared analog pins.
# =====================================================================

@cocotb.test()
async def test_project_zero_asserted_only_for_slot_zero(dut):
    """project_zero follows proj_sel == 0, which is also the reset state."""
    spi = await reset(dut)

    # Slot 0 is the reset default, so project_zero starts asserted.
    assert int(dut.project_zero.value) == 1, \
        "project_zero is not asserted out of reset, but proj_sel resets to 0"

    for slot in (1, 5, 18):
        await spi.write_reg(REG["proj_sel"], slot)
        await Timer(SETTLE_NS, unit="ns")
        assert int(dut.project_zero.value) == 0, \
            f"project_zero asserted while slot {slot} is selected"

    await spi.write_reg(REG["proj_sel"], 0)
    await Timer(SETTLE_NS, unit="ns")
    assert int(dut.project_zero.value) == 1, \
        "project_zero not re-asserted when slot 0 was selected again"


@cocotb.test()
async def test_diagnostic_switches_drive_the_shared_pins(dut):
    """Selecting project 0 puts the internal biases on the shared pins.

    The four diagnostic switches are the only drivers of
    user_analog_shared in this model, so this is also the only case in
    which those nets carry a value at all (GAP 1 above).  Line 3 is the
    bandgap, which makes it the one that can be checked against a
    changing source without knowing the trim curve.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    # Slot 0 selected, bandgap off.
    await spi.write_reg(REG["proj_sel"], 0)
    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=0))
    await Timer(SETTLE_NS, unit="ns")

    for line in range(4):
        assert not isnan(dut.user_analog_shared[line].value), (
            f"diagnostic switch {line} is off with project 0 selected;  "
            f"the shared analog pin cannot see the internal bias"
        )

    off = float(dut.user_analog_shared[3].value)
    assert abs(off) < 1e-9, f"bandgap disabled but pin 3 reads {off} V"

    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=16))
    await Timer(SETTLE_NS, unit="ns")
    on = float(dut.user_analog_shared[3].value)
    assert on > off, \
        f"pin 3 did not follow the bandgap: {off} V off, {on} V on"

    # Any other slot closes all four.
    await spi.write_reg(REG["proj_sel"], 7)
    await Timer(SETTLE_NS, unit="ns")
    for line in range(4):
        assert isnan(dut.user_analog_shared[line].value), (
            f"diagnostic switch {line} is still on with slot 7 selected;  "
            f"an internal bias would be shorted to the shared pin while a "
            f"project is using it"
        )


# =====================================================================
# Bandgap.  Structure only;  the trim equation is still being fitted.
# =====================================================================

@cocotb.test()
async def test_bandgap_off_is_zero_and_on_is_plausible(dut):
    """The bandgap is 0 V disabled and in a believable band enabled."""
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=0))
    await Timer(SETTLE_NS, unit="ns")
    v = float(dut.vbandgap.value)
    assert not isnan(v), "a disabled bandgap should be a connected 0 V, not NaN"
    assert abs(v) < 1e-9, f"disabled bandgap reads {v} V"

    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=8))
    await Timer(SETTLE_NS, unit="ns")
    v = float(dut.vbandgap.value)
    assert not isnan(v), "enabled bandgap reads NaN"
    assert 0.5 < v < 2.0, (
        f"enabled bandgap = {v} V.  This is a sanity bound on a 1.2 V "
        f"class reference, not a spec check --- if the fitted curve ever "
        f"lands outside it, widen the bound deliberately"
    )


@cocotb.test()
async def test_bandgap_trim_is_monotonic_and_saturates(dut):
    """Raising the trim code never lowers the output, and it stops at 16.

    housekeeping.v decodes the 5-bit setting as a thermometer code,
    bandgap_trim[i] = (bandgap_trim_set > i) over 16 bits, so codes above
    16 are all the same setting.  Both properties should survive the
    pending curve-fit;  the coefficients will not, which is why they are
    not asserted anywhere here.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    last = None
    for trim in range(0, 17):
        await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=trim))
        await Timer(SETTLE_NS, unit="ns")
        v = float(dut.vbandgap.value)
        assert not isnan(v), f"trim={trim}: bandgap reads NaN"
        assert int(dut.bandgap_trim.value).bit_count() == trim, (
            f"trim={trim}: thermometer code is "
            f"0x{int(dut.bandgap_trim.value):04x}, which has "
            f"{int(dut.bandgap_trim.value).bit_count()} bits set"
        )
        if last is not None:
            assert v >= last, (
                f"bandgap not monotonic: trim {trim-1} gave {last} V, "
                f"trim {trim} gave {v} V"
            )
        last = v

    for trim in (17, 24, 31):
        await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=trim))
        await Timer(SETTLE_NS, unit="ns")
        v = float(dut.vbandgap.value)
        assert abs(v - last) < 1e-12, (
            f"the thermometer code saturates at 16, but trim={trim} gave "
            f"{v} V against {last} V at trim=16"
        )


# =====================================================================
# The shared analog pads, driven from outside the chip.
# =====================================================================

@cocotb.test()
async def test_pads_are_disconnected_by_default(dut):
    """With nothing driving a pad, the pad reads as disconnected."""
    spi = await reset(dut)
    await spi.write_reg(REG["proj_sel"], 3)      # not the diagnostic slot
    await Timer(SETTLE_NS, unit="ns")

    for pin in range(ANALOG_PINS):
        assert isnan(read_pad(dut, pin)), (
            f"pad {pin} reads {read_pad(dut, pin)} with nothing driving it "
            f"and no diagnostic switch on.  A 0.0 here means an undriven "
            f"real port is being read as a connected zero volts"
        )


@cocotb.test()
async def test_pad_voltage_reaches_only_the_selected_slot(dut):
    """A voltage on a shared pad arrives at one project, on one line.

    The end-to-end path:  pad -> resolving mux -> per-slot bus switch ->
    project.  Each of the four pads is driven with a different voltage so
    that a transposition between lines cannot pass.
    """
    spi = await reset(dut)
    slot, i = 14, 13
    volts = (0.25, 1.10, 2.00, 3.05)

    for pin, v in enumerate(volts):
        drive_pad(dut, pin, v)

    await select_slot(spi, slot, proj_ena=1, analog_bus=0xF)

    for line, want in enumerate(volts):
        got = float(dut.user_analog[i * 4 + line].value)
        assert not isnan(got), \
            f"slot {slot} line {line} is NaN;  the pad drive did not arrive"
        assert abs(got - want) < 1e-9, (
            f"slot {slot} line {line} = {got} V, expected {want} V.  "
            f"A value belonging to another line means the bus is "
            f"transposed"
        )

    for other in range(NSLOTS):
        if other == i:
            continue
        for line in range(4):
            assert isnan(dut.user_analog[other * 4 + line].value), (
                f"slot {other+1} line {line} is also connected to the "
                f"shared pin while slot {slot} is selected"
            )


@cocotb.test()
async def test_pad_is_gated_by_its_own_bus_enable(dut):
    """Each bus line can be opened and closed independently of the pad."""
    spi = await reset(dut)
    slot, i = 2, 1
    drive_pad(dut, 1, 1.8)

    await select_slot(spi, slot, proj_ena=1, analog_bus=0b0010)
    assert abs(float(dut.user_analog[i * 4 + 1].value) - 1.8) < 1e-9, \
        "line 1 did not open"
    for line in (0, 2, 3):
        assert isnan(dut.user_analog[i * 4 + line].value), \
            f"line {line} is connected but its enable is clear"

    await select_slot(spi, slot, proj_ena=1, analog_bus=0b0000)
    assert isnan(dut.user_analog[i * 4 + 1].value), \
        "line 1 stayed connected after its enable was cleared"


@cocotb.test()
async def test_diagnostic_drive_takes_precedence_over_the_pad(dut):
    """When the chip drives a pad, the chip wins.

    Selecting project 0 closes the four diagnostic switches onto the
    shared pins.  Something driving the pin from outside at the same time
    is a contention the real circuit would resolve by its output
    impedances;  the model resolves it in favour of the internal driver,
    and the point of the test is that the behaviour is defined rather
    than dependent on elaboration order.
    """
    spi = await reset(dut)
    await apply_bias_defaults(spi)

    drive_pad(dut, 3, 2.5)
    await spi.write_reg(REG["proj_sel"], 3)
    await Timer(SETTLE_NS, unit="ns")
    assert abs(read_pad(dut, 3) - 2.5) < 1e-9, \
        "the pad drive is not reaching the pin with no slot selected"

    # Project 0 closes the diagnostic switch for the bandgap onto pin 3.
    await spi.write_reg(REG["bandgap"], bandgap_cfg(ena=1, trim=16))
    await spi.write_reg(REG["proj_sel"], 0)
    await Timer(SETTLE_NS, unit="ns")

    v = read_pad(dut, 3)
    assert abs(v - 2.5) > 1e-9, \
        "the diagnostic switch is closed but the pad drive still wins"
    assert abs(v - float(dut.vbandgap.value)) < 1e-12, \
        f"pin 3 reads {v} V, but the bandgap is at {float(dut.vbandgap.value)} V"

    # Releasing the pad leaves the diagnostic value in place.
    drive_pad(dut, 3, NAN)
    await Timer(SETTLE_NS, unit="ns")
    assert abs(read_pad(dut, 3) - float(dut.vbandgap.value)) < 1e-12, \
        "releasing the pad disturbed the diagnostic measurement"
