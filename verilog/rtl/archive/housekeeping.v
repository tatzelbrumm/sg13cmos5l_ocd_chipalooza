// SPDX-FileCopyrightText: 2026 Open Circuit Design, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
//
// Original SPDX-FileCopyrightText: 2020 Efabless Corporation

`default_nettype none
//----------------------------------------------------------
// SPI controller for Caravel openframe project
//----------------------------------------------------------
// Written by Tim Edwards
// efabless, inc. September 27, 2020
// Modified for the GF180MCU openframe project
// by Tim Edwards, Open Circuit Design, LLC
// December 2025
// Modified for the IHPSG13CMOS5L openframe projects
// by Tim Edwards, Open Circuit Design, LLC
// March 2026
// Modified for the Chipalooza challenge
// by Tim Edwards, Open Circuit Design, LLC
// July 2026
//----------------------------------------------------------

//-----------------------------------------------------------
// This is a standalone SPI for the caravel chip that is
// intended to drive all functions required for the
// user project.
//
// This module has been adapted for the IHPSG13CMOS5L
// openframe architecture.
//
// For the Chipalooza analog harness chip, the registers
// are as documented in doc/
//
//-----------------------------------------------------------

//------------------------------------------------------------
// Caravel openframe project defined registers:
// Register 0:  SPI status and control (unused & reserved)
// Register 1 and 2:  Manufacturer ID (0x0567) (readonly)
// Register 3:  Product ID (= 24) (readonly)
// Register 4-7: Mask revision (readonly) --- Externally programmed
//	with via programming.  Via programmed with a script to match
//	each project ID.
//
// Register 0x10:	sequencer mode
// Register 0x11:	SRAM mode
// Register 0x12:	clock prescaler
// Register 0x13-0x14:	sequencer start value
// Register 0x15-0x16:	sequencer stop value
// Register 0x17:	iDAC1 value
// Register 0x18:	iDAC1 control
// Register 0x19:	iDAC2 value
// Register 0x1A:	iDAC2 control
// Register 0x1B:	voltage bias control
// Register 0x1C:	bandgap control
// Register 0x20-0x37:	user project digital input routing
// Register 0x38:	user project digital output (sampled)
// Register 0x40-0x47:	user project digital output routing
// Register 0x50-0x5F:	user project configuration
//------------------------------------------------------------

module housekeeping (
`ifdef USE_POWER_PINS
    inout wire VPWR,		// 1.8V supply
    inout wire VGND,		// common ground
`endif
    
    input wire porb,		// from padframe
    input wire clk,		// from padframe
    input wire SCK,		// from padframe
    input wire SDI,		// from padframe
    input wire CSB,		// from padframe
    output wire SDO,		// to padframe
    output wire sdo_ena,	// to padframe
    output wire reset,
    input wire [31:0] mask_rev_in,	// metal programmed;  3.3V domain

    output wire [9:0] sram_addr,	// SRAM address
    output wire [7:0] sram_idata,	// data input to SRAM
    input wire [7:0] sram_odata,	// data output from SRAM

    input wire [11:0] io_in,	// from shared digital I/O pads
    output wire [11:0] io_out,	// to shared digital I/O pads
    output wire [11:0] io_oe,	// to shared digital I/O pads

    input wire [23:0] dbus_out,	// shared project digital bus (input to project)
    output wire [11:0] dbus_in,	// shared project digital bus (output from project)

    output wire	[3:0]	proj_sel,	// selected project to enable
    output wire 	proj_ena,	// individual project enables
    output wire 	proj_dig_ena,	// individual project digital bus enable
    output wire 	proj_3v3_ena,	// individual project power gate enable
    output wire 	proj_1v2_ena,	// individual project power gate enable
    output wire	[2:0]	analog_bus_ena,	// individual project analog bus enable

    output reg [4:0] idac1_value,
    output reg [5:0] idac1_control,
    output reg [4:0] idac2_value,
    output reg [5:0] idac2_control,
    output reg [5:0] vbias_control,		// voltage bias output control
    output reg [6:0] bandgap_control		// bandgap enable and trim
);

    wire [7:0] odata;
    wire [7:0] idata;
    wire [7:0] iaddr;
    wire [9:0] addr;
    wire [9:0] seq_sram_addr;
    wire [15:0] seq_out;
    wire [7:0] sram_data;

    wire rdstb;
    wire wrstb;
    wire loc_sdo;

    wire sram_ena;
    wire loop_mode;
    wire seq_ena;

    assign SDO = loc_sdo;

    // Principle chip registers

    reg [2:0] seq_mode;			// Sequencer mode
    reg [1:0] sram_mode;		// SRAM mode
    reg [7:0] clock_prescaler;		// Clock prescaler
    reg [15:0] seq_start;		// Sequencer start value
    reg [15:0] seq_stop;		// Sequencer stop value
    reg [95:0] user_in_route;		// user digital input bus assignments
    reg [47:0] user_out_route;		// user digital output bus assignments 
    reg [111:0] user_config;		// user project configuration

    // Instantiate the SPI interface

    housekeeping_spi spi (
	.reset(~porb),
    	.SCK(SCK),
    	.SDI(SDI),
    	.CSB(CSB),
    	.SDO(loc_sdo),
    	.sdoena(sdo_ena),
    	.idata(odata),
    	.odata(idata),
    	.oaddr(addr),
    	.rdstb(rdstb),
    	.wrstb(wrstb),
	.sram_ena(sram_ena),
	.loop_mode(loop_mode),
	.seq_ena(seq_ena),
	.dig_reset(reset)
    );

    wire [11:0] mfgr_id;
    wire [7:0]  prod_id;
    wire [31:0] mask_rev;

    assign mfgr_id = 12'h567;		// Hard-coded
    assign prod_id = 8'h18;		// Hard-coded
    assign mask_rev = mask_rev_in;	// Copy in to out.

    // Send register contents to odata on SPI read command
    // All values are 1-4 bits and no shadow registers are required.

    assign odata = 
    (sram_ena == 1'b1) ? sram_odata :
    (iaddr == 8'h00) ? 8'h00 :	// SPI status (fixed)
    (iaddr == 8'h01) ? {4'h0, mfgr_id[11:8]} :	// Manufacturer ID (fixed)
    (iaddr == 8'h02) ? mfgr_id[7:0] :	// Manufacturer ID (fixed)
    (iaddr == 8'h03) ? prod_id :	// Product ID (fixed)
    (iaddr == 8'h04) ? mask_rev[31:24] :	// Mask rev (metal programmed)
    (iaddr == 8'h05) ? mask_rev[23:16] :	// Mask rev (metal programmed)
    (iaddr == 8'h06) ? mask_rev[15:8] :		// Mask rev (metal programmed)
    (iaddr == 8'h07) ? mask_rev[7:0] :		// Mask rev (metal programmed)

    (iaddr == 8'h10) ? {5'h00, seq_mode} :
    (iaddr == 8'h11) ? {6'h00, sram_mode} :
    (iaddr == 8'h12) ? clock_prescaler :
    (iaddr == 8'h13) ? seq_start[7:0] :
    (iaddr == 8'h14) ? seq_start[15:8] :
    (iaddr == 8'h15) ? seq_stop[7:0] :
    (iaddr == 8'h16) ? seq_stop[15:8] :
    (iaddr == 8'h17) ? {3'h0, idac1_value} :
    (iaddr == 8'h18) ? {2'h0, idac1_control} :
    (iaddr == 8'h19) ? {3'h0, idac2_value} :
    (iaddr == 8'h1a) ? {2'h0, idac2_control} :
    (iaddr == 8'h1b) ? {2'h0, vbias_control} :
    (iaddr == 8'h1c) ? {1'h0, bandgap_control} :
    (iaddr == 8'h20) ? {4'h0, user_in_route[0*4 +: 4]} :
    (iaddr == 8'h21) ? {4'h0, user_in_route[1*4 +: 4]} :
    (iaddr == 8'h22) ? {4'h0, user_in_route[2*4 +: 4]} :
    (iaddr == 8'h23) ? {4'h0, user_in_route[3*4 +: 4]} :
    (iaddr == 8'h24) ? {4'h0, user_in_route[4*4 +: 4]} :
    (iaddr == 8'h25) ? {4'h0, user_in_route[5*4 +: 4]} :
    (iaddr == 8'h26) ? {4'h0, user_in_route[6*4 +: 4]} :
    (iaddr == 8'h27) ? {4'h0, user_in_route[7*4 +: 4]} :
    (iaddr == 8'h28) ? {4'h0, user_in_route[8*4 +: 4]} :
    (iaddr == 8'h29) ? {4'h0, user_in_route[9*4 +: 4]} :
    (iaddr == 8'h2a) ? {4'h0, user_in_route[10*4 +: 4]} :
    (iaddr == 8'h2b) ? {4'h0, user_in_route[11*4 +: 4]} :
    (iaddr == 8'h2c) ? {4'h0, user_in_route[12*4 +: 4]} :
    (iaddr == 8'h2d) ? {4'h0, user_in_route[13*4 +: 4]} :
    (iaddr == 8'h2e) ? {4'h0, user_in_route[14*4 +: 4]} :
    (iaddr == 8'h2f) ? {4'h0, user_in_route[15*4 +: 4]} :
    (iaddr == 8'h30) ? {4'h0, user_in_route[16*4 +: 4]} :
    (iaddr == 8'h31) ? {4'h0, user_in_route[17*4 +: 4]} :
    (iaddr == 8'h32) ? {4'h0, user_in_route[18*4 +: 4]} :
    (iaddr == 8'h33) ? {4'h0, user_in_route[19*4 +: 4]} :
    (iaddr == 8'h34) ? {4'h0, user_in_route[20*4 +: 4]} :
    (iaddr == 8'h35) ? {4'h0, user_in_route[21*4 +: 4]} :
    (iaddr == 8'h36) ? {4'h0, user_in_route[22*4 +: 4]} :
    (iaddr == 8'h37) ? {4'h0, user_in_route[23*4 +: 4]} :
    (iaddr == 8'h38) ? user_out :
    (iaddr == 8'h40) ? {4'h0, user_out_route[0*4 +: 4]} :
    (iaddr == 8'h41) ? {4'h0, user_out_route[1*4 +: 4]} :
    (iaddr == 8'h42) ? {4'h0, user_out_route[2*4 +: 4]} :
    (iaddr == 8'h43) ? {4'h0, user_out_route[3*4 +: 4]} :
    (iaddr == 8'h44) ? {4'h0, user_out_route[4*4 +: 4]} :
    (iaddr == 8'h45) ? {4'h0, user_out_route[5*4 +: 4]} :
    (iaddr == 8'h46) ? {4'h0, user_out_route[6*4 +: 4]} :
    (iaddr == 8'h47) ? {4'h0, user_out_route[7*4 +: 4]} :
    (iaddr == 8'h48) ? {4'h0, user_out_route[8*4 +: 4]} :
    (iaddr == 8'h49) ? {4'h0, user_out_route[9*4 +: 4]} :
    (iaddr == 8'h4a) ? {4'h0, user_out_route[10*4 +: 4]} :
    (iaddr == 8'h4b) ? {4'h0, user_out_route[11*4 +: 4]} :
    
    (iaddr == 8'h50) ? {4'h0, proj_sel} :
    (iaddr == 8'h51) ? {2'h0, {analog_bus_ena, proj_dig_ena, proj_1v2_ena,
			proj_3v3_ena, proj_ena}} :
               8'h00;	// Default

    // Register mapping and I/O to module

    always @(posedge SCK or negedge porb) begin
    if (porb == 1'b0) begin

    end else if (wrstb == 1'b1 && sram_ena == 1'b0) begin
        case (iaddr)
        8'h10: begin
	     seq_mode <= idata[2:0];
               end
        8'h11: begin
	     sram_mode <= idata[1:0];
               end
	8'h12: begin
	     clock_prescaler <= idata;
	       end
        8'h13: begin
	     seq_start[7:0] <= idata;
               end
        8'h14: begin
	     seq_start[15:8] <= idata;
               end
        8'h15: begin
	     seq_stop[7:0] <= idata;
               end
        8'h16: begin
	     seq_stop[15:8] <= idata;
               end
        8'h17: begin
	     idac1_value <= idata[4:0];
               end
        8'h18: begin
	     idac1_control <= idata[6:0];
               end
        8'h19: begin
	     idac2_value <= idata[4:0];
               end
        8'h1a: begin
	     idac2_control <= idata[6:0];
               end
        8'h1b: begin
	     vbias_control <= idata[6:0];
               end
        8'h1c: begin
	     bandgap_control <= idata[7:0];
               end
        8'h20: begin
	     user_in_route[0*4 +: 4] <= idata[3:0];
	       end
        8'h21: begin
	     user_in_route[1*4 +: 4] <= idata[3:0];
	       end
        8'h22: begin
	     user_in_route[2*4 +: 4] <= idata[3:0];
	       end
        8'h23: begin
	     user_in_route[3*4 +: 4] <= idata[3:0];
	       end
        8'h24: begin
	     user_in_route[4*4 +: 4] <= idata[3:0];
	       end
        8'h25: begin
	     user_in_route[5*4 +: 4] <= idata[3:0];
	       end
        8'h26: begin
	     user_in_route[6*4 +: 4] <= idata[3:0];
	       end
        8'h27: begin
	     user_in_route[7*4 +: 4] <= idata[3:0];
	       end
        8'h28: begin
	     user_in_route[8*4 +: 4] <= idata[3:0];
	       end
        8'h29: begin
	     user_in_route[9*4 +: 4] <= idata[3:0];
	       end
        8'h2a: begin
	     user_in_route[10*4 +: 4] <= idata[3:0];
	       end
        8'h2b: begin
	     user_in_route[11*4 +: 4] <= idata[3:0];
	       end
        8'h2c: begin
	     user_in_route[12*4 +: 4] <= idata[3:0];
	       end
        8'h2d: begin
	     user_in_route[13*4 +: 4] <= idata[3:0];
	       end
        8'h2e: begin
	     user_in_route[14*4 +: 4] <= idata[3:0];
	       end
        8'h2f: begin
	     user_in_route[15*4 +: 4] <= idata[3:0];
	       end
        8'h30: begin
	     user_in_route[16*4 +: 4] <= idata[3:0];
	       end
        8'h31: begin
	     user_in_route[17*4 +: 4] <= idata[3:0];
	       end
        8'h32: begin
	     user_in_route[18*4 +: 4] <= idata[3:0];
	       end
        8'h33: begin
	     user_in_route[19*4 +: 4] <= idata[3:0];
	       end
        8'h34: begin
	     user_in_route[20*4 +: 4] <= idata[3:0];
	       end
        8'h35: begin
	     user_in_route[21*4 +: 4] <= idata[3:0];
	       end
        8'h36: begin
	     user_in_route[22*4 +: 4] <= idata[3:0];
	       end
        8'h37: begin
	     user_in_route[23*4 +: 4] <= idata[3:0];
	       end
        8'h40: begin
	     user_out_route[0*4 +: 4] <= idata[3:0];
	       end
        8'h41: begin
	     user_out_route[1*4 +: 4] <= idata[3:0];
	       end
        8'h42: begin
	     user_out_route[2*4 +: 4] <= idata[3:0];
	       end
        8'h43: begin
	     user_out_route[3*4 +: 4] <= idata[3:0];
	       end
        8'h44: begin
	     user_out_route[4*4 +: 4] <= idata[3:0];
	       end
        8'h45: begin
	     user_out_route[5*4 +: 4] <= idata[3:0];
	       end
        8'h46: begin
	     user_out_route[6*4 +: 4] <= idata[3:0];
	       end
        8'h47: begin
	     user_out_route[7*4 +: 4] <= idata[3:0];
	       end
        8'h48: begin
	     user_out_route[8*4 +: 4] <= idata[3:0];
	       end
        8'h49: begin
	     user_out_route[9*4 +: 4] <= idata[3:0];
	       end
        8'h4a: begin
	     user_out_route[10*4 +: 4] <= idata[3:0];
	       end
        8'h4b: begin
	     user_out_route[11*4 +: 4] <= idata[3:0];
	       end
        8'h50: begin
	     proj_sel <= idata[3:0];
	       end
        8'h51: begin
	     proj_ena <= idata[0];
	     proj_3v3_ena <= idata[1];
	     proj_1v2_ena <= idata[2];
	     proj_dig_ena <= idata[3];
	     analog_bus_ena <= idata[4:5];
	       end
        endcase	// (iaddr)
    end
    end

/* SRAM address */

assign sram_addr = (seq_ena == 1'b1) ? seq_sram_addr : addr;

/* Sequencer */

sequencer sequencer (
    .clk(clk),			// To do:  add prescaler
    .reset(reset),
    .seq_out(seq_out),	
    .seq_mode(seq_mode),
    .loop_mode(loop_mode),
    .sram_addr(seq_sram_addr),
    .sram_data(sram_data)
);

/* Multiplexed digital bus */

router router (
    .io_in(io_in),
    .io_out(io_out),
    .io_oe(io_oe),
    .dbus_in(dbus_in),
    .dbus_out(dbus_out),
    .sram_out(sram_data),
    .seq_out(seq_out),
    .user_in_route(user_in_route),
    .user_out_route(user_out_route)
);

endmodule	// housekeeping

`default_nettype wire
