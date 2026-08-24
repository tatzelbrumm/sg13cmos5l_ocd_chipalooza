v {xschem version=3.4.6 file_version=1.2}
G {}
K {}
V {}
S {}
E {}
T {Power switches
(schematic position = layout position)} 150 -1000 0 0 0.4 0.4 {}
T {Dual-voltage power domain:
vddio/vssio = 5V
vccd/vssd = 1.2V} -440 -1630 0 0 0.4 0.4 {}
T {Loopback tie-offs.
These resistors match actual metal resistors in the layout,
and have a corresponding matching value.} -910 -1290 0 0 0.3 0.3 {}
T {Note:  The biasgen is connected directly to the power supply, not a switched supply.
In practice, all infrastructure subcircuits will be tied directly to the power
supply;  for the test chip, the bandgap and voltage bias generator are connected
to switched power supplies for testing.} 1270 -1270 0 0 0.3 0.3 {}
T {ena_snk_test0} 1010 -1170 0 0 0.3 0.3 {}
T {ena_src_test0} 1010 -1140 0 0 0.3 0.3 {}
T {(unused, reserved)} 940 -1220 0 0 0.3 0.3 {}
T {Control infrastructure for analog projects (test version)
16 Power domain switches
1  Bandgap
1  Voltage bias generator
Current bias generator with
2  8-bit iDAC sources
2  8-bit iDAC sinks
1  5-bit iDAC sink} 100 -1740 0 0 0.5 0.5 {}
T {Note:  status bits are unused, and tied off arbitrarily to digital one/zero from
nearby loopback signals in the wrapper.} 1190 -200 0 0 0.3 0.3 {}
N -340 -1490 -270 -1490 {lab=vddio}
N -340 -1470 -270 -1470 {lab=vssio}
N -340 -1450 -270 -1450 {lab=vccd}
N -340 -1430 -270 -1430 {lab=vssd}
N -60 -870 -20 -870 {lab=vddio}
N -60 -850 -20 -850 {lab=vssio}
N -130 -890 -20 -890 {lab=control[74]}
N -60 -830 -20 -830 {lab=vssd}
N -60 -810 -20 -810 {lab=vccd}
N -110 -790 -20 -790 {lab=vdda1}
N -60 -730 -20 -730 {lab=vddio}
N -60 -710 -20 -710 {lab=vssio}
N -130 -750 -20 -750 {lab=control[75]}
N -60 -690 -20 -690 {lab=vssd}
N -60 -670 -20 -670 {lab=vccd}
N -110 -650 -20 -650 {lab=vdda2}
N -60 -590 -20 -590 {lab=vddio}
N -60 -570 -20 -570 {lab=vssio}
N -130 -610 -20 -610 {lab=control[76]}
N -60 -550 -20 -550 {lab=vssd}
N -60 -530 -20 -530 {lab=vccd}
N -110 -510 -20 -510 {lab=vdda3}
N -60 -450 -20 -450 {lab=vddio}
N -60 -430 -20 -430 {lab=vssio}
N -130 -470 -20 -470 {lab=control[77]}
N -60 -410 -20 -410 {lab=vssd}
N -60 -390 -20 -390 {lab=vccd}
N -110 -370 -20 -370 {lab=vdda4}
N -60 -310 -20 -310 {lab=vddio}
N -60 -290 -20 -290 {lab=vssio}
N -130 -330 -20 -330 {lab=control[78]}
N -60 -270 -20 -270 {lab=vssd}
N -60 -250 -20 -250 {lab=vccd}
N -110 -230 -20 -230 {lab=vdda5}
N -60 -170 -20 -170 {lab=vddio}
N -60 -150 -20 -150 {lab=vssio}
N -130 -190 -20 -190 {lab=control[79]}
N -60 -130 -20 -130 {lab=vssd}
N -60 -110 -20 -110 {lab=vccd}
N -110 -90 -20 -90 {lab=vdda6}
N -60 -30 -20 -30 {lab=vddio}
N -60 -10 -20 -10 {lab=vssio}
N -130 -50 -20 -50 {lab=control[80]}
N -60 10 -20 10 {lab=vssd}
N -60 30 -20 30 {lab=vccd}
N -110 50 -20 50 {lab=vdda7}
N 620 -870 660 -870 {lab=vddio}
N 620 -850 660 -850 {lab=vssio}
N 620 -890 730 -890 {lab=control[27]}
N 620 -830 660 -830 {lab=vssd}
N 620 -810 660 -810 {lab=vccd}
N 620 -790 710 -790 {lab=vdda16}
N 620 -730 660 -730 {lab=vddio}
N 620 -710 660 -710 {lab=vssio}
N 620 -750 730 -750 {lab=control[26]}
N 620 -690 660 -690 {lab=vssd}
N 620 -670 660 -670 {lab=vccd}
N 620 -650 710 -650 {lab=vdda15}
N 620 -590 660 -590 {lab=vddio}
N 620 -570 660 -570 {lab=vssio}
N 620 -610 730 -610 {lab=control[25]}
N 620 -550 660 -550 {lab=vssd}
N 620 -530 660 -530 {lab=vccd}
N 620 -510 710 -510 {lab=vdda14}
N 620 -450 660 -450 {lab=vddio}
N 620 -430 660 -430 {lab=vssio}
N 620 -470 730 -470 {lab=control[24]}
N 620 -410 660 -410 {lab=vssd}
N 620 -390 660 -390 {lab=vccd}
N 620 -370 710 -370 {lab=vdda13}
N 620 -310 660 -310 {lab=vddio}
N 620 -290 660 -290 {lab=vssio}
N 620 -330 730 -330 {lab=control[23]}
N 620 -270 660 -270 {lab=vssd}
N 620 -250 660 -250 {lab=vccd}
N 620 -230 710 -230 {lab=vdda12}
N 620 -170 660 -170 {lab=vddio}
N 620 -150 660 -150 {lab=vssio}
N 620 -190 730 -190 {lab=control[22]}
N 620 -130 660 -130 {lab=vssd}
N 620 -110 660 -110 {lab=vccd}
N 620 -90 710 -90 {lab=vdda11}
N 620 -30 660 -30 {lab=vddio}
N 620 -10 660 -10 {lab=vssio}
N 620 -50 730 -50 {lab=control[21]}
N 620 10 660 10 {lab=vssd}
N 620 30 660 30 {lab=vccd}
N 620 50 710 50 {lab=vdda10}
N 2460 -640 2460 -590 {lab=vssd}
N 2570 -640 2570 -590 {lab=vssio}
N 2460 -930 2460 -880 {lab=vccd}
N 2570 -930 2570 -880 {lab=vdda5}
N 2670 -780 2740 -780 {lab=voltgen_vout1}
N 2670 -730 2740 -730 {lab=voltgen_vout2}
N 2020 -1020 2050 -1020 {lab=vbg}
N 2320 -780 2370 -780 {lab=vbg}
N 1770 -880 1800 -880 {lab=idac1_sink}
N 1550 -880 1660 -880 {lab=#net1}
N 1550 -820 2370 -820 {lab=#net2}
N 1550 -800 2370 -800 {lab=#net3}
N 1550 -1040 1610 -1040 {lab=vddio}
N 1550 -1020 1610 -1020 {lab=vssio}
N 1550 -1000 1610 -1000 {lab=vccd}
N 1550 -980 1610 -980 {lab=vssd}
N 1740 -1040 1800 -1040 {lab=vdda12}
N 1740 -1020 1800 -1020 {lab=vccd}
N 1740 -1000 1800 -1000 {lab=vssd}
N 1740 -920 1800 -920 {lab=vssio}
N 1210 -1000 1250 -1000 {lab=vbg}
N 1210 -1120 1210 -1000 {lab=vbg}
N 1210 -1120 2020 -1120 {lab=vbg}
N 2020 -1120 2020 -1020 {lab=vbg}
N 1980 -1020 2020 -1020 {lab=vbg}
N 1150 -980 1250 -980 {lab=control[87]}
N 1150 -960 1250 -960 {lab=control[86]}
N 1150 -940 1250 -940 {lab=control[85]}
N 1150 -900 1250 -900 {lab=control[71:73],control[82:83]}
N 1150 -880 1250 -880 {lab=control[107:103]}
N 1150 -860 1250 -860 {lab=control[58:62]}
N 1150 -840 1250 -840 {lab=control[45:49]}
N 1150 -820 1250 -820 {lab=control[121:117]}
N 1150 -800 1250 -800 {lab=control[94:90]}
N 1150 -780 1250 -780 {lab=control[63:70]}
N 1150 -760 1250 -760 {lab=control[102:95]}
N 1150 -740 1250 -740 {lab=control[50:57]}
N 1150 -720 1250 -720 {lab=control[115:108]}
N 1150 -1040 1250 -1040 {lab=control[88]}
N 1550 -860 1800 -860 {lab=#net4}
N 1800 -860 1800 -840 {lab=#net4}
N 1800 -840 2370 -840 {lab=#net4}
N 1770 -980 1800 -980 {lab=control[28]}
N 1770 -940 1800 -940 {lab=control[29:44]}
N 2270 -760 2370 -760 {lab=control[124]}
N 2270 -740 2370 -740 {lab=control[126]}
N 2270 -720 2370 -720 {lab=control[125]}
N 2270 -700 2370 -700 {lab=control[127]}
N 2270 -680 2370 -680 {lab=control[116],control[122:123]}
N -740 -880 -700 -880 {lab=spi_SDI_zero}
N -740 -850 -700 -850 {lab=spi_SDI_zero}
N -740 -880 -740 -850 {lab=spi_SDI_zero}
N -770 -880 -740 -880 {lab=spi_SDI_zero}
N -740 -810 -700 -810 {lab=spi_CSB_zero}
N -740 -780 -700 -780 {lab=spi_CSB_zero}
N -740 -810 -740 -780 {lab=spi_CSB_zero}
N -770 -810 -740 -810 {lab=spi_CSB_zero}
N -740 -750 -700 -750 {lab=spi_SCK_zero}
N -740 -720 -700 -720 {lab=spi_SCK_zero}
N -740 -750 -740 -720 {lab=spi_SCK_zero}
N -770 -750 -740 -750 {lab=spi_SCK_zero}
N 1010 -1020 1250 -1020 {lab=ref_in}
N 1550 -840 1600 -840 {lab=test_source_ibias}
N 1540 -320 1570 -320 {lab=#net5}
N 1540 -300 1600 -300 {lab=control[127:0]}
N 1170 -320 1240 -320 {lab=mask_rev[31:0]}
N 1170 -360 1240 -360 {lab=spi_CSB_in}
N 1170 -380 1240 -380 {lab=spi_SDI_in}
N 1170 -400 1240 -400 {lab=spi_SCK_in}
N 1170 -420 1240 -420 {lab=resetb_in}
N 1180 -440 1240 -440 {lab=vssd}
N 1180 -460 1240 -460 {lab=vccd}
N 1540 -380 1580 -380 {lab=spi_SDO_out}
N 1540 -360 1580 -360 {lab=spi_SDO_ena}
N 1130 50 1200 50 {lab=spi_SDO_zero}
N 1130 110 1200 110 {lab=flash_io3_one}
N 1620 -30 1680 -30 {lab=control[19:0]}
N 960 -1160 980 -1160 {lab=control[89]}
N 960 -1130 980 -1130 {lab=control[84]}
N -740 -1100 -700 -1100 {lab=gpio1_zero}
N -740 -1070 -700 -1070 {lab=gpio1_zero}
N -740 -1100 -740 -1070 {lab=gpio1_zero}
N -770 -1100 -740 -1100 {lab=gpio1_zero}
N -740 -1030 -700 -1030 {lab=UART_Rx_zero}
N -740 -1000 -700 -1000 {lab=UART_Rx_zero}
N -740 -1030 -740 -1000 {lab=UART_Rx_zero}
N -770 -1030 -740 -1030 {lab=UART_Rx_zero}
N -740 -970 -700 -970 {lab=UART_Tx_zero}
N -740 -940 -700 -940 {lab=UART_Tx_zero}
N -740 -970 -740 -940 {lab=UART_Tx_zero}
N -770 -970 -740 -970 {lab=UART_Tx_zero}
N -640 -1100 -620 -1100 {lab=gpio1_ena}
N -640 -1070 -620 -1070 {lab=gpio1_out}
N -640 -1030 -620 -1030 {lab=UART_Rx_ena}
N -640 -1000 -620 -1000 {lab=UART_Rx_out}
N -640 -970 -620 -970 {lab=UART_Tx_ena}
N -640 -940 -620 -940 {lab=UART_Tx_out}
N -640 -880 -610 -880 {lab=spi_SDI_ena}
N -640 -850 -610 -850 {lab=spi_SDI_out}
N -640 -810 -610 -810 {lab=spi_CSB_ena}
N -640 -780 -610 -780 {lab=spi_CSB_out}
N -640 -750 -610 -750 {lab=spi_SCK_ena}
N -640 -720 -610 -720 {lab=spi_SCK_out}
N -70 110 -30 110 {lab=vddio}
N -70 130 -30 130 {lab=vssio}
N -140 90 -30 90 {lab=control[81]}
N -70 150 -30 150 {lab=vssd}
N -70 170 -30 170 {lab=vccd}
N -120 190 -30 190 {lab=vdda8}
N 620 110 660 110 {lab=vddio}
N 620 130 660 130 {lab=vssio}
N 620 90 730 90 {lab=control[20]}
N 620 150 660 150 {lab=vssd}
N 620 170 660 170 {lab=vccd}
N 620 190 710 190 {lab=vdda9}
N 1130 -10 1200 -10 {lab=spi_SDO_one}
N 1170 -300 1240 -300 {lab=flash_io3_zero*32,flash_io3_one*32,spi_SDO_zero*32,spi_SDO_one*32}
N 1170 -300 1170 -230 {lab=flash_io3_zero*32,flash_io3_one*32,spi_SDO_zero*32,spi_SDO_one*32}
N -740 -660 -700 -660 {lab=flash_csb_zero}
N -740 -630 -700 -630 {lab=flash_csb_zero}
N -740 -660 -740 -630 {lab=flash_csb_zero}
N -770 -660 -740 -660 {lab=flash_csb_zero}
N -640 -660 -610 -660 {lab=flash_csb_ena}
N -640 -630 -610 -630 {lab=flash_csb_out}
N -740 -570 -700 -570 {lab=flash_clk_zero}
N -740 -540 -700 -540 {lab=flash_clk_zero}
N -740 -570 -740 -540 {lab=flash_clk_zero}
N -770 -570 -740 -570 {lab=flash_clk_zero}
N -640 -570 -610 -570 {lab=flash_clk_ena}
N -640 -540 -610 -540 {lab=flash_clk_out}
N -740 -480 -700 -480 {lab=flash_io0_zero}
N -740 -450 -700 -450 {lab=flash_io0_zero}
N -740 -480 -740 -450 {lab=flash_io0_zero}
N -770 -480 -740 -480 {lab=flash_io0_zero}
N -640 -480 -610 -480 {lab=flash_io0_ena}
N -640 -450 -610 -450 {lab=flash_io0_out}
N -740 -380 -700 -380 {lab=flash_io1_zero}
N -740 -350 -700 -350 {lab=flash_io1_zero}
N -740 -380 -740 -350 {lab=flash_io1_zero}
N -770 -380 -740 -380 {lab=flash_io1_zero}
N -640 -380 -610 -380 {lab=flash_io1_ena}
N -640 -350 -610 -350 {lab=flash_io1_out}
N -740 -290 -700 -290 {lab=flash_io2_zero}
N -740 -260 -700 -260 {lab=flash_io2_zero}
N -740 -290 -740 -260 {lab=flash_io2_zero}
N -770 -290 -740 -290 {lab=flash_io2_zero}
N -640 -290 -610 -290 {lab=flash_io2_ena}
N -640 -260 -610 -260 {lab=flash_io2_out}
N -740 -200 -700 -200 {lab=flash_io3_zero}
N -740 -170 -700 -170 {lab=flash_io3_zero}
N -740 -200 -740 -170 {lab=flash_io3_zero}
N -770 -200 -740 -200 {lab=flash_io3_zero}
N -640 -200 -610 -200 {lab=flash_io3_ena}
N -640 -170 -610 -170 {lab=flash_io3_out}
N -740 -1170 -700 -1170 {lab=gpio0_zero}
N -740 -1140 -700 -1140 {lab=gpio0_zero}
N -740 -1170 -740 -1140 {lab=gpio0_zero}
N -770 -1170 -740 -1170 {lab=gpio0_zero}
N -640 -1170 -620 -1170 {lab=gpio0_ena}
N -640 -1140 -620 -1140 {lab=gpio0_out}
N 1660 -900 1800 -900 {lab=#net1}
N 1660 -900 1660 -880 {lab=#net1}
N 1550 -780 1790 -780 {lab=idac1_source}
N 1770 -760 1790 -760 {lab=idac1_sink}
N 1550 -740 1790 -740 {lab=idac2_source}
N 1550 -720 1790 -720 {lab=idac2_sink}
N 1770 -880 1770 -760 {lab=idac1_sink}
N 1550 -760 1770 -760 {lab=idac1_sink}
N 1550 -900 1580 -900 {lab=test_source}
N 1580 -900 1580 -700 {lab=test_source}
N 1580 -700 1610 -700 {lab=test_source}
C {power_stage.sym} 130 0 0 0 {name=x1}
C {power_stage.sym} 130 -140 0 0 {name=x2}
C {power_stage.sym} 130 -280 0 0 {name=x3}
C {power_stage.sym} 130 -420 0 0 {name=x4}
C {power_stage.sym} 130 -560 0 0 {name=x5}
C {power_stage.sym} 130 -700 0 0 {name=x6}
C {power_stage.sym} 130 -840 0 0 {name=x7}
C {power_stage.sym} 470 0 0 1 {name=x8}
C {power_stage.sym} 470 -140 0 1 {name=x9}
C {power_stage.sym} 470 -280 0 1 {name=x10}
C {power_stage.sym} 470 -420 0 1 {name=x11}
C {power_stage.sym} 470 -560 0 1 {name=x12}
C {power_stage.sym} 470 -700 0 1 {name=x13}
C {power_stage.sym} 470 -840 0 1 {name=x14}
C {sg13cmos5l_ocd_ip__bandgap.sym} 1820 -940 0 0 {name=x15}
C {sg13cmos5l_ocd_ip__biasgen1.sym} 1400 -720 0 0 {name=x16}
C {sg13cmos5l_ocd_ip__voltgen.sym} 2520 -730 0 0 {name=x17}
C {iopin.sym} -340 -1490 0 1 {name=p1 lab=vddio}
C {iopin.sym} -340 -1470 0 1 {name=p2 lab=vssio}
C {iopin.sym} -340 -1450 0 1 {name=p3 lab=vccd}
C {iopin.sym} -340 -1430 0 1 {name=p4 lab=vssd}
C {lab_pin.sym} -270 -1490 0 1 {name=p5 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -270 -1470 0 1 {name=p6 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -270 -1450 0 1 {name=p7 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -270 -1430 0 1 {name=p8 sig_type=std_logic lab=vssd}
C {lab_pin.sym} -60 -870 0 0 {name=p9 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -60 -850 0 0 {name=p11 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -110 -790 0 0 {name=p12 sig_type=std_logic lab=vdda1}
C {lab_pin.sym} -60 -810 0 0 {name=p13 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -60 -730 0 0 {name=p15 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -60 -710 0 0 {name=p17 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -110 -650 0 0 {name=p18 sig_type=std_logic lab=vdda2}
C {lab_pin.sym} -60 -670 0 0 {name=p19 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -60 -590 0 0 {name=p21 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -60 -570 0 0 {name=p23 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -110 -510 0 0 {name=p24 sig_type=std_logic lab=vdda3}
C {lab_pin.sym} -60 -530 0 0 {name=p25 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -60 -450 0 0 {name=p27 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -60 -430 0 0 {name=p29 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -110 -370 0 0 {name=p30 sig_type=std_logic lab=vdda4}
C {lab_pin.sym} -60 -390 0 0 {name=p31 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -60 -310 0 0 {name=p33 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -60 -290 0 0 {name=p35 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -110 -230 0 0 {name=p36 sig_type=std_logic lab=vdda5}
C {lab_pin.sym} -60 -250 0 0 {name=p37 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -60 -170 0 0 {name=p39 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -60 -150 0 0 {name=p41 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -110 -90 0 0 {name=p42 sig_type=std_logic lab=vdda6}
C {lab_pin.sym} -60 -110 0 0 {name=p43 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -60 -30 0 0 {name=p45 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -60 -10 0 0 {name=p47 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -110 50 0 0 {name=p48 sig_type=std_logic lab=vdda7}
C {lab_pin.sym} -60 30 0 0 {name=p49 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 660 -870 0 1 {name=p51 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 -850 0 1 {name=p53 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 710 -510 0 1 {name=p54 sig_type=std_logic lab=vdda14}
C {lab_pin.sym} 660 -810 0 1 {name=p55 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 660 -730 0 1 {name=p57 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 -710 0 1 {name=p59 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 710 -370 0 1 {name=p60 sig_type=std_logic lab=vdda13}
C {lab_pin.sym} 660 -670 0 1 {name=p61 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 660 -590 0 1 {name=p63 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 -570 0 1 {name=p65 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 710 -230 0 1 {name=p66 sig_type=std_logic lab=vdda12}
C {lab_pin.sym} 660 -530 0 1 {name=p67 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 660 -450 0 1 {name=p69 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 -430 0 1 {name=p71 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 710 -90 0 1 {name=p72 sig_type=std_logic lab=vdda11}
C {lab_pin.sym} 660 -390 0 1 {name=p73 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 660 -310 0 1 {name=p75 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 -290 0 1 {name=p77 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 710 50 0 1 {name=p78 sig_type=std_logic lab=vdda10}
C {lab_pin.sym} 660 -250 0 1 {name=p79 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 660 -170 0 1 {name=p81 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 -150 0 1 {name=p83 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 710 190 0 1 {name=p84 sig_type=std_logic lab=vdda9}
C {lab_pin.sym} 660 -110 0 1 {name=p85 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 660 -30 0 1 {name=p87 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 -10 0 1 {name=p89 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 660 30 0 1 {name=p91 sig_type=std_logic lab=vccd}
C {ipin.sym} 1170 -420 0 0 {name=p93 lab=resetb_in}
C {ipin.sym} 1170 -320 0 0 {name=p99 lab=mask_rev[31:0]}
C {lab_pin.sym} -130 -890 0 0 {name=p10 sig_type=std_logic lab=control[74]}
C {lab_pin.sym} -130 -750 0 0 {name=p16 sig_type=std_logic lab=control[75]}
C {lab_pin.sym} -130 -610 0 0 {name=p22 sig_type=std_logic lab=control[76]}
C {lab_pin.sym} -130 -470 0 0 {name=p28 sig_type=std_logic lab=control[77]}
C {lab_pin.sym} -130 -330 0 0 {name=p34 sig_type=std_logic lab=control[78]}
C {lab_pin.sym} -130 -190 0 0 {name=p40 sig_type=std_logic lab=control[79]}
C {lab_pin.sym} -130 -50 0 0 {name=p46 sig_type=std_logic lab=control[80]}
C {lab_pin.sym} 730 -890 0 1 {name=p58 sig_type=std_logic lab=control[27]}
C {lab_pin.sym} 730 -750 0 1 {name=p64 sig_type=std_logic lab=control[26]}
C {lab_pin.sym} 730 -610 0 1 {name=p70 sig_type=std_logic lab=control[25]}
C {lab_pin.sym} 730 -470 0 1 {name=p76 sig_type=std_logic lab=control[24]}
C {lab_pin.sym} 730 -330 0 1 {name=p82 sig_type=std_logic lab=control[23]}
C {lab_pin.sym} 730 -190 0 1 {name=p88 sig_type=std_logic lab=control[22]}
C {lab_pin.sym} 2460 -590 3 0 {name=p102 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 2570 -590 3 0 {name=p103 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 2460 -930 1 0 {name=p104 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 2570 -930 1 0 {name=p105 sig_type=std_logic lab=vdda5}
C {lab_pin.sym} 2320 -780 0 0 {name=p107 sig_type=std_logic lab=vbg}
C {lab_pin.sym} 1740 -1020 0 0 {name=p108 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 1740 -1000 0 0 {name=p109 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 1740 -1040 0 0 {name=p110 sig_type=std_logic lab=vdda12}
C {lab_pin.sym} 1610 -1040 2 0 {name=p111 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 1740 -920 0 0 {name=p112 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 1610 -1020 0 1 {name=p113 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 1610 -1000 0 1 {name=p114 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 1610 -980 0 1 {name=p115 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 1150 -960 0 0 {name=p117 sig_type=std_logic lab=control[86]}
C {lab_pin.sym} 1150 -940 0 0 {name=p118 sig_type=std_logic lab=control[85]}
C {lab_pin.sym} 1150 -900 0 0 {name=p119 sig_type=std_logic lab=control[71:73],control[82:83]}
C {lab_pin.sym} 1150 -880 0 0 {name=p120 sig_type=std_logic lab=control[107:103]}
C {lab_pin.sym} 1150 -860 0 0 {name=p121 sig_type=std_logic lab=control[58:62]}
C {lab_pin.sym} 1150 -840 0 0 {name=p122 sig_type=std_logic lab=control[45:49]}
C {lab_pin.sym} 1150 -820 0 0 {name=p123 sig_type=std_logic lab=control[121:117]}
C {lab_pin.sym} 1150 -800 0 0 {name=p124 sig_type=std_logic lab=control[94:90]}
C {lab_pin.sym} 1150 -780 0 0 {name=p125 sig_type=std_logic lab=control[63:70]}
C {lab_pin.sym} 1150 -760 0 0 {name=p126 sig_type=std_logic lab=control[102:95]}
C {lab_pin.sym} 1150 -740 0 0 {name=p127 sig_type=std_logic lab=control[50:57]}
C {lab_pin.sym} 1150 -720 0 0 {name=p128 sig_type=std_logic lab=control[115:108]}
C {lab_pin.sym} 1150 -980 0 0 {name=p129 sig_type=std_logic lab=control[87]}
C {lab_pin.sym} 1150 -1040 0 0 {name=p130 sig_type=std_logic lab=control[88]}
C {lab_pin.sym} 730 -50 0 1 {name=p138 sig_type=std_logic lab=control[21]}
C {lab_pin.sym} 1770 -980 0 0 {name=p52 sig_type=std_logic lab=control[28]}
C {lab_pin.sym} 1770 -940 0 0 {name=p139 sig_type=std_logic lab=control[29:44]}
C {lab_pin.sym} 2270 -760 0 0 {name=p140 sig_type=std_logic lab=control[124]}
C {lab_pin.sym} 2270 -740 0 0 {name=p141 sig_type=std_logic lab=control[126]}
C {lab_pin.sym} 2270 -720 0 0 {name=p142 sig_type=std_logic lab=control[125]}
C {lab_pin.sym} 2270 -700 0 0 {name=p143 sig_type=std_logic lab=control[127]}
C {lab_pin.sym} 2270 -680 0 0 {name=p144 sig_type=std_logic lab=control[116],control[122:123]}
C {opin.sym} 1580 -380 0 0 {name=p94 lab=spi_SDO_out}
C {opin.sym} 1580 -360 0 0 {name=p95 lab=spi_SDO_ena}
C {opin.sym} -610 -880 0 0 {name=p96 lab=spi_SDI_ena}
C {opin.sym} -610 -850 0 0 {name=p97 lab=spi_SDI_out}
C {ipin.sym} -770 -880 0 0 {name=p98 lab=spi_SDI_zero}
C {ipin.sym} 1170 -380 0 0 {name=p100 lab=spi_SDI_in}
C {opin.sym} -610 -810 0 0 {name=p101 lab=spi_CSB_ena}
C {opin.sym} -610 -780 0 0 {name=p145 lab=spi_CSB_out}
C {ipin.sym} -770 -810 0 0 {name=p146 lab=spi_CSB_zero}
C {ipin.sym} 1170 -360 0 0 {name=p147 lab=spi_CSB_in}
C {opin.sym} -610 -750 0 0 {name=p148 lab=spi_SCK_ena}
C {opin.sym} -610 -720 0 0 {name=p149 lab=spi_SCK_out}
C {ipin.sym} -770 -750 0 0 {name=p150 lab=spi_SCK_zero}
C {ipin.sym} 1170 -400 0 0 {name=p151 lab=spi_SCK_in}
C {opin.sym} 2050 -1020 0 0 {name=p152 lab=vbg}
C {ipin.sym} 1010 -1020 0 0 {name=p106 lab=ref_in}
C {ipin.sym} 1790 -760 0 1 {name=p116 lab=idac1_sink}
C {ipin.sym} 1790 -720 0 1 {name=p153 lab=idac2_sink}
C {opin.sym} 1790 -780 0 0 {name=p131 lab=idac1_source}
C {opin.sym} 1790 -740 0 0 {name=p132 lab=idac2_source}
C {opin.sym} 1600 -840 0 0 {name=p133 lab=test_source_ibias}
C {opin.sym} 2740 -780 0 0 {name=p134 lab=voltgen_vout1}
C {opin.sym} 2740 -730 0 0 {name=p135 lab=voltgen_vout2}
C {housekeeping_top.sym} 1390 -360 0 0 {name=x18}
C {noconn.sym} 1570 -320 0 1 {name=l1}
C {lab_pin.sym} 1600 -300 0 1 {name=p136 sig_type=std_logic lab=control[127:0]}
C {lab_pin.sym} 1180 -440 0 0 {name=p137 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 1180 -460 0 0 {name=p154 sig_type=std_logic lab=vccd}
C {lab_pin.sym} 960 -1160 0 0 {name=p155 sig_type=std_logic lab=control[89]}
C {lab_pin.sym} 960 -1130 0 0 {name=p156 sig_type=std_logic lab=control[84]}
C {ipin.sym} 1130 -10 0 0 {name=p157 lab=spi_SDO_one}
C {ipin.sym} 1130 50 0 0 {name=p158 lab=spi_SDO_zero}
C {ipin.sym} 1130 110 0 0 {name=p161 lab=flash_io3_one}
C {noconn.sym} 1680 -30 0 1 {name=l2}
C {lab_pin.sym} 1620 -30 0 0 {name=p165 sig_type=std_logic lab=control[19:0]}
C {noconn.sym} 980 -1160 0 1 {name=l3}
C {noconn.sym} 980 -1130 0 1 {name=l4}
C {opin.sym} -620 -1100 0 0 {name=p166 lab=gpio1_ena}
C {opin.sym} -620 -1070 0 0 {name=p167 lab=gpio1_out}
C {ipin.sym} -770 -1100 0 0 {name=p168 lab=gpio1_zero}
C {opin.sym} -620 -1030 0 0 {name=p169 lab=UART_Rx_ena}
C {opin.sym} -620 -1000 0 0 {name=p170 lab=UART_Rx_out}
C {ipin.sym} -770 -1030 0 0 {name=p171 lab=UART_Rx_zero}
C {opin.sym} -620 -970 0 0 {name=p172 lab=UART_Tx_ena}
C {opin.sym} -620 -940 0 0 {name=p173 lab=UART_Tx_out}
C {ipin.sym} -770 -970 0 0 {name=p174 lab=UART_Tx_zero}
C {res.sym} -670 -1100 1 0 {name=R1
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -1070 1 0 {name=R2
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -1030 1 0 {name=R3
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -1000 1 0 {name=R4
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -970 1 0 {name=R5
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -940 1 0 {name=R6
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -880 1 0 {name=R7
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -850 1 0 {name=R8
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -810 1 0 {name=R9
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -780 1 0 {name=R10
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -750 1 0 {name=R11
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -720 1 0 {name=R12
value=0.0293
device=resistor
m=1}
C {power_stage.sym} 120 140 0 0 {name=x19}
C {power_stage.sym} 470 140 0 1 {name=x20}
C {lab_pin.sym} -70 110 0 0 {name=p175 sig_type=std_logic lab=vddio}
C {lab_pin.sym} -70 130 0 0 {name=p176 sig_type=std_logic lab=vssio}
C {lab_pin.sym} -120 190 0 0 {name=p177 sig_type=std_logic lab=vdda8}
C {lab_pin.sym} -70 170 0 0 {name=p178 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -70 150 0 0 {name=p179 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 110 0 1 {name=p180 sig_type=std_logic lab=vddio}
C {lab_pin.sym} 660 130 0 1 {name=p181 sig_type=std_logic lab=vssio}
C {lab_pin.sym} 660 170 0 1 {name=p183 sig_type=std_logic lab=vccd}
C {lab_pin.sym} -140 90 0 0 {name=p185 sig_type=std_logic lab=control[81]}
C {lab_pin.sym} 730 90 0 1 {name=p186 sig_type=std_logic lab=control[20]}
C {lab_pin.sym} 1170 -230 0 1 {name=p160 sig_type=std_logic lab=flash_io3_zero*32,flash_io3_one*32,spi_SDO_zero*32,spi_SDO_one*32}
C {lab_pin.sym} 1200 -10 0 1 {name=p159 sig_type=std_logic lab=spi_SDO_one}
C {lab_pin.sym} 1200 50 0 1 {name=p163 sig_type=std_logic lab=spi_SDO_zero}
C {lab_pin.sym} 1200 110 0 1 {name=p164 sig_type=std_logic lab=flash_io3_one}
C {lab_pin.sym} 710 -650 0 1 {name=p90 sig_type=std_logic lab=vdda15}
C {lab_pin.sym} 710 -790 0 1 {name=p182 sig_type=std_logic lab=vdda16}
C {lab_pin.sym} -60 10 0 0 {name=p14 sig_type=std_logic lab=vssd}
C {lab_pin.sym} -60 -130 0 0 {name=p20 sig_type=std_logic lab=vssd}
C {lab_pin.sym} -60 -270 0 0 {name=p26 sig_type=std_logic lab=vssd}
C {lab_pin.sym} -60 -410 0 0 {name=p32 sig_type=std_logic lab=vssd}
C {lab_pin.sym} -60 -550 0 0 {name=p38 sig_type=std_logic lab=vssd}
C {lab_pin.sym} -60 -690 0 0 {name=p44 sig_type=std_logic lab=vssd}
C {lab_pin.sym} -60 -830 0 0 {name=p50 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 -830 0 1 {name=p56 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 -690 0 1 {name=p62 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 -550 0 1 {name=p68 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 -410 0 1 {name=p74 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 -270 0 1 {name=p80 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 -130 0 1 {name=p86 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 10 0 1 {name=p92 sig_type=std_logic lab=vssd}
C {lab_pin.sym} 660 150 0 1 {name=p184 sig_type=std_logic lab=vssd}
C {res.sym} -670 -1170 1 0 {name=R13
value=0.018
device=resistor
m=1}
C {res.sym} -670 -1140 1 0 {name=R14
value=0.018
device=resistor
m=1}
C {opin.sym} -610 -660 0 0 {name=p191 lab=flash_csb_ena}
C {opin.sym} -610 -630 0 0 {name=p192 lab=flash_csb_out}
C {ipin.sym} -770 -660 0 0 {name=p193 lab=flash_csb_zero}
C {res.sym} -670 -660 1 0 {name=R15
value=0.018
device=resistor
m=1}
C {res.sym} -670 -630 1 0 {name=R16
value=0.018
device=resistor
m=1}
C {opin.sym} -610 -570 0 0 {name=p194 lab=flash_clk_ena}
C {opin.sym} -610 -540 0 0 {name=p195 lab=flash_clk_out}
C {ipin.sym} -770 -570 0 0 {name=p196 lab=flash_clk_zero}
C {res.sym} -670 -570 1 0 {name=R17
value=0.018
device=resistor
m=1}
C {res.sym} -670 -540 1 0 {name=R18
value=0.018
device=resistor
m=1}
C {opin.sym} -610 -480 0 0 {name=p197 lab=flash_io0_ena}
C {opin.sym} -610 -450 0 0 {name=p198 lab=flash_io0_out}
C {ipin.sym} -770 -480 0 0 {name=p199 lab=flash_io0_zero}
C {res.sym} -670 -480 1 0 {name=R19
value=0.018
device=resistor
m=1}
C {res.sym} -670 -450 1 0 {name=R20
value=0.018
device=resistor
m=1}
C {opin.sym} -610 -380 0 0 {name=p200 lab=flash_io1_ena}
C {opin.sym} -610 -350 0 0 {name=p201 lab=flash_io1_out}
C {ipin.sym} -770 -380 0 0 {name=p202 lab=flash_io1_zero}
C {res.sym} -670 -380 1 0 {name=R21
value=0.018
device=resistor
m=1}
C {res.sym} -670 -350 1 0 {name=R22
value=0.018
device=resistor
m=1}
C {opin.sym} -610 -290 0 0 {name=p203 lab=flash_io2_ena}
C {opin.sym} -610 -260 0 0 {name=p204 lab=flash_io2_out}
C {ipin.sym} -770 -290 0 0 {name=p205 lab=flash_io2_zero}
C {res.sym} -670 -290 1 0 {name=R23
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -260 1 0 {name=R24
value=0.0293
device=resistor
m=1}
C {opin.sym} -610 -200 0 0 {name=p206 lab=flash_io3_ena}
C {opin.sym} -610 -170 0 0 {name=p207 lab=flash_io3_out}
C {ipin.sym} -770 -200 0 0 {name=p208 lab=flash_io3_zero}
C {res.sym} -670 -200 1 0 {name=R25
value=0.0293
device=resistor
m=1}
C {res.sym} -670 -170 1 0 {name=R26
value=0.0293
device=resistor
m=1}
C {opin.sym} -620 -1170 0 0 {name=p188 lab=gpio0_ena}
C {opin.sym} -620 -1140 0 0 {name=p189 lab=gpio0_out}
C {ipin.sym} -770 -1170 0 0 {name=p190 lab=gpio0_zero}
C {opin.sym} 1610 -700 0 0 {name=p162 lab=test_source}
