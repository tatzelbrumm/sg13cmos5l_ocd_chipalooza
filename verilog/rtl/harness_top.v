/*
 * Module which instantiates all of the main components of the analog
 * harness chip:  housekeeping, SRAM, and 18 project slots with control.
 */

module harness_top (
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

    output wire [9:0] sram_addr,        // SRAM address
    output wire [7:0] sram_idata,       // data input to SRAM
    input wire [7:0] sram_odata,        // data output from SRAM

    input wire [11:0] io_in,    // from shared digital I/O pads
    output wire [11:0] io_out,  // to shared digital I/O pads
    output wire [11:0] io_oe,   // to shared digital I/O pads

    input wire [23:0] dbus_out, // shared project digital bus (input to project)
    output wire [11:0] dbus_in,  // shared project digital bus (output from project)

    output wire [5:0] proj_sel,		// selected project slot
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
	    .sram_addr(sram_addr),
	    .sram_idata(sram_idata),
	    .sram_odata(sram_odata),
	    .io_in(io_in),
	    .io_out(io_out_buf),
	    .io_oe(io_oe_buf),
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
		)
	    
	end
    endgenerate

    /* Instantiate user project wrappers.  These are not done by "generate"
     * because the number of dedicated pins, and therefore the name of the
     * module used, depends on position (see documentation).
     */

    # Project slot 1 (4 analog pins)
    user_project_wrapper_4a slot_1 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[0]),
	.clk(user_clk[0]),
	.dig_in(user_dig_in[0*24 +: 24]),
	.dig_out(user_dig_out[0*12 +: 12]),
	.analog_pin(s1_an),			// to padframe, 4 bits
	.ibias(proj_ibias[0*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[0])			// post-switch, 1 bit
    );

    # Project slot 2 (1 analog pin)
    user_project_wrapper_1a slot_2 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[1]),
	.clk(user_clk[1]),
	.dig_in(user_dig_in[1*24 +: 24]),
	.dig_out(user_dig_out[1*12 +: 12]),
	.analog_pin(s2_an),			// to padframe, 4 bits
	.ibias(proj_ibias[1*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[1])			// post-switch, 1 bit
    );

    # Project slot 3 (2 analog pins)
    user_project_wrapper_2a slot_3 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[2]),
	.clk(user_clk[2]),
	.dig_in(user_dig_in[2*24 +: 24]),
	.dig_out(user_dig_out[2*12 +: 12]),
	.analog_pin(s3_an),			// to padframe, 4 bits
	.ibias(proj_ibias[2*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[2])			// post-switch, 1 bit
    );

    # Project slot 4 (3 analog pins)
    user_project_wrapper_3a slot_4 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[3]),
	.clk(user_clk[3]),
	.dig_in(user_dig_in[3*24 +: 24]),
	.dig_out(user_dig_out[3*12 +: 12]),
	.analog_pin(s4_an),			// to padframe, 4 bits
	.ibias(proj_ibias[3*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[3])			// post-switch, 1 bit
    );

    # Project slot 5 (2 analog pins)
    user_project_wrapper_2a slot_5 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[4]),
	.clk(user_clk[4]),
	.dig_in(user_dig_in[4*24 +: 24]),
	.dig_out(user_dig_out[4*12 +: 12]),
	.analog_pin(s5_an),			// to padframe, 4 bits
	.ibias(proj_ibias[4*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[4])			// post-switch, 1 bit
    );

    # Project slot 6 (1 analog pin)
    user_project_wrapper_1a slot_6 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[5]),
	.clk(user_clk[5]),
	.dig_in(user_dig_in[5*24 +: 24]),
	.dig_out(user_dig_out[5*12 +: 12]),
	.analog_pin(s6_an),			// to padframe, 4 bits
	.ibias(proj_ibias[5*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[5])			// post-switch, 1 bit
    );

    # Project slot 7 (2 analog pins)
    user_project_wrapper_2a slot_7 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[6]),
	.clk(user_clk[6]),
	.dig_in(user_dig_in[6*24 +: 24]),
	.dig_out(user_dig_out[6*12 +: 12]),
	.analog_pin(s7_an),			// to padframe, 4 bits
	.ibias(proj_ibias[6*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[6])			// post-switch, 1 bit
    );

    # Project slot 8 (3 analog pins)
    user_project_wrapper_3a slot_8 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[7]),
	.clk(user_clk[7]),
	.dig_in(user_dig_in[7*24 +: 24]),
	.dig_out(user_dig_out[7*12 +: 12]),
	.analog_pin(s8_an),			// to padframe, 4 bits
	.ibias(proj_ibias[7*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[7])			// post-switch, 1 bit
    );

    # Project slot 9 (3 analog pins)
    user_project_wrapper_3a slot_9 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[8]),
	.clk(user_clk[8]),
	.dig_in(user_dig_in[8*24 +: 24]),
	.dig_out(user_dig_out[8*12 +: 12]),
	.analog_pin(s9_an),			// to padframe, 4 bits
	.ibias(proj_ibias[8*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[8])			// post-switch, 1 bit
    );

    # Project slot 10 (2 analog pins)
    user_project_wrapper_2a slot_10 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[9]),
	.clk(user_clk[9]),
	.dig_in(user_dig_in[9*24 +: 24]),
	.dig_out(user_dig_out[9*12 +: 12]),
	.analog_pin(s10_an),			// to padframe, 4 bits
	.ibias(proj_ibias[9*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[9])			// post-switch, 1 bit
    );

    # Project slot 11 (1 analog pin)
    user_project_wrapper_1a slot_11 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[10]),
	.clk(user_clk[10]),
	.dig_in(user_dig_in[10*24 +: 24]),
	.dig_out(user_dig_out[10*12 +: 12]),
	.analog_pin(s11_an),			// to padframe, 4 bits
	.ibias(proj_ibias[10*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[10])			// post-switch, 1 bit
    );

    # Project slot 12 (2 analog pins)
    user_project_wrapper_2a slot_12 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[11]),
	.clk(user_clk[11]),
	.dig_in(user_dig_in[11*24 +: 24]),
	.dig_out(user_dig_out[11*12 +: 12]),
	.analog_pin(s12_an),			// to padframe, 4 bits
	.ibias(proj_ibias[11*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[11])			// post-switch, 1 bit
    );

    # Project slot 13 (3 analog pins)
    user_project_wrapper_3a slot_13 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[12]),
	.clk(user_clk[12]),
	.dig_in(user_dig_in[12*24 +: 24]),
	.dig_out(user_dig_out[12*12 +: 12]),
	.analog_pin(s13_an),			// to padframe, 4 bits
	.ibias(proj_ibias[12*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[12])			// post-switch, 1 bit
    );

    # Project slot 14 (2 analog pins)
    user_project_wrapper_2a slot_14 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[13]),
	.clk(user_clk[13]),
	.dig_in(user_dig_in[13*24 +: 24]),
	.dig_out(user_dig_out[13*12 +: 12]),
	.analog_pin(s14_an),			// to padframe, 4 bits
	.ibias(proj_ibias[13*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[13])			// post-switch, 1 bit
    );

    # Project slot 15 (1 analog pin)
    user_project_wrapper_1a slot_15 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[14]),
	.clk(user_clk[14]),
	.dig_in(user_dig_in[14*24 +: 24]),
	.dig_out(user_dig_out[14*12 +: 12]),
	.analog_pin(s15_an),			// to padframe, 4 bits
	.ibias(proj_ibias[14*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[14])			// post-switch, 1 bit
    );

    # Project slot 16 (4 analog pins)
    user_project_wrapper_4a slot_16 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[15]),
	.clk(user_clk[15]),
	.dig_in(user_dig_in[15*24 +: 24]),
	.dig_out(user_dig_out[15*12 +: 12]),
	.analog_pin(s16_an),			// to padframe, 4 bits
	.ibias(proj_ibias[15*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[15])			// post-switch, 1 bit
    );

    # Project slot 17 (no analog pins)
    user_project_wrapper_0a slot_17 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[16]),
	.clk(user_clk[16]),
	.dig_in(user_dig_in[16*24 +: 24]),
	.dig_out(user_dig_out[16*12 +: 12]),
	.ibias(proj_ibias[16*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[16])			// post-switch, 1 bit
    );

    # Project slot 18 (no analog pins)
    user_project_wrapper_0a slot_18 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(vdd_3v3),
	    .vdd_1v2(vdd_1v2),
	    .vss_3v3(vss_3v3),
	    .vss_1v2(vss_1v2),
	    .vssio(vssio),
	`endif
	.enable(user_ena[17]),
	.clk(user_clk[17]),
	.dig_in(user_dig_in[17*24 +: 24]),
	.dig_out(user_dig_out[17*12 +: 12]),
	.ibias(proj_ibias[17*2 +: 2]),		// post-switches, 2 bits
	.vbias(vbias[17])			// post-switch, 1 bit
    );

    # Project slot 0 (special, diagnostic)
    # (TBD)

endmodule
