/*
 *------------------------------------------------------------------------
 * netlists_lvs.v
 *
 * Netlists for sg13cmos5l openframe project
 * This file includes all of the verilog modules for openframe,
 * excluding modules which are represented as SPICE netlists,
 * for use with netgen LVS.
 *
 *------------------------------------------------------------------------
 */ 

`timescale 1 ns / 1 ps

`define UNIT_DELAY #1
`define USE_POWER_PINS
`define HAS_USER_PROJECT

`default_nettype none

/* Layout blocks (no behavioral or functional content) */
`include "caravel_logo.v"
`include "caravel_motto.v"
`include "copyright_block.v"
`include "user_id_textblock.v"
`include "open_source.v"
`include "sg13cmos5l_caravel_openframe_fill_pattern.v"

/* Basic building blocks */
`include "constant_block.v"

/* ROM program for project ID */
`include "user_id_programming.v"

/* User project wrapper */
`include "openframe_project_wrapper.v"

/* Padframe */
`include "sg13cmos5l_padframe.v"

/* Top level cell (pre-fill) */
`include "sg13cmos5l_caravel_openframe.v"
