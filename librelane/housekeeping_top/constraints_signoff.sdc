#-----------------------------------------------------------------------
# housekeeping_top --- SIGNOFF constraints
#-----------------------------------------------------------------------
#
# Everything in constraints_common.sdc, plus BOTH sram_clk definitions so
# that the sequencer and SPI access modes are both checked.  OpenSTA
# handles two clocks on one port;  only TritonCTS does not, which is why
# place-and-route uses constraints_pnr.sdc instead.
#-----------------------------------------------------------------------

source [file join [file dirname [file normalize [info script]]] constraints_common.sdc]

# The SRAM clock mux output.  Two generated clocks on one port, declared
# logically exclusive because only one source is ever selected.
create_generated_clock -name sram_clk_c -source $clk_port -combinational \
    [get_ports sram_clk]
create_generated_clock -name sram_clk_s -source $sck_port -combinational \
    -add -master_clock SCK -comment "SPI access path" \
    [get_ports sram_clk]

set_clock_groups -logically_exclusive \
    -group {sram_clk_c} -group {sram_clk_s}

# clk_out and sram_clk_c derive from clk;  sram_clk_s derives from SCK.
# Keep the derived clocks in the same asynchronous split as their masters
# so no false cross-domain paths are created.
set_clock_groups -asynchronous \
    -group {clk clk_out sram_clk_c} \
    -group {SCK sram_clk_s}


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

# Corner-aware.  The per-corner signoff STA loads exactly one liberty,
# so the detection is well defined here.
lassign [sram_corner_values] _sc_name _sc_vals _sc_ok

if { $_sc_ok == 1 } {
    puts "\[INFO] SRAM interface timed with $_sc_name values"
    sram_apply {sram_clk_c sram_clk_s} $_sc_vals
} elseif { $_sc_ok == 0 } {
    puts "\[INFO] SRAM interface NOT timed at $_sc_name --- 1.5 V mode, no SRAM model"
    sram_not_timed
} else {
    puts "\[WARNING] SRAM corner could not be determined ($_sc_name);"
    puts "          falling back to the conservative slow_1p08V values."
    sram_apply {sram_clk_c sram_clk_s} $::sram_tim_slow
}
