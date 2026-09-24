"""Per-slot control:  selection, the dig_ena latch, and the gated clock.

user_project_control was wholly untested, and until the bit_index fix in
digital_top.v it could not be tested at all:  bit_index was one wire in
the generate scope with eighteen continuous assignments, so proj_addr
resolved to x in every instance and "select" never asserted.  These
tests fail loudly if that regresses.

Two of them cover claims the timing constraints make but cannot check,
the same category as test_clocking.py:

  - constraints.sdc leaves the dig_ena latches deliberately untimed,
    because dig_ena is sequenced by software over SPI rather than by a
    clock.  Nothing in static timing covers dig_in -> proj_dig_in, so the
    latch behaviour has to be covered here instead.

  - proj_clk comes from an sg13cmos5l_lgcp_1 clock gate rather than an
    AND of select and clk, specifically so that changing the selected
    project cannot emit a runt pulse or a spurious edge.  The case that
    matters is clk stopped HIGH, which is explicitly permitted --- some
    analog projects stop the clock to keep digital noise down.
"""

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

from harness import REG, reset, proj_config, set_dbus_pattern

SETTLE_NS = 100
CLK_NS = 15                     # the constrained period
NSLOTS = 18


def slot_dig_in(dut, slot):
    """The 24 bits presented to slot N (1..18)."""
    i = slot - 1
    return (int(dut.user_dig_in.value) >> (i * 24)) & 0xFFFFFF


@cocotb.test()
async def test_select_is_one_hot(dut):
    """proj_sel enables exactly one slot, for every one of the 18."""
    spi = await reset(dut)

    for slot in range(1, NSLOTS + 1):
        await spi.write_reg(REG["proj_sel"], slot)
        await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
        await Timer(SETTLE_NS, unit="ns")

        ena = int(dut.user_ena.value)
        want = 1 << (slot - 1)
        assert ena == want, (
            f"proj_sel={slot}: user_ena = 0b{ena:018b}, expected "
            f"0b{want:018b}.  An x here means proj_addr is undriven, which "
            f"is what the bit_index fix addressed"
        )


@cocotb.test()
async def test_slot_zero_selects_nothing(dut):
    """proj_sel = 0 is the diagnostic address and matches no slot."""
    spi = await reset(dut)

    await spi.write_reg(REG["proj_sel"], 0)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await Timer(SETTLE_NS, unit="ns")

    assert int(dut.user_ena.value) == 0, \
        "a slot is enabled with the diagnostic address selected"


@cocotb.test()
async def test_addresses_above_18_select_nothing(dut):
    """proj_sel is five bits;  19..31 are unassigned and must match no slot.

    Worth pinning down because proj_addr is a truncated localparam, so an
    off-by-one in the generate loop would show up as slot 18 answering to
    19 or as slot 1 answering to 0.
    """
    spi = await reset(dut)

    for slot in (19, 20, 31):
        await spi.write_reg(REG["proj_sel"], slot)
        await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
        await Timer(SETTLE_NS, unit="ns")
        assert int(dut.user_ena.value) == 0, \
            f"proj_sel={slot} is unassigned but enabled a slot"


@cocotb.test()
async def test_unselected_slots_see_no_enables(dut):
    """Every project-facing enable is deasserted on unselected slots."""
    spi = await reset(dut)
    slot = 11

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"],
                        proj_config(proj_ena=1, pwr_3v3=1, pwr_1v2=1,
                                    dig_ena=1, analog_bus=0xF))
    await Timer(SETTLE_NS, unit="ns")

    mask = ~(1 << (slot - 1)) & ((1 << NSLOTS) - 1)
    for name in ("user_ena", "user_3v3_ena", "user_1v2_ena"):
        got = int(getattr(dut, name).value)
        assert got & mask == 0, (
            f"{name} = 0b{got:018b} with slot {slot} selected;  an "
            f"unselected slot is enabled"
        )


@cocotb.test()
async def test_dig_in_latch_is_transparent_then_holds(dut):
    """dig_ena opens the input latch;  releasing it freezes the value.

    This is the sequence the latch exists for:  program the routing,
    raise dig_ena so everything arrives at once, then lower it so the
    project sees a stable word while the routing is reprogrammed for the
    next step.  Static timing never sees this path.
    """
    spi = await reset(dut)
    slot = 4

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))

    first = 0xA5C3F0
    await set_dbus_pattern(spi, first)
    await Timer(SETTLE_NS, unit="ns")

    # Latch still closed:  the latch resets to zero while unselected and
    # has not been opened since, so nothing has reached the project.
    assert slot_dig_in(dut, slot) == 0, (
        f"proj_dig_in is 0x{slot_dig_in(dut, slot):06x} before dig_ena was "
        f"ever raised;  the latch is not holding its reset state"
    )

    # Open it:  transparent, so the pattern appears.
    await spi.write_reg(REG["proj_config"],
                        proj_config(proj_ena=1, dig_ena=1))
    await Timer(SETTLE_NS, unit="ns")
    assert slot_dig_in(dut, slot) == first, (
        f"with dig_ena high, proj_dig_in is "
        f"0x{slot_dig_in(dut, slot):06x}, expected 0x{first:06x}"
    )

    # Close it, then change the routing underneath.  The held value must
    # not move.
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await Timer(SETTLE_NS, unit="ns")
    await set_dbus_pattern(spi, 0x5A3C0F)
    await Timer(SETTLE_NS, unit="ns")
    assert slot_dig_in(dut, slot) == first, (
        f"proj_dig_in changed to 0x{slot_dig_in(dut, slot):06x} with "
        f"dig_ena low;  the latch is transparent when it should be holding"
    )

    # Reopen it:  the new value arrives.
    await spi.write_reg(REG["proj_config"],
                        proj_config(proj_ena=1, dig_ena=1))
    await Timer(SETTLE_NS, unit="ns")
    assert slot_dig_in(dut, slot) == 0x5A3C0F, (
        f"reopening the latch did not take the new value;  proj_dig_in is "
        f"0x{slot_dig_in(dut, slot):06x}"
    )


@cocotb.test()
async def test_dig_in_latch_clears_when_deselected(dut):
    """Deselecting a slot resets its input latch to zero.

    RESET_B on the dlhrq cells is ~select, so a project that is no longer
    selected sees all zeros rather than a stale word from whenever it was
    last configured.
    """
    spi = await reset(dut)
    slot = 13

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await set_dbus_pattern(spi, 0xFFFFFF)
    await spi.write_reg(REG["proj_config"],
                        proj_config(proj_ena=1, dig_ena=1))
    await Timer(SETTLE_NS, unit="ns")
    assert slot_dig_in(dut, slot) == 0xFFFFFF, "latch did not open"

    # Select a different slot.  dig_ena is still high, so only the reset
    # can be responsible for clearing it.
    await spi.write_reg(REG["proj_sel"], 14)
    await Timer(SETTLE_NS, unit="ns")
    assert slot_dig_in(dut, slot) == 0, (
        f"slot {slot} still holds 0x{slot_dig_in(dut, slot):06x} after "
        f"being deselected"
    )
    assert slot_dig_in(dut, 14) == 0xFFFFFF, \
        "the newly selected slot did not pick the pattern up"


@cocotb.test()
async def test_only_the_selected_slot_sees_the_bus(dut):
    """The shared bus reaches one project and seventeen zeros."""
    spi = await reset(dut)
    slot = 7

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await set_dbus_pattern(spi, 0xC3A55A)
    await spi.write_reg(REG["proj_config"],
                        proj_config(proj_ena=1, dig_ena=1))
    await Timer(SETTLE_NS, unit="ns")

    for other in range(1, NSLOTS + 1):
        want = 0xC3A55A if other == slot else 0
        got = slot_dig_in(dut, other)
        assert got == want, (
            f"slot {other}: proj_dig_in = 0x{got:06x}, expected 0x{want:06x}"
        )


@cocotb.test()
async def test_proj_clk_runs_only_on_the_selected_slot(dut):
    """The clock gate passes clk to one slot and holds the rest low."""
    spi = await reset(dut)
    slot = 10

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await Timer(SETTLE_NS, unit="ns")

    cocotb.start_soon(Clock(dut.clk, CLK_NS, unit="ns").start())

    seen_high = 0
    for _ in range(40):
        await Timer(CLK_NS / 8, unit="ns")
        seen_high |= int(dut.user_clk.value)

    want = 1 << (slot - 1)
    assert seen_high == want, (
        f"clocks toggled on 0b{seen_high:018b}, expected only "
        f"0b{want:018b}.  A gate stuck open leaves an unselected project "
        f"clocked, and the PnR clock tree was not built for that load"
    )


@cocotb.test()
async def test_proj_clk_has_no_glitch_when_selection_changes(dut):
    """Changing the selected project with clk stopped HIGH emits no edge.

    This is the case an AND gate gets wrong and the reason for the
    lgcp_1:  with clk parked high, asserting select would take the AND
    output straight up, giving the newly selected project a rising edge
    that never came from the clock.  The gate's latch captures select
    only while clk is low, so nothing happens until the next real cycle.
    """
    spi = await reset(dut)

    # Park clk high with nothing selected.
    dut.clk.value = 1
    await Timer(SETTLE_NS, unit="ns")

    old = int(dut.user_clk.value)
    assert old == 0, \
        f"a project clock is already high with no slot selected: 0b{old:018b}"

    # Select a slot while clk stays high.
    await spi.write_reg(REG["proj_sel"], 6)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await Timer(SETTLE_NS, unit="ns")

    got = int(dut.user_clk.value)
    assert got == 0, (
        f"user_clk = 0b{got:018b} after selecting slot 6 with clk parked "
        f"high.  That is a spurious rising edge into the project --- the "
        f"clock gate is behaving like a plain AND"
    )

    # Bring clk low, then high:  now the gate may open, and must.
    dut.clk.value = 0
    await Timer(CLK_NS, unit="ns")
    dut.clk.value = 1
    await Timer(CLK_NS, unit="ns")

    assert int(dut.user_clk.value) == (1 << 5), (
        f"user_clk = 0b{int(dut.user_clk.value):018b} on the first full "
        f"cycle after selection;  slot 6 should now be clocked"
    )


@cocotb.test()
async def test_proj_clk_stops_cleanly_on_deselect(dut):
    """Deselecting with clk parked high does not leave the clock stuck high.

    The mirror of the test above.  The gate closes on the following low
    phase, so the project ends up with its clock at zero rather than
    frozen high, which would hold a latch-based design transparent.
    """
    spi = await reset(dut)

    await spi.write_reg(REG["proj_sel"], 6)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    dut.clk.value = 0
    await Timer(CLK_NS, unit="ns")
    dut.clk.value = 1
    await Timer(CLK_NS, unit="ns")
    assert int(dut.user_clk.value) == (1 << 5), "slot 6 is not clocked"

    # Deselect while clk is high, then complete one cycle.
    await spi.write_reg(REG["proj_sel"], 7)
    dut.clk.value = 0
    await Timer(CLK_NS, unit="ns")
    dut.clk.value = 1
    await Timer(CLK_NS, unit="ns")

    got = int(dut.user_clk.value)
    assert got & (1 << 5) == 0, \
        f"slot 6 is still clocked after deselection: 0b{got:018b}"


@cocotb.test()
async def test_proj_reset_is_synchronised_and_per_slot(dut):
    """The 0x04 command reaches the selected project as a synchronous reset.

    user_project_control_base pushes "select & reset" through a two-stage
    synchroniser on clk, so proj_reset needs a running clock to appear
    and must never appear on an unselected slot.
    """
    spi = await reset(dut)
    slot = 15

    cocotb.start_soon(Clock(dut.clk, CLK_NS, unit="ns").start())

    await spi.write_reg(REG["proj_sel"], slot)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await Timer(SETTLE_NS, unit="ns")
    assert int(dut.user_reset.value) == 0, \
        "a project is held in reset before the command was issued"

    # The digital reset command.  dig_reset stays asserted until CSB
    # rises, and the synchroniser needs two clk edges inside that window,
    # so the clock has to be running --- which it is.
    await spi.start()
    await spi.write_byte(0x04)
    await Timer(4 * CLK_NS, unit="ns")

    got = int(dut.user_reset.value)
    assert got == (1 << (slot - 1)), (
        f"user_reset = 0b{got:018b} during the reset command, expected "
        f"only slot {slot}"
    )

    await spi.end()
    await Timer(4 * CLK_NS, unit="ns")
    assert int(dut.user_reset.value) == 0, \
        "proj_reset did not release when CSB cleared dig_reset"


@cocotb.test()
async def test_dig_out_daisy_chain_is_continuous(dut):
    """The two output chains relay their zero seed through all 18 slots.

    dbus_vec_left[11:0] and dbus_vec_right[11:0] are tied to zero at the
    far end and each slot passes dig_out_relay through when it is not
    both selected and digitally enabled.  So with dig_ena low, the value
    arriving back at housekeeping must be exactly zero --- not x, which
    is what a break or a misindexed slice in the chain would give.

    This is as far as the chain can be checked today:  the slot wrappers
    are empty, so proj_dig_out is undriven and a selected, enabled slot
    injects z rather than data.
    """
    spi = await reset(dut)

    await spi.write_reg(REG["proj_sel"], 9)
    await spi.write_reg(REG["proj_config"], proj_config(proj_ena=1))
    await Timer(SETTLE_NS, unit="ns")

    left = dut.dbus_vec_left.value
    right = dut.dbus_vec_right.value
    assert left.is_resolvable, \
        f"the left dig_out chain carries x: {left}"
    assert right.is_resolvable, \
        f"the right dig_out chain carries x: {right}"
    assert int(left) == 0, f"left chain is 0x{int(left):030x}, expected 0"
    assert int(right) == 0, f"right chain is 0x{int(right):030x}, expected 0"
