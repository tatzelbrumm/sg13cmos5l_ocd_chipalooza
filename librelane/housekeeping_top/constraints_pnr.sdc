#-----------------------------------------------------------------------
# housekeeping_top --- PLACE AND ROUTE constraints
#-----------------------------------------------------------------------
#
# Everything in constraints_common.sdc, plus a SINGLE sram_clk definition.
#
# TritonCTS cannot cope with two clocks on one net (CTS-0114), so PnR is
# analysed in the sequencer mode only:  a case analysis pins the clock mux
# select high, which both removes the SCK arc through the mux and selects
# pat_sram_addr on the address mux, so the two are consistent.
#
# This is the demanding mode --- 15 ns rather than 100 ns --- and the hold
# padding the tool adds to the address path applies to the SPI mode too,
# since it is the same physical path with the same 0.849 ns requirement.
# The SPI mode is checked separately;  see constraints_signoff.sdc.
#
# NOTE the case analysis is on the MUX INSTANCE PIN, not on the seq_ena
# net.  Putting it on the net would also force sram_read, the address mux
# and the sequencer/pattern sync_reset, masking real paths.
#-----------------------------------------------------------------------

source [file join [file dirname [file normalize [info script]]] constraints_common.sdc]

# Sequencer mode:  seq_ena = 1 selects clk (mux function is (!S*A0)+(S*A1)
# with A1 = clk), and disables the SCK arc through the mux.
set mux_sel [get_pins -quiet sram_clk_mux/S]
if { [llength $mux_sel] != 1 } {
    puts "\[ERROR] sram_clk_mux/S not found.  The (* keep *) mux instance in"
    puts "        housekeeping_top.v has been renamed or optimised away, so the"
    puts "        clock mux is NOT pinned and CTS will see two clocks on"
    puts "        sram_clk again (CTS-0114).  Fix the name here."
} else {
    set_case_analysis 1 $mux_sel
    puts "\[INFO] clock mux pinned to clk (sequencer mode) for PnR"
}

create_generated_clock -name sram_clk -source $clk_port -combinational \
    [get_ports sram_clk]

set_clock_groups -asynchronous \
    -group {clk clk_out sram_clk} \
    -group {SCK}

#-----------------------------------------------------------------------
# SRAM interface
#-----------------------------------------------------------------------
#
# The SRAM is outside this block, so its setup and hold requirements have
# to be stated here by hand.  Values are the worst case over the three
# characterised corners of RM_IHPSG13_1P_1024x8_c2 (slow 1.08V/125C for
# hold, fast 1.32V/-55C for setup), plus ~0.02 ns for the 18 um route.
#
#   A_CLK -> A_DOUT   7.186 ns   (slow)
#   A_ADDR setup      0.068      hold  0.849
#   A_DIN  setup      0.140      hold  0.652
#   A_WEN  setup      0.849      hold  0.372
#   A_REN  setup      0.458      hold  0.411
#
# Setup is nearly free.  ALL the risk is on hold:  the address is
# launched by a clk-domain flop and captured by the SRAM on the same
# edge, so the launch path has to be longer than the SRAM's hold
# requirement.  The -min terms below, with the hold values negated, are
# what make that a checked constraint rather than an assumption.
#
# WHETHER THIS NEEDS DELAY PADDING DEPENDS ON CTS, so check it in the
# real run rather than assuming either way.
#
# The favourable case:  sram_clk leaves through the mux without going
# through the internal clock tree, while the launching flops sit behind
# CTS, so the natural skew covers the hold requirement.  Roughly 0.45 ns
# of insertion delay is enough against the 0.849 ns address hold, and the
# previous run measured 0.715 ns minimum.
#
# But sram_clk_c is a generated clock, so CTS may instead BALANCE it
# against the internal sinks to minimise skew, which removes exactly that
# advantage.  On the pre-CTS netlist --- no clock tree at all, so the mux
# delay is pure loss --- this shows as about -0.9 ns on sram_addr.  If
# CTS balances, repair_timing will pad the address and data paths with
# delay cells, which is the correct and expected outcome.  Either result
# is fine;  what matters is that it is now a checked constraint instead
# of one of the 420 unconstrained endpoints.

set sram_wire 0.020

# Fixed worst-case values, NOT corner-detected:  place-and-route loads all
# six libraries at once, so the detection in constraints_common.sdc would
# pick an arbitrary one.  The slow 1.08 V numbers are the binding case
# among the three corners where the SRAM is actually qualified, so padding
# to satisfy them satisfies the other two by a wide margin.
puts "\[INFO] SRAM interface: fixed slow_1p08V values for PnR"
sram_apply {sram_clk} $::sram_tim_slow
