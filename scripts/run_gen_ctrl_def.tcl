#--------------------------------------------------------------
# run_gen_ctrl_def.tcl
#
# Tcl script to automate the process of generating pins at the
# best positions for the user project controller.  This block
# is a macro that sits between the digital lines coming from
# housekeeping and the corresponding lines controlling each
# user project.
#--------------------------------------------------------------
#
# VPWR and VGND will be taken care of by the synthesis tool's
# PDN generator.
#
# Signal pins:
#
# dig_out[11:0]		(output)	right
#
# proj_sel[4:0]		(input)		bottom
# clk			(input)		bottom
# dig_ena		(input)		bottom
# enable		(input)		bottom
# reset			(input)		bottom
# analog_ena[3:0]	(input)		bottom
# ibias_ena[1:0]	(input)		bottom
# vbias_ena		(input)		bottom
# power_3v3_ena		(input)		bottom
# power_1v2_ena		(input)		bottom
# dig_in[23:0]		(input)		bottom
# proj_addr[4:0]	(input)		bottom
#
# proj_clk		(output)	top
# proj_ena		(output)	top
# proj_reset		(output)	top
# proj_3v3_ena		(output)	top
# proj_1v2_ena		(output)	top
# proj_analog_ena[3:0]	(output)	top
# proj_ibias_ena[1:0]	(output)	top
# proj_vbias_ena	(output)	top
# proj_dig_in[23:0]	(output)	top
# proj_dig_out[11:0]	(input)		top
#
# dig_out_relay[11:0]	(input)		left
#
#--------------------------------------------------------------
# Prep:  Make sure that the layout file does not exist.  If so,
# exit.  The user must knowingly delete the original file.
#--------------------------------------------------------------

if {[file exists user_project_control_def.mag]} {
    puts stderr "Layout for user_project_control DEF exists!"
    puts stderr "(File is magic/user_project_control_def.mag)"
    puts stderr "Back up and delete before regenerating!"
    quit -noprompt
}

#--------------------------------------------------------------
# Setup
#--------------------------------------------------------------

namespace path {::tcl::mathop ::tcl::mathfunc}

units microns
load user_project_control_def -silent

# Make sure these numbers match the die and core areas in the
# LibreLane config.yaml file.

set die_llx 0
set die_lly 0
set die_urx 105
set die_ury 60

box values 0 0 0 0

#--------------------------------------------------------------
# Defined procedures
#--------------------------------------------------------------

# Label on the bottom
proc label_bottom_signal {pin_text x dir} {
    global die_lly
    box size 0 0
    box position $x $die_lly
    box grow e 0.15
    box grow w 0.15
    box grow n 2
    paint m2
    label $pin_text FreeSans 0.3 90 0 0 c m2
    port make
    port class $dir
    port use signal
}

# Label on the right
proc label_right_signal {pin_text y dir} {
    global die_urx
    box size 0 0
    box position $die_urx $y
    box grow n 0.15
    box grow s 0.15
    box grow w 2
    paint m3
    label $pin_text FreeSans 0.3 0 0 0 c m3
    port make
    port class $dir
    port use signal
}

# Label on the top
proc label_top_signal {pin_text x dir} {
    global die_ury
    box size 0 0
    box position $x $die_ury
    box grow e 0.15
    box grow w 0.15
    box grow s 2
    paint m2
    label $pin_text FreeSans 0.3 90 0 0 c m2
    port make
    port class $dir
    port use signal
}

# Label on the left
proc label_left_signal {pin_text y dir} {
    global die_llx
    box size 0 0
    box position $die_llx $y
    box grow n 0.15
    box grow s 0.15
    box grow e 2
    paint m3
    label $pin_text FreeSans 0.3 0 0 0 c m3
    port make
    port class $dir
    port use signal
}

#--------------------------------------------------------------
# Establish die size
#--------------------------------------------------------------

property FIXED_BBOX $die_llx $die_lly $die_urx $die_ury

#--------------------------------------------------------------
# Create the pins
#--------------------------------------------------------------

# All of these signals are under the SRAM, so put them far to
# the left.

label_bottom_signal clk		  3	input
label_bottom_signal proj_sel\[4\] 5	input
label_bottom_signal proj_sel\[3\] 7	input
label_bottom_signal proj_sel\[2\] 9	input
label_bottom_signal proj_sel\[1\] 11	input
label_bottom_signal proj_sel\[0\] 13	input
label_bottom_signal dig_ena 	  15	input
label_bottom_signal enable 	  17	input
label_bottom_signal reset 	  19	input
label_bottom_signal analog_ena\[3\] 21	input
label_bottom_signal analog_ena\[2\] 23	input
label_bottom_signal analog_ena\[1\] 25	input
label_bottom_signal analog_ena\[0\] 27 	input
label_bottom_signal ibias_ena\[1\] 29 	input
label_bottom_signal ibias_ena\[0\] 31 	input
label_bottom_signal vbias_ena	  33 	input
label_bottom_signal power_3v3_ena 35 	input
label_bottom_signal power_1v2_ena 37 	input
label_bottom_signal dig_in\[23\]  39 	input
label_bottom_signal dig_in\[22\]  41 	input
label_bottom_signal dig_in\[21\]  43 	input
label_bottom_signal dig_in\[20\]  45 	input
label_bottom_signal dig_in\[19\]  47 	input
label_bottom_signal dig_in\[18\]  49 	input
label_bottom_signal dig_in\[17\]  51 	input
label_bottom_signal dig_in\[16\]  53 	input
label_bottom_signal dig_in\[15\]  55 	input
label_bottom_signal dig_in\[14\]  57 	input
label_bottom_signal dig_in\[13\]  59 	input
label_bottom_signal dig_in\[12\]  61 	input
label_bottom_signal dig_in\[11\]  63 	input
label_bottom_signal dig_in\[10\]  65 	input
label_bottom_signal dig_in\[9\]   67 	input
label_bottom_signal dig_in\[8\]   69 	input
label_bottom_signal dig_in\[7\]   71 	input
label_bottom_signal dig_in\[6\]   73 	input
label_bottom_signal dig_in\[5\]   75 	input
label_bottom_signal dig_in\[4\]   77 	input
label_bottom_signal dig_in\[3\]   79 	input
label_bottom_signal dig_in\[2\]   81 	input
label_bottom_signal dig_in\[1\]   83 	input
label_bottom_signal dig_in\[0\]   85 	input

label_bottom_signal proj_addr\[4\] 87	input
label_bottom_signal proj_addr\[3\] 89	input
label_bottom_signal proj_addr\[2\] 91	input
label_bottom_signal proj_addr\[1\] 93	input
label_bottom_signal proj_addr\[0\] 95	input

label_top_signal proj_clk	 	3	output
label_top_signal proj_ena	 	5  	output
label_top_signal proj_reset	 	7  	output
label_top_signal proj_3v3_ena		9  	output
label_top_signal proj_1v2_ena	 	11  	output
label_top_signal proj_analog_ena\[3\]   13 	output
label_top_signal proj_analog_ena\[2\]   15 	output
label_top_signal proj_analog_ena\[1\]   17 	output
label_top_signal proj_analog_ena\[0\]   19 	output
label_top_signal proj_ibias_ena\[1\]    21 	output
label_top_signal proj_ibias_ena\[0\]    23 	output
label_top_signal proj_vbias_ena	        25 	output
label_top_signal proj_dig_in\[23\]      27 	output
label_top_signal proj_dig_in\[22\]      29 	output
label_top_signal proj_dig_in\[21\]      31 	output
label_top_signal proj_dig_in\[20\]      33 	output
label_top_signal proj_dig_in\[19\]      35 	output
label_top_signal proj_dig_in\[18\]      37 	output
label_top_signal proj_dig_in\[17\]      39 	output
label_top_signal proj_dig_in\[16\]      41 	output
label_top_signal proj_dig_in\[15\]      43 	output
label_top_signal proj_dig_in\[14\]      45 	output
label_top_signal proj_dig_in\[13\]      47 	output
label_top_signal proj_dig_in\[12\]      49 	output
label_top_signal proj_dig_in\[11\]      51 	output
label_top_signal proj_dig_in\[10\]      53 	output
label_top_signal proj_dig_in\[9\]       55 	output
label_top_signal proj_dig_in\[8\]       57 	output
label_top_signal proj_dig_in\[7\]       59 	output
label_top_signal proj_dig_in\[6\]       61 	output
label_top_signal proj_dig_in\[5\]       63 	output
label_top_signal proj_dig_in\[4\]       65 	output
label_top_signal proj_dig_in\[3\]       67 	output
label_top_signal proj_dig_in\[2\]       69 	output
label_top_signal proj_dig_in\[1\]       71 	output
label_top_signal proj_dig_in\[0\]       73 	output
label_top_signal proj_dig_out\[11\]     75 	input
label_top_signal proj_dig_out\[10\]     77 	input
label_top_signal proj_dig_out\[9\]      79 	input
label_top_signal proj_dig_out\[8\]      81 	input
label_top_signal proj_dig_out\[7\]      83 	input
label_top_signal proj_dig_out\[6\]      85 	input
label_top_signal proj_dig_out\[5\]      87 	input
label_top_signal proj_dig_out\[4\]      89 	input
label_top_signal proj_dig_out\[3\]      91 	input
label_top_signal proj_dig_out\[2\]      93 	input
label_top_signal proj_dig_out\[1\]      95 	input
label_top_signal proj_dig_out\[0\]      97 	input

# The daisy-chained return bus.  dig_out (right edge) and
# dig_out_relay (left edge) must stay at matching y positions and in
# matching bit order:  slot N's dig_out faces slot N+1's dig_out_relay,
# so identical positions give a straight-across connection with no jogs
# at the top level.
#
# Spread on a 4 um pitch over y = 8 .. 52, centred in the 60 um die,
# rather than bunched into y = 5 .. 27 as they were when the die was
# only 35 um tall.  Spreading them lets the placer distribute the 12
# output buffers and 12 relay muxes vertically instead of forcing all
# 24 nets through one horizontal channel --- which matters here because
# the Metal4 power corridors leave this block routing almost entirely
# on Metal2 (vertical) and Metal3 (horizontal).

label_right_signal dig_out\[11\]      8	output
label_right_signal dig_out\[10\]      12	output
label_right_signal dig_out\[9\]       16	output
label_right_signal dig_out\[8\]       20	output
label_right_signal dig_out\[7\]       24	output
label_right_signal dig_out\[6\]       28	output
label_right_signal dig_out\[5\]       32	output
label_right_signal dig_out\[4\]       36	output
label_right_signal dig_out\[3\]       40	output
label_right_signal dig_out\[2\]       44	output
label_right_signal dig_out\[1\]       48	output
label_right_signal dig_out\[0\]       52	output

label_left_signal dig_out_relay\[11\] 8	input
label_left_signal dig_out_relay\[10\] 12	input
label_left_signal dig_out_relay\[9\]  16	input
label_left_signal dig_out_relay\[8\]  20	input
label_left_signal dig_out_relay\[7\]  24	input
label_left_signal dig_out_relay\[6\]  28	input
label_left_signal dig_out_relay\[5\]  32	input
label_left_signal dig_out_relay\[4\]  36	input
label_left_signal dig_out_relay\[3\]  40	input
label_left_signal dig_out_relay\[2\]  44	input
label_left_signal dig_out_relay\[1\]  48	input
label_left_signal dig_out_relay\[0\]  52	input

# Add route obstructions around the edges over and under the pins
tech unlock *
box values $die_llx $die_lly $die_urx [+ $die_lly 1]
paint obsm2
paint obsm4
box values $die_llx $die_lly [+ $die_llx 1] $die_ury
paint obsm1
paint obsm3
box values [- $die_urx 1] $die_lly $die_urx $die_ury
paint obsm2
paint obsm4
box values $die_llx [- $die_ury 1] $die_urx $die_ury
paint obsm1
paint obsm3

# Prevent metal4 from being routed in these areas which are power buses
# running over the top of the cell
box values $die_llx $die_lly [+ $die_llx 4.3] $die_ury
paint obsm4
box values [+ $die_llx 31.8] $die_lly [+ $die_llx 61.7] $die_ury
paint obsm4
box values [- $die_urx 30] $die_lly $die_urx $die_ury
paint obsm4

writeall force user_project_control_def

# Generate the DEF for this using "def write".  Change the cellname
# to get the right name for the DEF file, and write to the def/
# subdirectory.

cellname rename user_project_control_def user_project_control
def write ../def/user_project_control

quit -noprompt
