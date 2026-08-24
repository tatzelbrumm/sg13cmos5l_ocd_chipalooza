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

    output wire [3:0] proj_sel,		// selected project slot
    output wire	      proj_ena,		// project enable
    output wire	      proj_dig_ena,	// project shared digital bus enable
    output wire       proj_3v3_ena,	// project 3.3V power gate enable
    output wire       proj_1v2_ena,	// project 1.2V power gate enable
    output wire [2:0] analog_bus_ena,	// project analog bus enable

    output wire [4:0] idac1_value,
    output wire [5:0] idac1_control,
    output wire [4:0] idac2_value,
    output wire [5:0] idac2_control,
    output wire [5:0] vbias_control,             // voltage bias output control
    output wire [6:0] bandgap_control            // bandgap enable and trim
);

    wire [23:0] dbus_out_buf;
    wire [11:0] io_out_buf;
    wire [4:0] idac1_value_buf;
    wire [5:0] idac1_control_buf;
    wire [4:0] idac2_value_buf;
    wire [5:0] idac2_control_buf;
    wire [5:0] vbias_control_buf;
    wire [6:0] bandgap_control_buf;

    // NOTE:  IHP verilog for the standard cells does not have power and ground

    /* Instantiate antenna tie-downs on all input pins */
    (* keep *)
    sg13cmos5l_antennanp tiedowns [80:0] (
	`ifdef USE_POWER_PINS
	    // .VDD(VPWR),
	    // .VSS(VGND),
	`endif
	.A({porb, clk, SCK, SDI, CSB, mask_rev_in, dbus_out, io_in, sram_odata})
    );
    
    /* Instantiate buffers on all potentially long-distance outputs */
    (* keep *)
    sg13cmos5l_buf_8 outbuffers [69:0] (
	`ifdef USE_POWER_PINS
	    // .VDD(VPWR),
	    // .VSS(VGND),
	`endif
	.A({dbus_out, io_out, idac1_value, idac1_control, idac2_value, idac2_control,
			vbias_control, bandgap_control}),
	.X({dbus_out_buf, io_out_buf, idac1_value_buf, idac1_control_buf,
		idac2_value_buf, idac2_control_buf, vbias_control_buf,
		bandgap_control_buf})
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
	    .reset(reset),
	    .mask_rev_in(mask_rev_in),
	    .sram_addr(sram_addr),
	    .sram_idata(sram_idata),
	    .sram_odata(sram_odata),
	    .io_in(io_in),
	    .io_out(io_out_buf),
	    .io_oe(io_oe)buf),
	    .dbus_out(dbus_out_buf),
	    .dbus_in(dbus_in),
	    .proj_sel(proj_sel),
	    .proj_ena(proj_ena),
	    .proj_dig_ena(proj_dig_ena),
	    .proj_3v3_ena(proj_3v3_ena),
	    .proj_1v2_ena(proj_1v2_ena),
	    .analog_bus_ena(analog_bus_ena),
	    .idac1_value(idac1_value_buf),
	    .idac1_control(idac1_control_buf),
	    .idac2_value(idac2_value_buf),
	    .idac2_control(idac2_control_buf),
	    .vbias_control(vbias_control_buf),
	    .bandgap_control(bandgap_control_buf)
    );

endmodule
