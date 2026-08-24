/*
 *------------------------------------------------------------------------
 * netlists.v
 *
 * Netlists for sg13cmos5l openframe project
 *
 * This file includes all of the verilog modules for openframe
 * for use in simulation (e.g., iverilog).
 *
 *------------------------------------------------------------------------
 */ 

`timescale 1 ns / 1 ps

`define UNIT_DELAY #1
`define USE_POWER_PINS

`default_nettype none

/* Foundry PDK libraries */
/* Need to pass the PDK root directory to iverilog with option -I */
/* (Local PDK root directory is ~/gits/ihp-sg13cmos5l) */

`include "libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_stdcell.v"
`include "libs.ref/sg13cmos5l_io/verilog/sg13cmos5l_io.v"

/* Layout blocks (no behavioral or functional content) */
`include "caravel_logo.v"
`include "caravel_motto.v"
`include "copyright_block.v"
`include "user_id_textblock.v"
`include "open_source.v"

/* Basic building blocks */
`include "constant_block.v"

/* ROM program for project ID */
`include "user_id_programming.v"

/* User project wrapper */
`include "openframe_project_wrapper.v"

/* User project */
`include "openframe_user_project.v"

/* Padframe */
`include "sg13cmos5l_padframe.v"

/* Top level cell */
`include "sg13cmos5l_caravel_openframe.v"
