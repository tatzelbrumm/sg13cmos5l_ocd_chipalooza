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
# RSTB			(input)		bottom, at resetb pad
# SCK			(input)		
# SDI			(input)
# CSB			(input)
# SDO			(output)
# sdo_ena		(output)
# reset			(output)	top center
# control[127:0]	(output)	across the top
# status[127:0]		(input)		across the top
# mask_rev_in[31:0]	(input)		bottom right corner
#
# control and status get divided into four parts of 32 bits each
# and are interleaved across the top, but the interleaving is mirrored
# around the center so that all power switch and bias current controls
# can be near the center:
#
#	status[127:96] control[127:96] status[95:64] control[95:64] ...
#	... control[63:32] status[63:32] control[31:0] status[31:0]
#
#--------------------------------------------------------------
# Setup
#--------------------------------------------------------------

namespace path {::tcl::mathop ::tcl::mathfunc}

units microns
load housekeeping_top_def -silent

set die_llx 360
set die_lly 300
set die_urx 1700
set die_ury 480

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

label_bottom_signal RSTB	580	input

label_right_signal SDO		350	output
label_right_signal sdo_ena	360	output
label_right_signal SDI		370	input
label_right_signal CSB		380	input
label_right_signal SCK		390	input

label_right_signal mask_rev_in\[31\] 311	input
label_right_signal mask_rev_in\[30\] 312	input
label_right_signal mask_rev_in\[29\] 313	input
label_right_signal mask_rev_in\[28\] 314	input
label_right_signal mask_rev_in\[27\] 315	input
label_right_signal mask_rev_in\[26\] 316	input
label_right_signal mask_rev_in\[25\] 317	input
label_right_signal mask_rev_in\[24\] 318	input
label_right_signal mask_rev_in\[23\] 319	input
label_right_signal mask_rev_in\[22\] 320	input
label_right_signal mask_rev_in\[21\] 321	input
label_right_signal mask_rev_in\[20\] 322	input
label_right_signal mask_rev_in\[19\] 323	input
label_right_signal mask_rev_in\[18\] 324	input
label_right_signal mask_rev_in\[17\] 325	input
label_right_signal mask_rev_in\[16\] 326	input
label_right_signal mask_rev_in\[15\] 327	input
label_right_signal mask_rev_in\[14\] 328	input
label_right_signal mask_rev_in\[13\] 329	input
label_right_signal mask_rev_in\[12\] 330	input
label_right_signal mask_rev_in\[11\] 331	input
label_right_signal mask_rev_in\[10\] 332	input
label_right_signal mask_rev_in\[9\]  333	input
label_right_signal mask_rev_in\[8\]  334	input
label_right_signal mask_rev_in\[7\]  335	input
label_right_signal mask_rev_in\[6\]  336	input
label_right_signal mask_rev_in\[5\]  337	input
label_right_signal mask_rev_in\[4\]  338	input
label_right_signal mask_rev_in\[3\]  339	input
label_right_signal mask_rev_in\[2\]  340	input
label_right_signal mask_rev_in\[1\]  341	input
label_right_signal mask_rev_in\[0\]  342	input

# Spread the controls evenly across the top, at 5um pitch.
# This leaves 85 on either side.

label_top_signal status\[127\]   370	input
label_top_signal status\[126\]   375	input
label_top_signal status\[125\]   380	input
label_top_signal status\[124\]   385	input
label_top_signal status\[123\]   390	input
label_top_signal status\[122\]   395	input
label_top_signal status\[121\]   400	input
label_top_signal status\[120\]   405	input
label_top_signal status\[119\]   410	input
label_top_signal status\[118\]   415	input
label_top_signal status\[117\]   420	input
label_top_signal status\[116\]   425	input
label_top_signal status\[115\]   430	input
label_top_signal status\[114\]   435	input
label_top_signal status\[113\]   440	input
label_top_signal status\[112\]   445	input
label_top_signal status\[111\]   450	input
label_top_signal status\[110\]   455	input
label_top_signal status\[109\]   460	input
label_top_signal status\[108\]   465	input
label_top_signal status\[107\]   470	input
label_top_signal status\[106\]   475	input
label_top_signal status\[105\]   480	input
label_top_signal status\[104\]   485	input
label_top_signal status\[103\]   490	input
label_top_signal status\[102\]   495	input
label_top_signal status\[101\]   500	input
label_top_signal status\[100\]   505	input
label_top_signal status\[99\]    510	input
label_top_signal status\[98\]    515	input
label_top_signal status\[97\]    520	input
label_top_signal status\[96\]    525	input

label_top_signal control\[127\]  530	output
label_top_signal control\[126\]  535	output
label_top_signal control\[125\]  540	output
label_top_signal control\[124\]  545	output
label_top_signal control\[123\]  550	output
label_top_signal control\[122\]  555	output
label_top_signal control\[121\]  560	output
label_top_signal control\[120\]  565	output
label_top_signal control\[119\]  570	output
label_top_signal control\[118\]  575	output
label_top_signal control\[117\]  580	output
label_top_signal control\[116\]  585	output
label_top_signal control\[115\]  590	output
label_top_signal control\[114\]  595	output
label_top_signal control\[113\]  600	output
label_top_signal control\[112\]  605	output
label_top_signal control\[111\]  610	output
label_top_signal control\[110\]  615	output
label_top_signal control\[109\]  620	output
label_top_signal control\[108\]  625	output
label_top_signal control\[107\]  630	output
label_top_signal control\[106\]  635	output
label_top_signal control\[105\]  640	output
label_top_signal control\[104\]  645	output
label_top_signal control\[103\]  650	output
label_top_signal control\[102\]  655	output
label_top_signal control\[101\]  660	output
label_top_signal control\[100\]  665	output
label_top_signal control\[99\]   670	output
label_top_signal control\[98\]   675	output
label_top_signal control\[97\]   680	output
label_top_signal control\[96\]   685	output

label_top_signal status\[95\]    690	input
label_top_signal status\[94\]    695	input
label_top_signal status\[93\]    700	input
label_top_signal status\[92\]    705	input
label_top_signal status\[91\]    710	input
label_top_signal status\[90\]    715	input
label_top_signal status\[89\]    720	input
label_top_signal status\[88\]    725	input
label_top_signal status\[87\]    730	input
label_top_signal status\[86\]    735	input
label_top_signal status\[85\]    740	input
label_top_signal status\[84\]    745	input
label_top_signal status\[83\]    750	input
label_top_signal status\[82\]    755	input
label_top_signal status\[81\]    760	input
label_top_signal status\[80\]    765	input
label_top_signal status\[79\]    770	input
label_top_signal status\[78\]    775	input
label_top_signal status\[77\]    780	input
label_top_signal status\[76\]    785	input
label_top_signal status\[75\]    790	input
label_top_signal status\[74\]    795	input
label_top_signal status\[73\]    800	input
label_top_signal status\[72\]    805	input
label_top_signal status\[71\]    810	input
label_top_signal status\[70\]    815	input
label_top_signal status\[69\]    820	input
label_top_signal status\[68\]    825	input
label_top_signal status\[67\]    830	input
label_top_signal status\[66\]    835	input
label_top_signal status\[65\]    840	input
label_top_signal status\[64\]    845	input

label_top_signal control\[95\]   850	output
label_top_signal control\[94\]   855	output
label_top_signal control\[93\]   860	output
label_top_signal control\[92\]   865	output
label_top_signal control\[91\]   870	output
label_top_signal control\[90\]   875	output
label_top_signal control\[89\]   880	output
label_top_signal control\[88\]   885	output
label_top_signal control\[87\]   890	output
label_top_signal control\[86\]   895	output
label_top_signal control\[85\]   900	output
label_top_signal control\[84\]   905	output
label_top_signal control\[83\]   910	output
label_top_signal control\[82\]   915	output
label_top_signal control\[81\]   920	output
label_top_signal control\[80\]   925	output
label_top_signal control\[79\]   930	output
label_top_signal control\[78\]   935	output
label_top_signal control\[77\]   940	output
label_top_signal control\[76\]   945	output
label_top_signal control\[75\]   950	output
label_top_signal control\[74\]   955	output
label_top_signal control\[73\]   960	output
label_top_signal control\[72\]   965	output
label_top_signal control\[71\]   970	output
label_top_signal control\[70\]   975	output
label_top_signal control\[69\]   980	output
label_top_signal control\[68\]   985	output
label_top_signal control\[67\]   990	output
label_top_signal control\[66\]   995	output
label_top_signal control\[65\]  1000	output
label_top_signal control\[64\]  1005	output

label_top_signal reset		1010	output

label_top_signal control\[63\]  1015	output
label_top_signal control\[62\]  1020	output
label_top_signal control\[61\]  1025	output
label_top_signal control\[60\]  1030	output
label_top_signal control\[59\]  1035	output
label_top_signal control\[58\]  1040	output
label_top_signal control\[57\]  1045	output
label_top_signal control\[56\]  1050	output
label_top_signal control\[55\]  1055	output
label_top_signal control\[54\]  1060	output
label_top_signal control\[53\]  1065	output
label_top_signal control\[52\]  1070	output
label_top_signal control\[51\]  1075	output
label_top_signal control\[50\]  1080	output
label_top_signal control\[49\]  1085	output
label_top_signal control\[48\]  1090	output
label_top_signal control\[47\]  1095	output
label_top_signal control\[46\]  1100	output
label_top_signal control\[45\]  1105	output
label_top_signal control\[44\]  1110	output
label_top_signal control\[43\]  1115	output
label_top_signal control\[42\]  1120	output
label_top_signal control\[41\]  1125	output
label_top_signal control\[40\]  1130	output
label_top_signal control\[39\]  1135	output
label_top_signal control\[38\]  1140	output
label_top_signal control\[37\]  1145	output
label_top_signal control\[36\]  1150	output
label_top_signal control\[35\]  1155	output
label_top_signal control\[34\]  1160	output
label_top_signal control\[33\]  1165	output
label_top_signal control\[32\]  1170	output

label_top_signal status\[63\]   1175	input
label_top_signal status\[62\]   1180	input
label_top_signal status\[61\]   1185	input
label_top_signal status\[60\]   1190	input
label_top_signal status\[59\]   1195	input
label_top_signal status\[58\]   1200	input
label_top_signal status\[57\]   1205	input
label_top_signal status\[56\]   1210	input
label_top_signal status\[55\]   1215	input
label_top_signal status\[54\]   1220	input
label_top_signal status\[53\]   1225	input
label_top_signal status\[52\]   1230	input
label_top_signal status\[51\]   1235	input
label_top_signal status\[50\]   1240	input
label_top_signal status\[49\]   1245	input
label_top_signal status\[48\]   1250	input
label_top_signal status\[47\]   1255	input
label_top_signal status\[46\]   1260	input
label_top_signal status\[45\]   1265	input
label_top_signal status\[44\]   1270	input
label_top_signal status\[43\]   1275	input
label_top_signal status\[42\]   1280	input
label_top_signal status\[41\]   1285	input
label_top_signal status\[40\]   1290	input
label_top_signal status\[39\]   1295	input
label_top_signal status\[38\]   1300	input
label_top_signal status\[37\]   1305	input
label_top_signal status\[36\]   1310	input
label_top_signal status\[35\]   1315	input
label_top_signal status\[34\]   1320	input
label_top_signal status\[33\]   1325	input
label_top_signal status\[32\]   1330	input

label_top_signal control\[31\]  1335	output
label_top_signal control\[30\]  1340	output
label_top_signal control\[29\]  1345	output
label_top_signal control\[28\]  1350	output
label_top_signal control\[27\]  1355	output
label_top_signal control\[26\]  1360	output
label_top_signal control\[25\]  1365	output
label_top_signal control\[24\]  1370	output
label_top_signal control\[23\]  1375	output
label_top_signal control\[22\]  1380	output
label_top_signal control\[21\]  1385	output
label_top_signal control\[20\]  1390	output
label_top_signal control\[19\]  1395	output
label_top_signal control\[18\]  1400	output
label_top_signal control\[17\]  1405	output
label_top_signal control\[16\]  1410	output
label_top_signal control\[15\]  1415	output
label_top_signal control\[14\]  1420	output
label_top_signal control\[13\]  1425	output
label_top_signal control\[12\]  1430	output
label_top_signal control\[11\]  1435	output
label_top_signal control\[10\]  1440	output
label_top_signal control\[9\]   1445	output
label_top_signal control\[8\]   1450	output
label_top_signal control\[7\]   1455	output
label_top_signal control\[6\]   1460	output
label_top_signal control\[5\]   1465	output
label_top_signal control\[4\]   1470	output
label_top_signal control\[3\]   1475	output
label_top_signal control\[2\]   1480	output
label_top_signal control\[1\]   1485	output
label_top_signal control\[0\]   1490	output

label_top_signal status\[31\]   1495	input
label_top_signal status\[30\]   1500	input
label_top_signal status\[29\]   1505	input
label_top_signal status\[28\]   1510	input
label_top_signal status\[27\]   1515	input
label_top_signal status\[26\]   1520	input
label_top_signal status\[25\]   1525	input
label_top_signal status\[24\]   1530	input
label_top_signal status\[23\]   1535	input
label_top_signal status\[22\]   1540	input
label_top_signal status\[21\]   1545	input
label_top_signal status\[20\]   1550	input
label_top_signal status\[19\]   1555	input
label_top_signal status\[18\]   1560	input
label_top_signal status\[17\]   1565	input
label_top_signal status\[16\]   1570	input
label_top_signal status\[15\]   1575	input
label_top_signal status\[14\]   1580	input
label_top_signal status\[13\]   1585	input
label_top_signal status\[12\]   1590	input
label_top_signal status\[11\]   1595	input
label_top_signal status\[10\]   1600	input
label_top_signal status\[9\]    1605	input
label_top_signal status\[8\]    1610	input
label_top_signal status\[7\]    1615	input
label_top_signal status\[6\]    1620	input
label_top_signal status\[5\]    1625	input
label_top_signal status\[4\]    1630	input
label_top_signal status\[3\]    1635	input
label_top_signal status\[2\]    1640	input
label_top_signal status\[1\]    1645	input
label_top_signal status\[0\]    1650	input

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
