// Definitions for running testbench simulation of the digital top
//
// NOTE:  Pass the PDK directory to iverilog with option -I
// e.g., "iverilog -I/home/tim/gits/ihp-sg13cmos5l digital_tb.v"

`timescale 1 ns / 1 ps

`define FUNCTIONAL 1	// forces SRAM and logic to functional mode

// Housekeeping source files
`include "housekeeping.v"
`include "housekeeping_spi.v"
`include "housekeeping_top.v"
`include "lfsr.v"
`include "router.v"
`include "sequencer.v"
`include "pattern.v"

// Blocks outside of housekeeping
`include "user_project_control.v"
`include "user_project_control_base.v"

// User project slot wrappers, one per slot.  Empty of user content, but
// instantiated by digital_top.v so that the digital signalling to and
// from each slot is observable rather than dangling.
`include "slot1_wrapper.v"
`include "slot2_wrapper.v"
`include "slot3_wrapper.v"
`include "slot4_wrapper.v"
`include "slot5_wrapper.v"
`include "slot6_wrapper.v"
`include "slot7_wrapper.v"
`include "slot8_wrapper.v"
`include "slot9_wrapper.v"
`include "slot10_wrapper.v"
`include "slot11_wrapper.v"
`include "slot12_wrapper.v"
`include "slot13_wrapper.v"
`include "slot14_wrapper.v"
`include "slot15_wrapper.v"
`include "slot16_wrapper.v"
`include "slot17_wrapper.v"
`include "slot18_wrapper.v"

// Behavioural models of the analog blocks, from the IP repositories
// where the blocks themselves are defined.  These make digital_top the
// digital equivalent of the whole chip:  switches, power gates and bias
// generators modelled with real-valued ports so that connectivity and
// control can be checked as though everything were digital.
`include "../../dependencies/sg13cmos5l_ocd_ip__analog_switches/verilog/analog_switch.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__analog_switches/verilog/analog_switch_med.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__analog_switches/verilog/analog_switch_small.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__analog_switches/verilog/analog_pswitch_small.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__analog_switches/verilog/power_stage1v2.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__analog_switches/verilog/power_stage2.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__biasgen/verilog/sg13cmos5l_ocd_ip__bandgap_v2.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__biasgen/verilog/sg13cmos5l_ocd_ip__voltgen_v2.v"
`include "../../dependencies/sg13cmos5l_ocd_ip__biasgen/verilog/sg13cmos5l_ocd_ip__biasgen2.v"

// Foundry IP blocks
`include "libs.ref/sg13cmos5l_sram/verilog/RM_IHPSG13_1P_1024x8_c2_bm_bist.v"
`include "libs.ref/sg13cmos5l_sram/verilog/RM_IHPSG13_1P_core_behavioral_bm_bist.v"
`include "libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_stdcell.v"
`include "libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_udp.v"

// All the digital, cobbled together for simulation
`include "digital_top.v"
