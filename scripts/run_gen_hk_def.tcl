#--------------------------------------------------------------
# run_gen_hk_def.tcl
#
# Tcl script to automate the process of generating pins at the
# best positions for the housekeeping controller.  Normally,
# a user project will take up the entire area of openframe.
# However, this project is a sub-harness for analog designs,
# and the digital controller needs to be restricted to the
# bottom side, with I/O pins for analog control and feedback
# along the top, and other I/O near the GPIO pins they are
# associated with.
#--------------------------------------------------------------
#
# VPWR and VGND will be taken care of by the synthesis tool's
# PDN generator.
#
# Signal pins:
#
# SDO			(output)	bottom, above pad
# sdo_ena		(output)	bottom, above pad
# SDI			(input)		bottom, above pad
# CSB			(input)		bottom, above pad
# SCK			(input)		bottom, above pad
# clk			(input)		bottom, above pad
# porb			(input)
# reset			(output)	top center
# mask_rev_in[31:0]	(input)		bottom right corner
# sram_clk		(output)	left
# sram_addr[9:0]	(output)	left
# sram_idata[7:0]	(output)	left
# sram_odata[7:0]	(input)		left
# sram_read		(output)	left
# sram_write		(output)	left
# io_in[11:0]		(input)		0-7 on bottom, 8-11 top
# io_out[11:0]		(output)	0-7 on bottom, 8-11 top
# io_oe[11:0]		(output)	0-7 on bottom, 8-11 top
# dbus_out[21:0]	(output)	top 
# dbus_in[11:0]		(input)		top 
# proj_sel[4:0]		(output)	top 
# proj_ena		(output)	top 
# proj_dig_ena		(output)	top 
# proj_3v3_ena		(output)	top 
# proj_1v2_ena		(output)	top 
# analog_bus_ena[3:0]	(output)	top 
# idac1_value[4:0]	(output)	top 
# idac1_control[5:0]	(output)	top 
# idac2_value[4:0]	(output)	top 
# idac2_control[5:0]	(output)	top 
# vbias_control[5:0]	(output)	top 
# bandgap_control[6:0]	(output)	top 
#
# The top signals are clustered at the center where they can
# access the infrastructure running up between the two columns
# of user projects on each side.
#
#--------------------------------------------------------------
# Prep:  Make sure that the layout file does not exist.  If so,
# exit.  The user must knowingly delete the original file.
#--------------------------------------------------------------

if {[file exists housekeeping_top_def.mag]} {
    puts stderr "Layout for housekeeping_top DEF exists!"
    puts stderr "(File is magic/housekeeping_top_def.mag)"
    puts stderr "Back up and delete before regenerating!"
    quit -noprompt
}

#--------------------------------------------------------------
# Setup
#--------------------------------------------------------------

namespace path {::tcl::mathop ::tcl::mathfunc}

units microns
load housekeeping_top_def -silent

# Die dimensions leave room for the IHP 1024x8 SRAM on the left.
# Make sure these numbers match the die and core areas in the
# LibreLane config.yaml file.

set die_llx 640
set die_lly 300
set die_urx 1895
set die_ury 453

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

label_bottom_signal SDO		650	output
label_bottom_signal sdo_ena	653	output
label_bottom_signal SDI		656	input
label_bottom_signal CSB		659	input
label_bottom_signal SCK		662	input

# From "clk", 

label_bottom_signal clk		760	input
label_bottom_signal porb	800	input

label_bottom_signal mask_rev_in\[31\] 1860	input
label_bottom_signal mask_rev_in\[30\] 1861	input
label_bottom_signal mask_rev_in\[29\] 1862	input
label_bottom_signal mask_rev_in\[28\] 1863	input
label_bottom_signal mask_rev_in\[27\] 1864	input
label_bottom_signal mask_rev_in\[26\] 1865	input
label_bottom_signal mask_rev_in\[25\] 1866	input
label_bottom_signal mask_rev_in\[24\] 1867	input
label_bottom_signal mask_rev_in\[23\] 1868	input
label_bottom_signal mask_rev_in\[22\] 1869	input
label_bottom_signal mask_rev_in\[21\] 1870	input
label_bottom_signal mask_rev_in\[20\] 1871	input
label_bottom_signal mask_rev_in\[19\] 1872	input
label_bottom_signal mask_rev_in\[18\] 1873	input
label_bottom_signal mask_rev_in\[17\] 1874	input
label_bottom_signal mask_rev_in\[16\] 1875	input
label_bottom_signal mask_rev_in\[15\] 1876	input
label_bottom_signal mask_rev_in\[14\] 1877	input
label_bottom_signal mask_rev_in\[13\] 1878	input
label_bottom_signal mask_rev_in\[12\] 1881	input
label_bottom_signal mask_rev_in\[11\] 1882	input
label_bottom_signal mask_rev_in\[10\] 1883	input
label_bottom_signal mask_rev_in\[9\]  1884	input
label_bottom_signal mask_rev_in\[8\]  1885	input
label_bottom_signal mask_rev_in\[7\]  1886	input
label_bottom_signal mask_rev_in\[6\]  1887	input
label_bottom_signal mask_rev_in\[5\]  1888	input
label_bottom_signal mask_rev_in\[4\]  1889	input
label_bottom_signal mask_rev_in\[3\]  1890	input
label_bottom_signal mask_rev_in\[2\]  1891	input
label_bottom_signal mask_rev_in\[1\]  1892	input
label_bottom_signal mask_rev_in\[0\]  1893	input

label_bottom_signal io_out\[0\]	      1068	output
label_bottom_signal io_oe\[0\]	      1071	output
label_bottom_signal io_in\[0\]	      1110	output
label_bottom_signal io_out\[1\]	      1178	output
label_bottom_signal io_oe\[1\]	      1181	output
label_bottom_signal io_in\[1\]	      1220	output
label_bottom_signal io_out\[2\]	      1288	output
label_bottom_signal io_oe\[2\]	      1291	output
label_bottom_signal io_in\[2\]	      1330	output
label_bottom_signal io_out\[3\]	      1398	output
label_bottom_signal io_oe\[3\]	      1401	output
label_bottom_signal io_in\[3\]	      1440	output
label_bottom_signal io_out\[4\]	      1508	output
label_bottom_signal io_oe\[4\]	      1511	output
label_bottom_signal io_in\[4\]	      1550	output
label_bottom_signal io_out\[5\]	      1618	output
label_bottom_signal io_oe\[5\]	      1621	output
label_bottom_signal io_in\[5\]	      1660	output
label_bottom_signal io_out\[6\]	      1728	output
label_bottom_signal io_oe\[6\]	      1731	output
label_bottom_signal io_in\[6\]	      1770	output
label_bottom_signal io_out\[7\]	      1838	output
label_bottom_signal io_oe\[7\]	      1841	output
label_bottom_signal io_in\[7\]	      1880	output

label_left_signal sram_idata\[0\]     305	output
label_left_signal sram_odata\[0\]     312	input
label_left_signal sram_idata\[1\]     316	output
label_left_signal sram_odata\[1\]     323	input
label_left_signal sram_idata\[2\]     327	output
label_left_signal sram_odata\[2\]     335	input
label_left_signal sram_idata\[3\]     338	output
label_left_signal sram_odata\[3\]     346	input
label_left_signal sram_addr\[6\]      359	output
label_left_signal sram_addr\[7\]      360	output
label_left_signal sram_clk	      369	output
label_left_signal sram_addr\[1\]      370	output
label_left_signal sram_addr\[0\]      371	output
label_left_signal sram_write          372	output
label_left_signal sram_read           373	output
label_left_signal sram_addr\[3\]      378	output
label_left_signal sram_addr\[2\]      379	output
label_left_signal sram_addr\[5\]      380	output
label_left_signal sram_addr\[4\]      382	output
label_left_signal sram_addr\[9\]      384	output
label_left_signal sram_addr\[8\]      389	output
label_left_signal sram_odata\[4\]     404	input
label_left_signal sram_idata\[4\]     411	output
label_left_signal sram_odata\[5\]     415	input
label_left_signal sram_idata\[5\]     423	output
label_left_signal sram_odata\[6\]     426	input
label_left_signal sram_idata\[6\]     434	output
label_left_signal sram_odata\[7\]     438	input
label_left_signal sram_idata\[7\]     445	output

label_top_signal reset		  990	output

label_top_signal dbus_out\[0\]    1000	output
label_top_signal dbus_out\[1\]    1002	output
label_top_signal dbus_out\[2\]    1004	output
label_top_signal dbus_out\[3\]    1006	output
label_top_signal dbus_out\[4\]    1008	output
label_top_signal dbus_out\[5\]    1010	output
label_top_signal dbus_out\[6\]    1012	output
label_top_signal dbus_out\[7\]    1014	output
label_top_signal dbus_out\[8\]    1018	output
label_top_signal dbus_out\[9\]    1020	output
label_top_signal dbus_out\[10\]   1022	output
label_top_signal dbus_out\[11\]   1024	output
label_top_signal dbus_out\[12\]   1026	output
label_top_signal dbus_out\[13\]   1028	output
label_top_signal dbus_out\[14\]   1030	output
label_top_signal dbus_out\[15\]   1032	output
label_top_signal dbus_out\[16\]   1036	output
label_top_signal dbus_out\[17\]   1038	output
label_top_signal dbus_out\[18\]   1040	output
label_top_signal dbus_out\[19\]   1042	output
label_top_signal dbus_out\[20\]   1044	output
label_top_signal dbus_out\[21\]   1046	output
label_top_signal dbus_out\[22\]   1048	output
label_top_signal dbus_out\[23\]   1050	output

label_top_signal dbus_in\[0\]    1053	input
label_top_signal dbus_in\[1\]    1055	input
label_top_signal dbus_in\[2\]    1058	input
label_top_signal dbus_in\[3\]    1060	input
label_top_signal dbus_in\[4\]    1062	input
label_top_signal dbus_in\[5\]    1064	input
label_top_signal dbus_in\[6\]    1066	input
label_top_signal dbus_in\[7\]    1068	input
label_top_signal dbus_in\[8\]    1070	input
label_top_signal dbus_in\[9\]    1072	input
label_top_signal dbus_in\[10\]   1074	input
label_top_signal dbus_in\[11\]   1076	input

label_top_signal proj_sel\[0\]   1080	output
label_top_signal proj_sel\[1\]   1082	output
label_top_signal proj_sel\[2\]   1084	output
label_top_signal proj_sel\[3\]   1086	output
label_top_signal proj_sel\[4\]   1088	output

label_top_signal proj_ena        1090	output
label_top_signal proj_dig_ena    1092	output
label_top_signal proj_3v3_ena    1094	output
label_top_signal proj_1v2_ena    1096	output

label_top_signal analog_bus_ena\[0\]   1100	output
label_top_signal analog_bus_ena\[1\]   1102	output
label_top_signal analog_bus_ena\[2\]   1104	output
label_top_signal analog_bus_ena\[3\]   1106	output
label_top_signal idac1_value\[0\]      1108	output
label_top_signal idac1_value\[1\]      1110	output
label_top_signal idac1_value\[2\]      1112	output
label_top_signal idac1_value\[3\]      1114	output
label_top_signal idac1_value\[4\]      1116	output
label_top_signal idac1_control\[0\]    1118	output
label_top_signal idac1_control\[1\]    1120	output
label_top_signal idac1_control\[2\]    1122	output
label_top_signal idac1_control\[3\]    1124	output
label_top_signal idac1_control\[4\]    1126	output
label_top_signal idac1_control\[5\]    1128	output
label_top_signal idac2_value\[0\]      1132	output
label_top_signal idac2_value\[1\]      1134	output
label_top_signal idac2_value\[2\]      1136	output
label_top_signal idac2_value\[3\]      1138	output
label_top_signal idac2_value\[4\]      1140	output
label_top_signal idac2_control\[0\]    1142	output
label_top_signal idac2_control\[1\]    1144	output
label_top_signal idac2_control\[2\]    1146	output
label_top_signal idac2_control\[3\]    1148	output
label_top_signal idac2_control\[4\]    1150	output
label_top_signal idac2_control\[5\]    1152	output
label_top_signal vbias_control\[0\]    1156	output
label_top_signal vbias_control\[1\]    1158	output
label_top_signal vbias_control\[2\]    1160	output
label_top_signal vbias_control\[3\]    1162	output
label_top_signal vbias_control\[4\]    1164	output
label_top_signal vbias_control\[5\]    1166	output
label_top_signal bandgap_control\[0\]  1170	output
label_top_signal bandgap_control\[1\]  1172	output
label_top_signal bandgap_control\[2\]  1174	output
label_top_signal bandgap_control\[3\]  1176	output
label_top_signal bandgap_control\[4\]  1178	output
label_top_signal bandgap_control\[5\]  1180	output
label_top_signal bandgap_control\[6\]  1182	output

# The I/O ports at the top have to be threaded through the center
label_top_signal io_out\[8\]	      1186	output
label_top_signal io_oe\[8\]	      1189	output
label_top_signal io_in\[8\]	      1192	output
label_top_signal io_out\[9\]	      1195	output
label_top_signal io_oe\[9\]	      1198	output
label_top_signal io_in\[9\]	      1201	output
label_top_signal io_out\[10\]	      1204	output
label_top_signal io_oe\[10\]	      1207	output
label_top_signal io_in\[10\]	      1210	output
label_top_signal io_out\[11\]	      1213	output
label_top_signal io_oe\[11\]	      1216	output
label_top_signal io_in\[11\]	      1219	output

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

writeall force housekeeping_top_def

# Generate the DEF for this using "def write".  Change the cellname
# to get the right name for the DEF file, and write to the def/
# subdirectory.

cellname rename housekeeping_top_def housekeeping_top
def write ../def/housekeeping_top

quit -noprompt
