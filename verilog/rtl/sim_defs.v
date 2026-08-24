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

// Foundry IP blocks
`include "libs.ref/sg13cmos5l_sram/verilog/RM_IHPSG13_1P_1024x8_c2_bm_bist.v"
`include "libs.ref/sg13cmos5l_sram/verilog/RM_IHPSG13_1P_core_behavioral_bm_bist.v"
`include "libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_stdcell.v"
`include "libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_udp.v"

// All the digital, cobbled together for simulation
`include "digital_top.v"
