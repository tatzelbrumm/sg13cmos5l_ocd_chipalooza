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
# proj_addr[4:0]	(input)		right side
#
# proj_sel[4:0]		(input)		bottom
# clk			(input)		bottom
# dig_ena		(input)		bottom
# enable		(input)		bottom
# analog_ena[3:0]	(input)		bottom
# ibias_ena[1:0]	(input)		bottom
# vbias_ena		(input)		bottom
# power_3v3_ena		(input)		bottom
# power_1v2_ena		(input)		bottom
# dig_in[23:0]		(input)		bottom
# proj_dig_out[11:0]	(input)		bottom
#
# proj_clk		(output)	top
# proj_ena		(output)	top
# proj_3v3_ena		(output)	top
# proj_1v2_ena		(output)	top
# proj_analog_ena[3:0]	(output)	top
# proj_ibias_ena[1:0]	(output)	top
# proj_vbias_ena	(output)	top
# proj_dig_in[23:0]	(output)	top
# dig_out[11:0]		(output)	top
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
set die_urx 110
set die_ury 35

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

label_bottom_signal clk		  2	input
label_bottom_signal proj_sel\[4\] 4	input
label_bottom_signal proj_sel\[3\] 6	input
label_bottom_signal proj_sel\[2\] 8	input
label_bottom_signal proj_sel\[1\] 10	input
label_bottom_signal proj_sel\[0\] 12	input
label_bottom_signal dig_ena 	  14	input
label_bottom_signal enable 	  16	input
label_bottom_signal analog_ena\[3\] 18	input
label_bottom_signal analog_ena\[2\] 20	input
label_bottom_signal analog_ena\[1\] 22	input
label_bottom_signal analog_ena\[0\] 24 	input
label_bottom_signal ibias_ena\[1\] 26 	input
label_bottom_signal ibias_ena\[0\] 28 	input
label_bottom_signal vbias_ena	  30 	input
label_bottom_signal power_3v3_ena 32 	input
label_bottom_signal power_1v2_ena 34 	input
label_bottom_signal dig_in\[23\]  36 	input
label_bottom_signal dig_in\[22\]  38 	input
label_bottom_signal dig_in\[21\]  40 	input
label_bottom_signal dig_in\[20\]  42 	input
label_bottom_signal dig_in\[19\]  44 	input
label_bottom_signal dig_in\[18\]  46 	input
label_bottom_signal dig_in\[17\]  48 	input
label_bottom_signal dig_in\[16\]  50 	input
label_bottom_signal dig_in\[15\]  52 	input
label_bottom_signal dig_in\[14\]  54 	input
label_bottom_signal dig_in\[13\]  56 	input
label_bottom_signal dig_in\[12\]  58 	input
label_bottom_signal dig_in\[11\]  60 	input
label_bottom_signal dig_in\[10\]  62 	input
label_bottom_signal dig_in\[9\]   64 	input
label_bottom_signal dig_in\[8\]   66 	input
label_bottom_signal dig_in\[7\]   68 	input
label_bottom_signal dig_in\[6\]   70 	input
label_bottom_signal dig_in\[5\]   72 	input
label_bottom_signal dig_in\[4\]   74 	input
label_bottom_signal dig_in\[3\]   76 	input
label_bottom_signal dig_in\[2\]   78 	input
label_bottom_signal dig_in\[1\]   80 	input
label_bottom_signal dig_in\[0\]   82 	input
label_bottom_signal dig_out\[11\] 84 	output
label_bottom_signal dig_out\[10\] 86 	output
label_bottom_signal dig_out\[9\]  88 	output
label_bottom_signal dig_out\[8\]  90 	output
label_bottom_signal dig_out\[7\]  92 	output
label_bottom_signal dig_out\[6\]  94 	output
label_bottom_signal dig_out\[5\]  96 	output
label_bottom_signal dig_out\[4\]  98 	output
label_bottom_signal dig_out\[3\]  100	output
label_bottom_signal dig_out\[2\]  102	output
label_bottom_signal dig_out\[1\]  104	output
label_bottom_signal dig_out\[0\]  106	output

label_top_signal proj_clk	 	2	output
label_top_signal proj_ena	 	4  	output
label_top_signal proj_3v3_ena		6  	output
label_top_signal proj_1v2_ena	 	8  	output
label_top_signal proj_analog_ena\[3\]   10 	output
label_top_signal proj_analog_ena\[2\]   12 	output
label_top_signal proj_analog_ena\[1\]   14 	output
label_top_signal proj_analog_ena\[0\]   16 	output
label_top_signal proj_ibias_ena\[1\]    18 	output
label_top_signal proj_ibias_ena\[0\]    20 	output
label_top_signal proj_vbias_ena	        22 	output
label_top_signal proj_dig_in\[23\]      24 	output
label_top_signal proj_dig_in\[22\]      26 	output
label_top_signal proj_dig_in\[21\]      28 	output
label_top_signal proj_dig_in\[20\]      30 	output
label_top_signal proj_dig_in\[19\]      32 	output
label_top_signal proj_dig_in\[18\]      34 	output
label_top_signal proj_dig_in\[17\]      36 	output
label_top_signal proj_dig_in\[16\]      38 	output
label_top_signal proj_dig_in\[15\]      40 	output
label_top_signal proj_dig_in\[14\]      42 	output
label_top_signal proj_dig_in\[13\]      44 	output
label_top_signal proj_dig_in\[12\]      46 	output
label_top_signal proj_dig_in\[11\]      48 	output
label_top_signal proj_dig_in\[10\]      50 	output
label_top_signal proj_dig_in\[9\]       52 	output
label_top_signal proj_dig_in\[8\]       54 	output
label_top_signal proj_dig_in\[7\]       56 	output
label_top_signal proj_dig_in\[6\]       58 	output
label_top_signal proj_dig_in\[5\]       60 	output
label_top_signal proj_dig_in\[4\]       62 	output
label_top_signal proj_dig_in\[3\]       64 	output
label_top_signal proj_dig_in\[2\]       66 	output
label_top_signal proj_dig_in\[1\]       68 	output
label_top_signal proj_dig_in\[0\]       70 	output
label_top_signal proj_dig_out\[11\]     72 	input
label_top_signal proj_dig_out\[10\]     74 	input
label_top_signal proj_dig_out\[9\]      76 	input
label_top_signal proj_dig_out\[8\]      78 	input
label_top_signal proj_dig_out\[7\]      80 	input
label_top_signal proj_dig_out\[6\]      82 	input
label_top_signal proj_dig_out\[5\]      84 	input
label_top_signal proj_dig_out\[4\]      86 	input
label_top_signal proj_dig_out\[3\]      88 	input
label_top_signal proj_dig_out\[2\]      90 	input
label_top_signal proj_dig_out\[1\]      92 	input
label_top_signal proj_dig_out\[0\]      94 	input

label_right_signal proj_addr\[4\] 10	output
label_right_signal proj_addr\[3\] 12 	output
label_right_signal proj_addr\[2\] 14 	output
label_right_signal proj_addr\[1\] 16 	output
label_right_signal proj_addr\[0\] 18	output

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

writeall force user_project_control_def

# Generate the DEF for this using "def write".  Change the cellname
# to get the right name for the DEF file, and write to the def/
# subdirectory.

cellname rename user_project_control_def user_project_control
def write ../def/user_project_control

quit -noprompt
