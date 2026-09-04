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
# proj_ibias_ena[1:0]	(output)	top 
# proj_vbias_ena	(output)	top 
# analog_bus_ena[3:0]	(output)	top 
# idac1_value[4:0]	(output)	top 
# idac2_value[4:0]	(output)	top 
# voltgen_ena[2:0]	(output)	top
# voltgen_high		(output)	top
# voltgen_value[2:0]	(output)	top
# bandgap_ena		(output)	top
# bandgap_trim[15:0]	(output)	top
# biasgen_ena		(output)	top
# biasgen_coarse	(output)	top
# biasgen_fine		(output)	top
# biasgen_ref_vbg	(output)	top
# bandgap_sink1[2:0]	(output)	top
# bandgap_sink2[1:0]	(output)	top
# voltgen_sink1[2:0]	(output)	top
# voltgen_sink2[2:0]	(output)	top
# voltgen_source[4:0]	(output)	top
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
#
# (Updated version: Shaving 20 micons off of the height)

set die_llx 640
set die_lly 300
set die_urx 1895
set die_ury 430

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
# Moved down because height was reduced.  Was: 423, 426, 434, 438, 445
# New ymax is 430
label_left_signal sram_idata\[5\]     418	output
label_left_signal sram_odata\[6\]     420	input
label_left_signal sram_idata\[6\]     422	output
label_left_signal sram_odata\[7\]     424	input
label_left_signal sram_idata\[7\]     426	output

label_top_signal reset		  1125	output

label_top_signal dbus_out\[0\]    1135	output
label_top_signal dbus_out\[1\]    1137	output
label_top_signal dbus_out\[2\]    1139	output
label_top_signal dbus_out\[3\]    1141	output
label_top_signal dbus_out\[4\]    1143	output
label_top_signal dbus_out\[5\]    1145	output
label_top_signal dbus_out\[6\]    1147	output
label_top_signal dbus_out\[7\]    1149	output
label_top_signal dbus_out\[8\]    1151	output
label_top_signal dbus_out\[9\]    1153	output
label_top_signal dbus_out\[10\]   1155	output
label_top_signal dbus_out\[11\]   1157	output
label_top_signal dbus_out\[12\]   1159	output
label_top_signal dbus_out\[13\]   1161	output
label_top_signal dbus_out\[14\]   1163	output
label_top_signal dbus_out\[15\]   1165	output
label_top_signal dbus_out\[16\]   1167	output
label_top_signal dbus_out\[17\]   1169	output
label_top_signal dbus_out\[18\]   1171	output
label_top_signal dbus_out\[19\]   1173	output
label_top_signal dbus_out\[20\]   1175	output
label_top_signal dbus_out\[21\]   1177	output
label_top_signal dbus_out\[22\]   1179	output
label_top_signal dbus_out\[23\]   1181	output

label_top_signal dbus_in\[0\]    1184	input
label_top_signal dbus_in\[1\]    1186	input
label_top_signal dbus_in\[2\]    1188	input
label_top_signal dbus_in\[3\]    1190	input
label_top_signal dbus_in\[4\]    1192	input
label_top_signal dbus_in\[5\]    1194	input
label_top_signal dbus_in\[6\]    1196	input
label_top_signal dbus_in\[7\]    1198	input
label_top_signal dbus_in\[8\]    1200	input
label_top_signal dbus_in\[9\]    1202	input
label_top_signal dbus_in\[10\]   1204	input
label_top_signal dbus_in\[11\]   1206	input

label_top_signal proj_sel\[0\]   1210	output
label_top_signal proj_sel\[1\]   1212	output
label_top_signal proj_sel\[2\]   1214	output
label_top_signal proj_sel\[3\]   1216	output
label_top_signal proj_sel\[4\]   1218	output

label_top_signal proj_ena        1220	output
label_top_signal proj_dig_ena    1222	output
label_top_signal proj_3v3_ena    1224	output
label_top_signal proj_1v2_ena    1226	output
label_top_signal proj_ibias_ena\[0\]    1228	output
label_top_signal proj_ibias_ena\[1\]    1230	output
label_top_signal proj_vbias_ena  1232	output

label_top_signal analog_bus_ena\[0\]   1234	output
label_top_signal analog_bus_ena\[1\]   1236	output
label_top_signal analog_bus_ena\[2\]   1238	output
label_top_signal analog_bus_ena\[3\]   1240	output
label_top_signal idac1_value\[0\]      1242	output
label_top_signal idac1_value\[1\]      1244	output
label_top_signal idac1_value\[2\]      1246	output
label_top_signal idac1_value\[3\]      1248	output
label_top_signal idac1_value\[4\]      1250	output
label_top_signal idac2_value\[0\]      1252	output
label_top_signal idac2_value\[1\]      1254	output
label_top_signal idac2_value\[2\]      1256	output
label_top_signal idac2_value\[3\]      1258	output
label_top_signal idac2_value\[4\]      1260	output
label_top_signal voltgen_ena\[0\]      1262	output
label_top_signal voltgen_ena\[1\]      1264	output
label_top_signal voltgen_ena\[2\]      1266	output
label_top_signal voltgen_high	       1268	output
label_top_signal voltgen_value\[0\]    1270	output
label_top_signal voltgen_value\[1\]    1272	output
label_top_signal voltgen_value\[2\]    1274	output
label_top_signal bandgap_ena	       1276	output
label_top_signal bandgap_trim\[0\]     1278	output
label_top_signal bandgap_trim\[1\]     1280	output
label_top_signal bandgap_trim\[2\]     1282	output
label_top_signal bandgap_trim\[3\]     1284	output
label_top_signal bandgap_trim\[4\]     1286	output
label_top_signal bandgap_trim\[5\]     1288	output
label_top_signal bandgap_trim\[6\]     1290	output
label_top_signal bandgap_trim\[7\]     1292	output
label_top_signal bandgap_trim\[8\]     1294	output
label_top_signal bandgap_trim\[9\]     1296	output
label_top_signal bandgap_trim\[10\]    1298	output
label_top_signal bandgap_trim\[11\]    1300	output
label_top_signal bandgap_trim\[12\]    1302	output
label_top_signal bandgap_trim\[13\]    1304	output
label_top_signal bandgap_trim\[14\]    1306	output
label_top_signal bandgap_trim\[15\]    1308	output
label_top_signal biasgen_ena	       1310	output
label_top_signal biasgen_coarse	       1312	output
label_top_signal biasgen_fine	       1314	output
label_top_signal biasgen_ref_vbg       1316	output
label_top_signal bandgap_sink1\[0\]    1318	output
label_top_signal bandgap_sink1\[1\]    1320	output
label_top_signal bandgap_sink1\[2\]    1322	output
label_top_signal bandgap_sink2\[0\]    1324	output
label_top_signal bandgap_sink2\[1\]    1326	output
label_top_signal voltgen_sink1\[0\]    1328	output
label_top_signal voltgen_sink1\[1\]    1330	output
label_top_signal voltgen_sink1\[2\]    1332	output
label_top_signal voltgen_sink2\[0\]    1334	output
label_top_signal voltgen_sink2\[1\]    1336	output
label_top_signal voltgen_sink2\[2\]    1338	output
label_top_signal voltgen_source\[0\]   1340	output
label_top_signal voltgen_source\[1\]   1342	output
label_top_signal voltgen_source\[2\]   1344	output
label_top_signal voltgen_source\[3\]   1346	output
label_top_signal voltgen_source\[4\]   1348	output

# The I/O ports at the top have to be threaded through the center
label_top_signal io_out\[8\]	      1352	output
label_top_signal io_oe\[8\]	      1355	output
label_top_signal io_in\[8\]	      1358	output
label_top_signal io_out\[9\]	      1361	output
label_top_signal io_oe\[9\]	      1364	output
label_top_signal io_in\[9\]	      1367	output
label_top_signal io_out\[10\]	      1380	output
label_top_signal io_oe\[10\]	      1383	output
label_top_signal io_in\[10\]	      1386	output
label_top_signal io_out\[11\]	      1389	output
label_top_signal io_oe\[11\]	      1392	output
label_top_signal io_in\[11\]	      1395	output

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
