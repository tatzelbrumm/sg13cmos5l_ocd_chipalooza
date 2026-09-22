#-----------------------------------------------------------------------
# Timing constraints for housekeeping_top --- COMMON
#
# Shared by constraints_pnr.sdc and constraints_signoff.sdc, which add
# the sram_clk definitions and the SRAM interface delays.  Never point
# LibreLane at this file directly:  on its own it leaves sram_clk
# undefined.
#
# WHY THE SPLIT.  sram_clk is a clock mux output and wants two generated
# clocks on one port, one per source.  OpenSTA handles that correctly,
# but TritonCTS refuses it:
#     [ERROR CTS-0114] Clock sram_clk_s overlaps a previous clock.
# So place-and-route analyses the sequencer mode only, with a case
# analysis forcing the mux, and signoff analyses both.  See each file.
#-----------------------------------------------------------------------
#
# CLOCK STRUCTURE.  This block has two asynchronous primary clocks and
# three derived ones, which is why the templated base.sdc could never
# describe it:  that file only ever constrains the first entry of
# CLOCK_PORT, so every previous run left the whole SCK domain invisible
# to both STA and CTS.  For the record, the last run before this file
# existed reported "324 unclocked register/latch pins" and "420
# unconstrained endpoints".
#
#   clk        primary.  Sequencer, pattern generator and LFSR.
#   SCK        primary.  SPI shift registers (both edges) and the whole
#              configuration register file.  Asynchronous to clk.
#
#   clk_out    generated from clk, exported to the user projects.
#   sram_clk   generated, TWO definitions on one port --- the output of
#              the sram_clk_mux, which selects clk when the sequencer is
#              running and SCK otherwise.
#
# There is deliberately NO seq_strobe clock any more.  It used to be a
# registered SPI output used as "posedge seq_strobe" to capture seq_mode,
# but both were assigned on the same SCK edge, so the capture flop
# sampled its own data as it changed --- STA measured -0.505 ns of hold
# slack once seq_strobe was declared a clock, and before that it was
# invisible because those flops were unclocked.  housekeeping_spi.v now
# decodes the command combinationally into seq_load, and seq_ena and
# loop_mode are ordinary SCK flops with an enable.  If a seq_strobe
# clock ever reappears here, the restructure has been reverted.
#
# EXPECTED check_setup OUTPUT.  With this file the only thing it should
# report is 2 unconstrained endpoints, "clk_out" and "sram_clk".  Both are
# output ports carrying a clock rather than data endpoints, so that is
# correct.  Anything else --- in particular any "unclocked register/latch
# pins" --- is a real problem.  For scale, the last run before this file
# existed reported 324 unclocked pins and 420 unconstrained endpoints.
#
# THE TWO SRAM CLOCKS ARE DECLARED LOGICALLY EXCLUSIVE.  That is an
# assertion about the design, not something the tool can verify:  it
# relies on the documented rule that "SRAM cannot be accessed while the
# sequencer is running", so seq_ena never changes with an access in
# flight.  It needs to be demonstrated in the cocotb tests rather than
# assumed --- specifically that no SRAM access can be initiated while
# seq_ena is set, and that changing seq_ena cannot produce an edge on
# sram_clk that the SRAM sees as a clock.
#
#-----------------------------------------------------------------------
# Tunables
#-----------------------------------------------------------------------

if { [info exists ::env(CLOCK_PERIOD)] } {
    set clk_period $::env(CLOCK_PERIOD)
} else {
    set clk_period 15.0
}

# SPI clock.  Driven by pyftdi over USB;  the interface is for
# communication, not real-time signalling, so 10 MHz is a ceiling rather
# than a target.
set sck_period      100.0

set io_delay        [expr {$clk_period * 0.20}]
set sck_io_delay    [expr {$sck_period * 0.20}]

set clk_uncertainty 0.25
set clk_transition  0.15
set time_derate     5.0

set max_fanout      10
set driving_cell    "sg13cmos5l_buf_4/X"

# Design-rule limits.  The library default max_transition is 2.5074 ns.
# Leaving it there is what let an early run finish with 4.589 ns of clock
# skew and 56 nets past the library's OWN limit at nom_slow_1p08V_125C:
# nothing was forcing the long clock wires to keep a sharp edge.  See
# also CTS_CLK_MAX_WIRE_LENGTH in config.yaml, which was 1200 um in a
# 1255 um wide block and is now back to the default.
#
# 1.0 ns is an aspirational target, NOT a signoff criterion, and it is
# deliberately tighter than anything can be expected to meet.  Read the
# max-slew numbers with that in mind:
#
#   - At nom_slow_1p08V_125C the design reports ~521 violations against
#     this 1.0 ns.  The worst actual slew is 2.05 ns and the median is
#     ~1.25 ns, so EVERY one of them is inside the library's own
#     2.5074 ns limit.  Before this constraint existed, 56 nets were past
#     that library limit.  So the tightening worked;  the violation count
#     went up because the ruler got stricter, not because the design got
#     worse.
#   - ZERO of those violators are on a clock net.  The clock trees meet
#     1.0 ns outright.  That is the part that matters and it is why this
#     stays tight:  a loose limit here is half of what produced 4.589 ns
#     of clock skew.
#   - Checker.MaxSlewViolations does not gate (MAX_SLEW_VIOLATION_CORNERS
#     is the match-nothing wildcard), so this costs nothing but noise.
#
# If a CLOCK net ever shows up in the max-slew violator list, that is a
# real regression;  look at CTS rather than relaxing this number.
#
# Do not try to express this as a tighter limit on [all_clocks]:  in
# OpenSTA that constrains every pin in the clock's DOMAIN, not the clock
# network, so it lands on data pins and makes things far worse.
set max_transition  1.0

#-----------------------------------------------------------------------
# Output loads
#-----------------------------------------------------------------------
#
# Three distinct classes;  a single OUTPUT_CAP_LOAD cannot describe them.

# The SRAM sits ~18 um away with one M2/M3 layer change.  ~1.7 fF of
# wire (93 aF/um) plus ~8 fF of SRAM pin capacitance.
set load_sram       0.010

# Bias and diagnostic outputs:  a few gates 300-350 um away.
set load_local      0.045

# The trunk up the centre of the chip, branching to all 18 control
# blocks.  ~2.5 mm of wire plus 18 antenna diodes and gate inputs.
#
# TODO: this is an estimate and it is the least certain number in this
# file.  If the trunk gets repeater buffers --- which is likely the right
# answer for clk_out --- then the load seen HERE drops to just the first
# repeater and this should come down accordingly.  Revisit once the
# trunk routing is decided.
set load_trunk      0.300

#-----------------------------------------------------------------------
# Port groups
#-----------------------------------------------------------------------

set clk_port [get_ports clk]
set sck_port [get_ports SCK]

# Asynchronous / static inputs that must not be timed against a clock:
#   porb        power-on reset, asynchronous
#   CSB         SPI chip select;  asynchronously resets the SPI
#   mask_rev_in metal-programmed constant in the 3.3 V domain
set async_inputs [get_ports {porb CSB mask_rev_in[*]}]

# Inputs that arrive asynchronously from pads or from the project slots
# and reach outputs only through the combinational router.
set feedthrough_inputs [get_ports {io_in[*] dbus_in_left[*] dbus_in_right[*]}]

# SRAM interface
set sram_out_ports  [get_ports {sram_addr[*] sram_idata[*] sram_read sram_write}]

# Outputs driven by the SCK-domain configuration registers, going up the
# trunk to the control blocks and out to the bias generators.
set config_outputs [get_ports {reset proj_sel[*] proj_ena proj_dig_ena \
                               proj_3v3_ena proj_1v2_ena proj_ibias_ena[*] \
                               proj_vbias_ena analog_bus_ena[*] \
                               idac1_value[*] idac2_value[*] \
                               voltgen_ena[*] voltgen_high voltgen_value[*] \
                               bandgap_ena bandgap_trim[*] \
                               biasgen_ena biasgen_coarse biasgen_fine \
                               biasgen_ref_vbg \
                               bandgap_sink1[*] bandgap_sink2[*] \
                               voltgen_sink1[*] voltgen_sink2[*] \
                               voltgen_source[*] project_zero}]

# Outputs driving the trunk up the centre of the chip to all 18 control
# blocks.  These deliberately drive a large load;  see $load_trunk.
set trunk_outputs [get_ports {clk_out reset dbus_out[*] proj_sel[*] \
                              proj_ena proj_dig_ena proj_3v3_ena \
                              proj_1v2_ena proj_ibias_ena[*] \
                              proj_vbias_ena analog_bus_ena[*]}]

# Router outputs:  combinational from io_in / dbus_in and from the
# SCK-domain routing registers.
set router_outputs [get_ports {dbus_out[*] io_out[*] io_oe[*]}]

#-----------------------------------------------------------------------
# Primary clocks
#-----------------------------------------------------------------------

create_clock -name clk -period $clk_period $clk_port
create_clock -name SCK -period $sck_period $sck_port

# clk and SCK are unrelated:  clk is a free-running external clock that
# may even be stopped, SCK is driven by the host only during a transfer.
set_clock_groups -asynchronous -group {clk} -group {SCK}

#-----------------------------------------------------------------------
# Generated clocks
#-----------------------------------------------------------------------

# Buffered copy of clk handed to the user projects.
create_generated_clock -name clk_out -source $clk_port -divide_by 1 \
    [get_ports clk_out]

#-----------------------------------------------------------------------
# Clock properties
#-----------------------------------------------------------------------

set_clock_uncertainty $clk_uncertainty [all_clocks]
set_clock_transition  $clk_transition  [all_clocks]

set_timing_derate -early [expr {1.0 - ($time_derate / 100.0)}]
set_timing_derate -late  [expr {1.0 + ($time_derate / 100.0)}]

if { [info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS) } {
    unset_propagated_clock [all_clocks]
} else {
    set_propagated_clock [all_clocks]
}

#-----------------------------------------------------------------------
# Environment
#-----------------------------------------------------------------------

set_max_fanout      $max_fanout      [current_design]
set_max_transition  $max_transition  [current_design]

# NOTE:  deliberately NO design-wide set_max_capacitance.
#
# A blanket 0.2 pF was tried and is wrong twice over.  It contradicts
# this file's own $load_trunk of 0.3 pF, producing exactly 42 max-cap
# violations --- one per trunk port --- against a load the file itself
# asserts.  And it is arbitrary:  the cells driving those ports are
# rated by their own liberty for far more (buf_4 1.2 pF, buf_8 2.4 pF,
# buf_16 4.8 pF), so 0.2 pF is 16x tighter than the hardware needs.
#
# Capacitance is the wrong knob anyway.  set_max_transition above is the
# physically meaningful constraint and is what shapes the design;  the
# per-cell liberty max_capacitance remains as an electrical backstop.
# Putting a limit on a port does not help either --- the check lands on
# the DRIVING PIN, so it just relocates the violation.

set_driving_cell \
    -lib_cell [lindex [split $driving_cell "/"] 0] \
    -pin      [lindex [split $driving_cell "/"] 1] \
    [all_inputs]

set_load $load_local [all_outputs]
set_load $load_sram  $sram_out_ports
set_load $load_sram  [get_ports sram_clk]
set_load $load_trunk $trunk_outputs



#-----------------------------------------------------------------------
# Asynchronous and static inputs
#-----------------------------------------------------------------------

# porb and CSB are asynchronous resets;  mask_rev_in is a metal-programmed
# constant that only ever reaches SDO through the readback mux.
set_false_path -from $async_inputs

# Declared only so that check_setup does not list them as "missing
# set_input_delay".  The false path above is what actually governs them,
# and the feedthrough inputs are governed by the set_max_delay at the end
# of this file.
set_input_delay 0 -clock SCK $async_inputs
set_input_delay 0 -clock clk $feedthrough_inputs

#-----------------------------------------------------------------------
# SPI interface (SCK domain)
#-----------------------------------------------------------------------
#
# SDI is a synchronous data input sampled on SCK edges.  The previous
# base.sdc declared "set_false_path -from [get_ports SDI]", which threw
# away the only real input timing constraint the SPI has.
set_input_delay $sck_io_delay -clock SCK [get_ports SDI]

# SDO is launched on the falling edge of SCK so that it is stable at the
# host's next rising edge;  sdo_ena follows it.
set_output_delay $sck_io_delay -clock SCK -clock_fall [get_ports {SDO sdo_ena}]

#-----------------------------------------------------------------------
# Configuration outputs (SCK domain)
#-----------------------------------------------------------------------
#
# Written by SPI register writes and then held.  Nothing downstream
# samples them against a clock, so they are budgeted rather than timed
# against a capture edge.  The budget exists so the endpoints are
# constrained and so the trunk drivers are forced to produce a sane edge
# into $load_trunk.
set_output_delay $sck_io_delay -clock SCK $config_outputs

#-----------------------------------------------------------------------
# Router feedthroughs
#-----------------------------------------------------------------------
#
# router.v is purely combinational, so io_in -> dbus_out and
# dbus_in_* -> io_out are pad-to-project and project-to-pad paths with no
# clock anywhere.  They were a large part of the 420 unconstrained
# endpoints.  Their delay is what a user project actually experiences
# when driving or observing a shared digital pin, so it is worth bounding
# even though nothing captures it synchronously.
# One budget covers everything reaching these ports, both the
# asynchronous feedthroughs and the SCK-domain routing registers that
# also drive them.  Do NOT add a set_output_delay on top:  the two
# compound at a shared endpoint (the output delay is subtracted from the
# max_delay's required time), which made an 8 ns budget read as -12 ns
# and reported a 14.8 ns violation on a path that is actually 2.6 ns.
#
# Measured depth is 14 logic levels, 2.58 ns at nom_slow_1p08V_125C on a
# non-timing-driven netlist, so 8 ns is comfortable.  dbus_out also has
# to charge the trunk load, which is the slower part.
set_max_delay 8.0 -to $router_outputs

#-----------------------------------------------------------------------
# SRAM interface timing
#-----------------------------------------------------------------------
#
# RM_IHPSG13_1P_1024x8_c2 is characterised at exactly three corners, and
# they line up precisely with this chip's 1.2 V operating mode:
#
#     SRAM corner          matches STA corner
#     slow_1p08V_125C      nom_slow_1p08V_125C
#     typ_1p20V_25C        nom_typ_1p20V_25C
#     fast_1p32V_m55C      nom_fast_1p32V_m40C
#
# The other three STA corners (1.35 / 1.50 / 1.65 V) are the 1.5 V mode,
# nominal +/-10%, and the SRAM is characterised at NONE of them.
#
# THE SRAM IS DELIBERATELY NOT TIMED IN THE 1.5 V MODE.  Running the
# digital at 1.5 V is a supported option --- block designers asked for it
# and the transistors are rated for continuous 1.5 V operation, so
# nothing is damaged --- but IHP does not characterise this SRAM there,
# so there is no honest number to check against.  The caveat that goes
# with the 1.5 V mode is therefore: the pattern generator and its memory
# are not qualified above 1.32 V.  A designer running at 1.5 V either
# does not use the pattern generator, or does so at their own risk.
#
# Inventing numbers for those corners is what the first run effectively
# did, by applying the 1.08 V values everywhere.  It produced 17 hold
# violations on sram_addr / sram_idata / sram_read --- none of them
# register-to-register, all of them artifacts of demanding 0.849 ns of
# hold where the part needs far less.  Extrapolating instead would have
# been a guess dressed up as a constraint.  Declaring the paths unchecked
# says what is actually true.
#
# NOTE ON THE CORNER DETECTION BELOW.  It reads the loaded standard-cell
# liberty, because LibreLane does not name the active corner in the
# environment.  That only works where exactly ONE liberty is loaded,
# which is the case for the per-corner signoff STA but NOT during
# place-and-route, where all six are read at once.  So only
# constraints_signoff.sdc uses it;  constraints_pnr.sdc uses the fixed
# worst-case values instead.  The proc returns "MULTI" if it sees more
# than one, so a mistake is loud rather than silent.

# {addr_su addr_hd din_su din_hd wen_su wen_hd ren_su ren_hd dout}
set ::sram_tim_slow {-0.198 0.849 -0.001 0.652 0.849 0.372 0.458 0.411 7.186}
set ::sram_tim_typ  {-0.003 0.525  0.115 0.399 0.607 0.247 0.376 0.271 4.304}
set ::sram_tim_fast { 0.068 0.341  0.140 0.264 0.447 0.177 0.302 0.189 2.651}

# Returns {corner-name values qualified}.  qualified == 0 means the SRAM
# has no model at this corner and its paths must not be timed.
proc sram_corner_values {} {
    set libs {}
    foreach l [get_libs -quiet *] {
	set n [get_full_name $l]
	if { [string match "*stdcell*" $n] } { lappend libs $n }
    }
    if { [llength $libs] != 1 } {
	return [list "MULTI ([llength $libs] libs)" $::sram_tim_slow -1]
    }
    set libname [lindex $libs 0]

    if { [string match "*slow_1p08V*" $libname] } { return [list slow_1p08V $::sram_tim_slow 1] }
    if { [string match "*typ_1p20V*"  $libname] } { return [list typ_1p20V  $::sram_tim_typ  1] }
    if { [string match "*fast_1p32V*" $libname] } { return [list fast_1p32V $::sram_tim_fast 1] }

    # 1.5 V mode corners:  no SRAM model, not timed.
    if { [string match "*1p35V*" $libname] } { return [list 1p35V $::sram_tim_slow 0] }
    if { [string match "*1p50V*" $libname] } { return [list 1p50V $::sram_tim_slow 0] }
    if { [string match "*1p65V*" $libname] } { return [list 1p65V $::sram_tim_slow 0] }

    return [list "UNRECOGNISED" $::sram_tim_slow -1]
}

# Applies the SRAM interface constraints for one or more sram clocks.
# $vals is a nine-element list as above.
proc sram_apply {clocks vals} {
    set wire 0.020
    lassign $vals addr_su addr_hd din_su din_hd wen_su wen_hd ren_su ren_hd dout
    foreach sc $clocks {
	set_output_delay -clock $sc -max [expr { $addr_su + $wire}] -add_delay [get_ports {sram_addr[*]}]
	set_output_delay -clock $sc -min [expr {-$addr_hd + $wire}] -add_delay [get_ports {sram_addr[*]}]

	set_output_delay -clock $sc -max [expr { $din_su + $wire}] -add_delay [get_ports {sram_idata[*]}]
	set_output_delay -clock $sc -min [expr {-$din_hd + $wire}] -add_delay [get_ports {sram_idata[*]}]

	set_output_delay -clock $sc -max [expr { $wen_su + $wire}] -add_delay [get_ports {sram_write}]
	set_output_delay -clock $sc -min [expr {-$wen_hd + $wire}] -add_delay [get_ports {sram_write}]

	set_output_delay -clock $sc -max [expr { $ren_su + $wire}] -add_delay [get_ports {sram_read}]
	set_output_delay -clock $sc -min [expr {-$ren_hd + $wire}] -add_delay [get_ports {sram_read}]

	# Read data returns $dout after the SRAM clock edge;  against a 15 ns
	# period that leaves ample time for the return route and capture.
	set_input_delay  -clock $sc -max [expr { $dout   + $wire}] -add_delay [get_ports {sram_odata[*]}]
	set_input_delay  -clock $sc -min 0.500                     -add_delay [get_ports {sram_odata[*]}]
    }
}

# Declares the SRAM interface unchecked, for corners with no SRAM model.
proc sram_not_timed {} {
    set_false_path -to   [get_ports {sram_addr[*] sram_idata[*] sram_read sram_write}]
    set_false_path -from [get_ports {sram_odata[*]}]
}
