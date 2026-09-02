/*
 * Module which instantiates all of the digital components of the analog
 * harness chip:  housekeeping, SRAM, and the control blocks for the 18
 * project slots.
 *
 * This module is used for simulating the digital communication and
 * control.
 */

module digital_top (
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
    output wire reset,
    input wire [31:0] mask_rev_in,      // metal programmed;  3.3V domain

    input wire [11:0] io_in,    // from shared digital I/O pads
    output wire [11:0] io_out,  // to shared digital I/O pads
    output wire [11:0] io_oe,   // to shared digital I/O pads

    output wire [23:0] dbus_out, // shared project digital bus (input to project)
    input wire [11:0]  dbus_in,  // shared project digital bus (output from project)

    output wire [4:0] proj_sel,		// selected project slot
    output wire	      proj_ena,		// project enable
    output wire	      proj_dig_ena,	// project shared digital bus enable
    output wire       proj_3v3_ena,	// project 3.3V power gate enable
    output wire       proj_1v2_ena,	// project 1.2V power gate enable
    output wire [1:0] proj_ibias_ena,	// project current bias switches
    output wire       proj_vbias_ena,	// project voltage bias switch
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
    output wire [4:0] voltgen_source             // voltage bias ibias source tuning
);

    wire [9:0] sram_addr;
    wire [7:0] sram_idata;
    wire [7:0] sram_odata;
    wire       sram_read;
    wire       sram_write;
    wire       sram_clk;

    /* Instantiate the housekeeping top module */
    housekeeping_top hk_top (
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
	    .reset(reset),
	    .mask_rev_in(mask_rev_in),
	    .sram_clk(sram_clk),
	    .sram_addr(sram_addr),
	    .sram_idata(sram_idata),
	    .sram_odata(sram_odata),
	    .sram_read(sram_read),
	    .sram_write(sram_write),
	    .io_in(io_in),
	    .io_out(io_out),
	    .io_oe(io_oe),
	    .dbus_out(dbus_out),
	    .dbus_in(dbus_in),
	    .proj_sel(proj_sel),
	    .proj_ena(proj_ena),
	    .proj_dig_ena(proj_dig_ena),
	    .proj_3v3_ena(proj_3v3_ena),
	    .proj_1v2_ena(proj_1v2_ena),
	    .proj_ibias_ena(proj_ibias_ena),
	    .proj_vbias_ena(proj_vbias_ena),
	    .analog_bus_ena(analog_bus_ena),
	    .idac1_value(idac1_value),
	    .idac2_value(idac2_value),
            .voltgen_ena(voltgen_ena),
            .voltgen_high(voltgen_high),
            .voltgen_value(voltgen_value),
            .bandgap_ena(bandgap_ena),
            .bandgap_trim(bandgap_trim),
            .biasgen_ena(biasgen_ena),
            .biasgen_coarse(biasgen_coarse),
            .biasgen_fine(biasgen_fine),
            .biasgen_ref_vbg(biasgen_ref_vbg),
            .bandgap_sink1(bandgap_sink1),
            .bandgap_sink2(bandgap_sink2),
            .voltgen_sink1(voltgen_sink1),
            .voltgen_sink2(voltgen_sink2),
            .voltgen_source(voltgen_source)
    );

    /* Instantiate the SRAM */

    RM_IHPSG13_1P_1024x8_c2_bm_bist sram (
	.A_CLK(sram_clk),
	.A_MEN(porb),
	.A_WEN(sram_write),	// write enable
	.A_REN(sram_read),	// read enable
	.A_ADDR(sram_addr),
	.A_DIN(sram_idata),
	.A_DLY(1'b1),		// set to 1 per documentation recommendation
	.A_DOUT(sram_odata),
	.A_BM(8'hff),		// bit mask (all bits used)
	.A_BIST_CLK(1'b0),	// not using BIST
	.A_BIST_EN(1'b0),
	.A_BIST_MEN(1'b0),
	.A_BIST_WEN(1'b0),
	.A_BIST_REN(1'b0),
	.A_BIST_ADDR(10'h000),
	.A_BIST_DIN(8'h00),
	.A_BIST_BM(8'h00)
    );

    /* Signals between project control and project wrapper (18 instances) */

    wire [17:0] user_clk;
    wire [17:0] user_ena;
    wire [17:0] user_3v3_ena;
    wire [17:0] user_1v2_ena;
    wire [71:0] user_analog_ena;	// 4 bits
    wire [35:0] user_ibias_ena;		// 2 bits
    wire [17:0] user_vbias_ena;
    wire [431:0] user_dig_in;		// 24 bits
    wire [215:0] user_dig_out;		// 12 bits

    /* Instantiate 18 project control blocks */
    /* NOTE: Project zero is diagnostic;  user projects are numbered 1 to 18 */

    genvar i;

    generate
	for (i = 0; i < 18; i = i + 1) begin
	    wire [4:0] bit_index;
            assign bit_index = i + 1; // Implicitly truncate
		user_project_control ctrl (
		    .proj_addr(bit_index),
		    .proj_sel(proj_sel),
		    .clk(clk),
		    .dig_ena(proj_dig_ena),
	  	    .enable(proj_ena),
		    .analog_ena(analog_bus_ena),
		    .ibias_ena(proj_ibias_ena),
		    .vbias_ena(proj_vbias_ena),
		    .power_3v3_ena(proj_3v3_ena),
		    .power_1v2_ena(proj_1v2_ena),
		    .dig_in(dbus_out),
		    .dig_out(dbus_in),

		    // These signals connect to the user project harness
		    .proj_clk(user_clk[i]),
		    .proj_ena(user_ena[i]),
		    .proj_3v3_ena(user_3v3_ena[i]),
		    .proj_1v2_ena(user_1v2_ena[i]),
		    .proj_analog_ena(user_analog_ena[i*4 +: 4]), // 4 bits
		    .proj_ibias_ena(user_ibias_ena[i*2 +: 2]),   // 2 bits
		    .proj_vbias_ena(user_vbias_ena[i]),
		    .proj_dig_in(user_dig_in[i*24 +: 24]),	 // 24 bits
		    .proj_dig_out(user_dig_out[i*12 +: 12])	 // 12 bits
		);
	end
    endgenerate

endmodule
