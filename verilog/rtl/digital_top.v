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
    output wire [3:0] analog_bus_ena,	// project analog bus enable

    output wire [4:0] idac1_value,
    output wire [5:0] idac1_control,
    output wire [4:0] idac2_value,
    output wire [5:0] idac2_control,
    output wire [5:0] vbias_control,             // voltage bias output control
    output wire [6:0] bandgap_control            // bandgap enable and trim
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
	    .analog_bus_ena(analog_bus_ena),
	    .idac1_value(idac1_value),
	    .idac1_control(idac1_control),
	    .idac2_value(idac2_value),
	    .idac2_control(idac2_control),
	    .vbias_control(vbias_control),
	    .bandgap_control(bandgap_control)
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
		user_project_control #(
		    .PROJ_ADDRESS(i + 1)
		) ctrl (
		    .proj_sel(proj_sel),
		    .clk(clk),
		    .dig_ena(proj_dig_ena),
	  	    .enable(proj_ena),
		    .analog_ena(analog_bus_ena),
		    .ibias_ena({idac2_control[0], idac1_control[0]}),
		    .vbias_ena(vbias_control[0]),
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
