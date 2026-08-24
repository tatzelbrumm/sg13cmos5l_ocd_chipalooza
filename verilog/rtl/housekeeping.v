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
// Register 0x17-0x18:	pattern generator stop value
// Register 0x19:	iDAC1 value
// Register 0x1A:	iDAC1 control
// Register 0x1B:	iDAC2 value
// Register 0x1C:	iDAC2 control
// Register 0x1D:	voltage bias control
// Register 0x1E:	bandgap control
// Register 0x20-0x37:	user project digital input routing
// Register 0x38:	user project digital output (sampled)
// Register 0x40-0x47:	user project digital output routing
// Register 0x50-0x62:	user project configuration
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

    output wire	sram_clk,		// SRAM clock
    output wire [9:0] sram_addr,	// SRAM address
    output wire [7:0] sram_idata,	// data input to SRAM
    input wire [7:0] sram_odata,	// data output from SRAM
    output wire	sram_read,		// SRAM read enable
    output wire	sram_write,		// SRAM write enable

    input wire [11:0] io_in,	// from shared digital I/O pads
    output wire [11:0] io_out,	// to shared digital I/O pads
    output wire [11:0] io_oe,	// to shared digital I/O pads

    output wire [23:0] dbus_out,	// shared project digital bus (input to project)
    input wire [11:0] dbus_in,		// shared project digital bus (output from project)

    output reg	[4:0]	proj_sel,	// selected project to enable
    output reg 		proj_ena,	// individual project enables
    output reg 		proj_dig_ena,	// individual project digital bus enable
    output reg 		proj_3v3_ena,	// individual project power gate enable
    output reg 		proj_1v2_ena,	// individual project power gate enable
    output reg	[3:0]	analog_bus_ena,	// individual project analog bus enable

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
    wire [9:0] pat_sram_addr;
    wire [7:0] pat_sram_data;
    wire [15:0] seq_out;

    wire rdstb;
    wire wrstb;
    wire loc_sdo;
    wire loc_reset;

    wire sram_ena;
    wire clk_scaled;

    reg seq_ena;
    reg loop_mode;
    wire seq_trig;
    wire pat_trig;


    wire seq_strobe;
    wire [1:0] seq_cmd;		// loop, single-shot, stop

    assign SDO = loc_sdo;
    assign loc_reset = ~porb | reset;

    // Principle chip registers

    reg [2:0] seq_mode;			// Sequencer mode
    reg [1:0] sram_mode;		// SRAM mode
    reg [7:0] seq_prescaler;		// Clock prescaler for sequencer
    reg [7:0] pat_prescaler;		// Clock prescaler for pattern generator
    reg [15:0] seq_start;		// Sequencer start value
    reg [15:0] seq_stop;		// Sequencer stop value
    reg [9:0]  pat_stop;		// Pattern generator stop value
    reg [95:0] user_in_route;		// user digital input bus assignments
    reg [47:0] user_out_route;		// user digital output bus assignments 
    reg [7:0] sram_monitor;		// monitor SRAM on digital out [7:0]
    reg [1:0] strobe_monitor;		// monitor strobes on digital out [9:8]

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
	.seq_strobe(seq_strobe),
	.seq_mode(seq_cmd),
	.dig_reset(reset)
    );

    wire [11:0] mfgr_id;
    wire [7:0]  prod_id;
    wire [31:0] mask_rev;

    assign mfgr_id = 12'h567;		// Hard-coded
    assign prod_id = 8'h18;		// Hard-coded
    assign mask_rev = mask_rev_in;	// Copy in to out.

    assign iaddr = addr[7:0];		// Register address space is the low
					// 8 address bits only (SRAM gets
					// all 10 bits).

    // Drive sequencer from SPI commands.  The SPI commands reset when CSB
    // is raised, so housekeeping_spi can only produce a strobe that needs
    // to be detected here, so that the sequencer can remain active after
    // the SPI transmission stops.

    always @(posedge seq_strobe or posedge loc_reset) begin
	if (loc_reset) begin
	    seq_ena <= 1'b0;
	    loop_mode <= 1'b0;
	end else begin
	    case (seq_cmd)
		2'b00: begin
		    seq_ena <= 1'b1;
		    loop_mode <= 1'b1;
		    end
		2'b01: begin
		    seq_ena <= 1'b1;
		    loop_mode <= 1'b0;
		    end
		default: begin
		    seq_ena <= 1'b0;
		    end
	    endcase
	end
    end

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
    (iaddr == 8'h12) ? seq_prescaler :
    (iaddr == 8'h13) ? pat_prescaler :
    (iaddr == 8'h14) ? seq_start[7:0] :
    (iaddr == 8'h15) ? seq_start[15:8] :
    (iaddr == 8'h16) ? seq_stop[7:0] :
    (iaddr == 8'h17) ? seq_stop[15:8] :
    (iaddr == 8'h18) ? pat_stop[7:0] :
    (iaddr == 8'h19) ? {6'h00, pat_stop[9:8]} :
    (iaddr == 8'h1a) ? {3'h0, idac1_value} :
    (iaddr == 8'h1b) ? {2'h0, idac1_control} :
    (iaddr == 8'h1c) ? {3'h0, idac2_value} :
    (iaddr == 8'h1d) ? {2'h0, idac2_control} :
    (iaddr == 8'h1e) ? {2'h0, vbias_control} :
    (iaddr == 8'h1f) ? {1'h0, bandgap_control} :
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
    (iaddr == 8'h38) ? dbus_in :
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
    (iaddr == 8'h4c) ? sram_monitor :
    (iaddr == 8'h4d) ? {6'h00, strobe_monitor} :
    
    (iaddr == 8'h50) ? {3'h0, proj_sel} :
    (iaddr == 8'h51) ? {analog_bus_ena, proj_dig_ena, proj_1v2_ena,
			proj_3v3_ena, proj_ena} :
               8'h00;	// Default

    // Register mapping and I/O to module

    always @(posedge SCK or negedge porb) begin
    if (porb == 1'b0) begin
	// Default values on reset
	seq_mode <= 3'b101;	// Set all sequencer bits to zero
	sram_mode <= 2'b00;	// Increment SRAM address at clock rate
	seq_prescaler <= 8'h07;	// Clock prescaler for sequencer = 7 (x8)
	pat_prescaler <= 8'h07;	// Clock prescaler for pattern generator = 7 (x8)
	seq_start <= 16'h0000;	// Sequencer starts at count 0
	seq_stop <= 16'h00ff;	// Sequencer ends at count 255
	pat_stop <= 16'h03ff;	// Pattern generator ends at addr 1023
	idac1_value <= 5'h00;	// iDAC current value = 0
	idac1_control <= 7'h00;	// (TBD)
	idac2_value <= 5'h00;	// iDAC current value = 0
	idac2_control <= 7'h00;	// (TBD)
	user_in_route <= 96'd0;	// (See router.v)
	user_out_route <= 48'd0; // (See router.v)
	proj_sel <= 5'h00;	// Diagnostic project selected
	proj_ena <= 1'b0;	// Project disabled
	proj_dig_ena <= 1'b0;	// Project digital I/O disabled
	proj_3v3_ena <= 1'b0;	// Project 3.3V power switch disabled
	proj_1v2_ena <= 1'b0;	// Project 1.2V power switch disabled
	analog_bus_ena <= 4'h0;	// Analog switches disabled
	sram_monitor <= 8'h00;	// SRAM monitoring disabled
	strobe_monitor <= 2'b00; // Strobe monitoring disabled.

    end else if ((wrstb == 1'b1) && (sram_ena == 1'b0)) begin
        case (iaddr)
        8'h10: begin
	     seq_mode <= idata[2:0];
               end
        8'h11: begin
	     sram_mode <= idata[1:0];
               end
	8'h12: begin
	     seq_prescaler <= idata;
	       end
	8'h13: begin
	     pat_prescaler <= idata;
	       end
        8'h14: begin
	     seq_start[7:0] <= idata;
               end
        8'h15: begin
	     seq_start[15:8] <= idata;
               end
        8'h16: begin
	     seq_stop[7:0] <= idata;
               end
        8'h17: begin
	     seq_stop[15:8] <= idata;
               end
        8'h18: begin
	     pat_stop[7:0] <= idata;
               end
        8'h19: begin
	     pat_stop[9:8] <= idata[1:0];
               end
        8'h1a: begin
	     idac1_value <= idata[4:0];
               end
        8'h1b: begin
	     idac1_control <= idata[6:0];
               end
        8'h1c: begin
	     idac2_value <= idata[4:0];
               end
        8'h1d: begin
	     idac2_control <= idata[6:0];
               end
        8'h1e: begin
	     vbias_control <= idata[6:0];
               end
        8'h1f: begin
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
	8'h4c: begin
	     sram_monitor <= idata;
	       end
	8'h4d: begin
	     strobe_monitor <= idata[1:0];
	       end
        8'h50: begin
	     proj_sel <= idata[4:0];
	       end
        8'h51: begin
	     proj_ena <= idata[0];
	     proj_3v3_ena <= idata[1];
	     proj_1v2_ena <= idata[2];
	     proj_dig_ena <= idata[3];
	     analog_bus_ena <= idata[7:4];
	       end
        endcase	// (iaddr)
    end
end

/* SRAM address */

assign sram_addr = (seq_ena == 1'b1) ? pat_sram_addr : addr;
assign sram_read = seq_ena | (sram_ena & rdstb);
assign sram_write = sram_ena & wrstb;
assign sram_idata = {8{sram_ena}} & idata;

/* Warning: gated clock.  Allows the SRAM to be accessed via the
 * SPI on the SPI's clock.
 */
assign sram_clk = (seq_ena == 1'b1) ? clk : SCK;

/* Sequencer */
sequencer sequencer (
    .clk(clk),
    .reset(loc_reset),
    .sync_reset(~seq_ena),
    .prescaler(seq_prescaler),
    .seq_out(seq_out),	
    .seq_mode(seq_mode),
    .seq_start(seq_start),
    .seq_stop(seq_stop),
    .loop_mode(loop_mode),
    .strobe_in(pat_trig),
    .strobe_out(seq_trig)
);

/* Arbitrary pattern generator */
pattern pattern (
    .clk(clk),
    .reset(loc_reset),
    .sync_reset(~seq_ena),
    .prescaler(pat_prescaler),
    .sram_mode(sram_mode),
    .sram_stop_addr(pat_stop),
    .sram_addr(pat_sram_addr),
    .sram_data_in(sram_odata),
    .sram_data_out(pat_sram_data),
    .loop_mode(loop_mode),
    .strobe_in(seq_trig),
    .strobe_out(pat_trig)
);

/* Multiplexed digital bus */

router router (
    .io_in(io_in),
    .io_out(io_out),
    .io_oe(io_oe),
    .dbus_in(dbus_in),
    .dbus_out(dbus_out),
    .sram_out(pat_sram_data),
    .seq_out(seq_out),
    .strobe_out({seq_trig, pat_trig}),
    .user_in_route(user_in_route),
    .user_out_route(user_out_route),
    .sram_monitor(sram_monitor),
    .strobe_monitor(strobe_monitor)
);

endmodule	// housekeeping

`default_nettype wire
