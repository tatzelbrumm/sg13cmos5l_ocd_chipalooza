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

/*
 * Module which instantiates the housekeeping unit along with
 * antenna tie-downs on all inputs and buffers on all outputs.
 */

module housekeeping_top (
`ifdef USE_POWER_PINS
    inout VPWR,     // 1.8V supply
    inout VGND,     // common ground
`endif
  
    input wire porb,
    input wire clk,
    input wire SCK,      // from padframe
    input wire SDI,      // from padframe
    input wire CSB,      // from padframe
    output wire SDO,     // to padframe
    output wire sdo_ena, // to padframe
    output wire reset,			// reset to user projects
    output wire clk_out,		// buffered clock to user projects
    input wire [31:0] mask_rev_in,      // metal programmed;  3.3V domain

    output wire sram_clk,		// SRAM clock
    output wire [9:0] sram_addr,	// SRAM address
    output wire [7:0] sram_idata,	// data input to SRAM
    input  wire [7:0] sram_odata,	// data output from SRAM
    output wire sram_read,		// SRAM read enable
    output wire sram_write,		// SRAM write enable

    input wire [11:0] io_in,    // from shared digital I/O pads
    output wire [11:0] io_out,  // to shared digital I/O pads
    output wire [11:0] io_oe,   // to shared digital I/O pads

    output wire [23:0] dbus_out,	// shared project digital bus (input to project)
    input wire [11:0] dbus_in_left,	// shared project digital bus (output from
					// left side projects)
    input wire [11:0] dbus_in_right,	// shared project digital bus (output from
					// right side projects)

    output wire [4:0] proj_sel,		// selected project slot
    output wire	      proj_ena,		// project enable
    output wire	      proj_dig_ena,	// project shared digital bus enable
    output wire       proj_3v3_ena,	// project 3.3V power gate enable
    output wire       proj_1v2_ena,	// project 1.2V power gate enable
    output wire	[1:0] proj_ibias_ena,	// project current bias switches
    output wire	      proj_vbias_ena,	// project voltage bias switch
    output wire [3:0] analog_bus_ena,	// project analog bus enable

    output wire [4:0] idac1_value,
    output wire [4:0] idac2_value,
    output wire [2:0] voltgen_ena,               // voltage bias enables
    output wire voltgen_high,                    // voltage bias high trim
    output wire [2:0] voltgen_value,             // voltage bias value
    output wire bandgap_ena,                     // bandgap enable
    output wire [15:0] bandgap_trim,             // bandgap trim (thermometer code)
    output wire biasgen_ena,                     // biasgen enable
    output wire biasgen_coarse,                  // biasgen coarse/fine control
    output wire biasgen_fine,                    // biasgen coarse/fine control
    output wire biasgen_ref_vbg,                 // biasgen bandgap-stabilize
    output wire [2:0] bandgap_sink1,             // bandgap ibias 1 sink tuning
    output wire [1:0] bandgap_sink2,             // bandgap ibias 2 sink tuning
    output wire [2:0] voltgen_sink1,             // voltage bias ibias 1 sink tuning
    output wire [2:0] voltgen_sink2,             // voltage bias ibias 2 sink tuning
    output wire [4:0] voltgen_source,            // voltage bias ibias source tuning
    output wire project_zero			 // diagnostic project selected
);

    wire [23:0] dbus_out_unbuf;
    wire [11:0] io_out_unbuf;
    wire [11:0] io_oe_unbuf;
    wire [4:0] idac1_value_unbuf;
    wire [4:0] idac2_value_unbuf;
    wire [2:0] voltgen_ena_unbuf;
    wire voltgen_high_unbuf;
    wire [2:0] voltgen_value_unbuf;
    wire bandgap_ena_unbuf;
    wire clk_out_unbuf;
    wire [15:0] bandgap_trim_unbuf;
    wire biasgen_ena_unbuf;
    wire biasgen_coarse_unbuf;
    wire biasgen_fine_unbuf;
    wire biasgen_ref_vbg_unbuf;
    wire [2:0] bandgap_sink1_unbuf;
    wire [1:0] bandgap_sink2_unbuf;
    wire [2:0] voltgen_sink1_unbuf;
    wire [2:0] voltgen_sink2_unbuf;
    wire [4:0] voltgen_source_unbuf;
    wire [4:0] proj_sel_unbuf;
    wire proj_ena_unbuf;
    wire proj_dig_ena_unbuf;
    wire proj_3v3_ena_unbuf;
    wire proj_1v2_ena_unbuf;
    wire [1:0] proj_ibias_ena_unbuf;
    wire proj_vbias_ena_unbuf;
    wire [3:0] analog_bus_ena_unbuf;
    wire reset_unbuf;
    wire project_zero_unbuf;
    wire seq_ena;

    // NOTE:  IHP verilog for the standard cells does not have power and ground

    /* Instantiate antenna tie-downs on all input pins */
    (* keep *)
    sg13cmos5l_antennanp tiedowns [80:0] (
	// no. signals = 1 + 1 + 1 + 1 + 1 + 32 + 12 + 12 + 12 + 8 = 81
	.A({porb, clk, SCK, SDI, CSB, mask_rev_in, dbus_in_right, dbus_in_left,
		io_in, sram_odata})
    );
    
    /* Instantiate buffers on all potentially long-distance outputs */
    (* keep *)
    sg13cmos5l_buf_16 outbuffers [120:0] (
	// no. signals: 24, 12, 12, 5, 5, 3, 1, 3, 1, 16, 1, 1, 1, 1, 3,
	//		2, 3, 3, 5, 1, 5, 1, 1, 1, 1, 2, 1, 4, 1, 1 = 121
	.A({dbus_out_unbuf, io_out_unbuf, io_oe_unbuf, idac1_value_unbuf,
		idac2_value_unbuf, voltgen_ena_unbuf, voltgen_high_unbuf,
		voltgen_value_unbuf, bandgap_ena_unbuf, bandgap_trim_unbuf,
		biasgen_ena_unbuf, biasgen_coarse_unbuf, biasgen_fine_unbuf,
		biasgen_ref_vbg_unbuf, bandgap_sink1_unbuf, bandgap_sink2_unbuf,
		voltgen_sink1_unbuf, voltgen_sink2_unbuf, voltgen_source_unbuf,
		clk_out_unbuf, proj_sel_unbuf, proj_ena_unbuf, proj_dig_ena_unbuf,
		proj_3v3_ena_unbuf, proj_1v2_ena_unbuf, proj_ibias_ena_unbuf,
		proj_vbias_ena_unbuf, analog_bus_ena_unbuf, reset_unbuf,
		project_zero_unbuf}),
	.X({dbus_out, io_out, io_oe, idac1_value, idac2_value, voltgen_ena,
		voltgen_high, voltgen_value, bandgap_ena, bandgap_trim,
		biasgen_ena, biasgen_coarse, biasgen_fine, biasgen_ref_vbg,
		bandgap_sink1, bandgap_sink2, voltgen_sink1, voltgen_sink2,
		voltgen_source, clk_out, proj_sel, proj_ena, proj_dig_ena,
		proj_3v3_ena, proj_1v2_ena, proj_ibias_ena, proj_vbias_ena,
		analog_bus_ena, reset, project_zero})
    );

    /* Vectors as seen by the SRAM, which in this version of the housekeeping
     * top module has 1024 words and 8 bits data.
     */

    /* SRAM clock mux.
     *
     * sram_clk = seq_ena ? clk : SCK.  Instantiated as a single mux cell
     * with (* keep *) so that it stays one recognisable instance:  the
     * SDC declares two generated clocks on this port, one from each
     * source, and marks them logically exclusive.  The SRAM is 18 um
     * away, so this drives ~10 fF and needs no separate buffer.
     *
     * NOTE:  the mux can still glitch if seq_ena changes while clk is
     * high and SCK is low.  seq_ena only changes on an SPI command, and
     * the documented rule is that the SRAM is not accessed while the
     * sequencer runs, so no write can be in flight when it moves.
     */
    (* keep *)
    sg13cmos5l_mux2_1 sram_clk_mux (
	.A0(SCK),
	.A1(clk),
	.S(seq_ena),
	.X(sram_clk)
    );

    /* Instantiate the housekeeping module */
    housekeeping hk (
	`ifdef USE_POWER_PINS
	    .VPWR(VPWR),
	    .VGND(VGND),
	`endif
	    .porb(porb),
	    .clk(clk),
	    .SCK(SCK),
	    .SDI(SDI),
	    .CSB(CSB),
	    .SDO(SDO),
	    .sdo_ena(sdo_ena),
	    .reset(reset_unbuf),
	    .clk_out(clk_out_unbuf),
	    .mask_rev_in(mask_rev_in),
	    .seq_ena_out(seq_ena),
	    .sram_addr(sram_addr),
	    .sram_idata(sram_idata),
	    .sram_odata(sram_odata),
	    .sram_read(sram_read),
	    .sram_write(sram_write),
	    .io_in(io_in),
	    .io_out(io_out_unbuf),
	    .io_oe(io_oe_unbuf),
	    .dbus_out(dbus_out_unbuf),
	    .dbus_in_left(dbus_in_left),
	    .dbus_in_right(dbus_in_right),
	    .proj_sel(proj_sel_unbuf),
	    .proj_ena(proj_ena_unbuf),
	    .proj_dig_ena(proj_dig_ena_unbuf),
	    .proj_3v3_ena(proj_3v3_ena_unbuf),
	    .proj_1v2_ena(proj_1v2_ena_unbuf),
	    .proj_ibias_ena(proj_ibias_ena_unbuf),
	    .proj_vbias_ena(proj_vbias_ena_unbuf),
	    .analog_bus_ena(analog_bus_ena_unbuf),
	    .idac1_value(idac1_value_unbuf),
	    .idac2_value(idac2_value_unbuf),
	    .voltgen_ena(voltgen_ena_unbuf),
	    .voltgen_high(voltgen_high_unbuf),
	    .voltgen_value(voltgen_value_unbuf),
	    .bandgap_ena(bandgap_ena_unbuf),
	    .bandgap_trim(bandgap_trim_unbuf),
	    .biasgen_ena(biasgen_ena_unbuf),
	    .biasgen_coarse(biasgen_coarse_unbuf),
	    .biasgen_fine(biasgen_fine_unbuf),
	    .biasgen_ref_vbg(biasgen_ref_vbg_unbuf),
	    .bandgap_sink1(bandgap_sink1_unbuf),
	    .bandgap_sink2(bandgap_sink2_unbuf),
	    .voltgen_sink1(voltgen_sink1_unbuf),
	    .voltgen_sink2(voltgen_sink2_unbuf),
	    .voltgen_source(voltgen_source_unbuf),
	    .project_zero(project_zero_unbuf)
    );

endmodule
