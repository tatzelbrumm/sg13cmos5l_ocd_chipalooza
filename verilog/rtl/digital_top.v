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
    inout AVDD,     // 3.3V supply
    inout AVSS,     // common ground
    inout DVDD,     // 1.2V supply
    inout DVSS,     // common ground
`endif
  
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

    /* The four shared analog pins.
     *
     * Each pad is TWO ports here, not one.  A "real" has no
     * high-impedance state, iverilog rejects a real inout port, and a
     * real cannot have two drivers, so a bidirectional pad cannot be a
     * single port in this modelling style:
     *
     *   analog_pinN_in    what the outside world drives onto the pad.
     *                     NaN means nothing is connected, which is the
     *                     normal case and what a testbench should leave
     *                     it at unless it is deliberately driving.
     *   analog_pinN_out   the resolved pad value, which is what the
     *                     on-chip switches actually see.
     *
     * The chip drives a pad only when project 0 is selected, through the
     * four diagnostic switches.  The resolution below is therefore "the
     * internal driver wins while it is conducting, otherwise the pad",
     * which is the single resolving mux the switch models' header asks
     * for in place of many switches fighting over one net.
     */
    /* LVS_STRUCTURAL collapses each pad back to the single
     * bidirectional wire the schematic and the layout actually have.
     * See validate/lvs/README for the whole story;  in short, yosys
     * rejects a real port outright, so the structural view cannot carry
     * reals at all, and the split above is an iverilog artifact that
     * must not reach LVS.
     */
`ifdef LVS_STRUCTURAL
    inout wire analog_pin0,
    inout wire analog_pin1,
    inout wire analog_pin2,
    inout wire analog_pin3,
`else
    input real analog_pin0_in,
    input real analog_pin1_in,
    input real analog_pin2_in,
    input real analog_pin3_in,

    output real analog_pin0_out,
    output real analog_pin1_out,
    output real analog_pin2_out,
    output real analog_pin3_out,
`endif

    /* FIXME---All of the signals below are now internal to this module
     * They could be exported.  But do they need to be?
     * Currently the I/O list is left as-is to be compatible with the existing testbenches.
     */

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

    /* Tie-off nets for hard-wired constants.
     *
     * A CONSTANT IS NOT A NET.  netgen drops a connection written as a
     * literal --- it does not warn, the pin simply does not take part in
     * the comparison.  That silently excluded all 18 proj_addr buses and
     * the 40 SRAM tie-off pins until it was measured:  LVS reported
     * "match uniquely" with two slots' addresses swapped.
     *
     * Physically these pins are tied to a supply rail, which is what the
     * schematic draws, so the structural view says so.  Behaviourally
     * the two nets are just 1 and 0, and every expression below is
     * unchanged by the substitution.
     */
`ifdef LVS_STRUCTURAL
    wire tie_hi;
    wire tie_lo;
    assign tie_hi = DVDD;
    assign tie_lo = DVSS;
`else
    wire tie_hi;
    wire tie_lo;
    assign tie_hi = 1'b1;
    assign tie_lo = 1'b0;
`endif

    /* Signals between housekeeping and the SRAM */
    wire [9:0] sram_addr;
    wire [7:0] sram_idata;
    wire [7:0] sram_odata;
    wire       sram_read;
    wire       sram_write;
    wire       sram_clk;

    /* Signals between project control wrappers and housekeeping */
    wire [23:0]  dbus_out;
    wire [119:0] dbus_vec_left;		// 12 bits * 10
    wire [119:0] dbus_vec_right;	// 12 bits * 10
    wire porb;				// power-on reset, active low.
					// Generated on chip by the POR block
					// below;  there is no porb pad.
    wire project_zero;			// diagnostic
    wire clk_out;			// buffered clock to the projects

    /* Shared analog resources */
`ifdef LVS_STRUCTURAL
    wire user_ibias_shared [0:1];
    wire user_vbias_shared;
    wire user_analog_shared [0:3];
    wire analog_diag [0:3];
    wire vbandgap;
`else
    wire real user_ibias_shared [0:1];
    wire real user_vbias_shared;
    wire real user_analog_shared [0:3];		// The resolved shared analog pins
    wire real analog_diag [0:3];		// Diagnostic drive onto those pins
    wire real vbandgap;
`endif

    /* Individual project power supplies.
     *
     * Declared unconditionally, NOT inside the USE_POWER_PINS guard.
     * The power gates are part of what this model exists to test ---
     * proj_3v3_ena and proj_1v2_ena are housekeeping register bits like
     * any other --- so they have to keep working when the design is
     * simulated without power pins.  USE_POWER_PINS controls only where
     * the rail VALUE comes from, not whether the gating happens.
     */
`ifdef LVS_STRUCTURAL
    wire user_avdd [0:17];
    wire user_dvdd [0:17];
`else
    wire real user_avdd [0:17];
    wire real user_dvdd [0:17];
`endif

    /* The chip supply rails as real voltages.
     *
     * The power switch models take real inputs, but AVDD/DVDD are 1-bit
     * supply nets.  DO NOT connect them directly:  iverilog silently
     * coerces a wire at 1'b1 into a real port as 1.0, so a 3.3 V rail
     * would quietly become 1.0 V with no warning, and every downstream
     * voltage would be wrong but plausible.  Convert explicitly.
     */
`ifdef LVS_STRUCTURAL
    /* Structurally the rails ARE the supply nets;  there is no value to
     * convert, so the two names are just aliases.  LVS_STRUCTURAL
     * requires USE_POWER_PINS for exactly this reason --- without the
     * supply ports there would be nothing to alias, and the analog
     * cells' power pins would go unconnected.
     */
    wire avdd_rail;
    wire dvdd_rail;
    assign avdd_rail = AVDD;
    assign dvdd_rail = DVDD;
`else
    wire real avdd_rail;
    wire real dvdd_rail;

    `ifdef USE_POWER_PINS
	assign avdd_rail = (AVDD === 1'b1) ? 3.3 : 0.0;
	assign dvdd_rail = (DVDD === 1'b1) ? 1.2 : 0.0;
    `else
	/* No power pins:  the rails are simply at their nominal values,
	 * so the gates still gate and the enables stay testable. */
	assign avdd_rail = 3.3;
	assign dvdd_rail = 1.2;
    `endif
`endif

    /* Individual analog resources */
`ifdef LVS_STRUCTURAL
    wire user_vbias [0:17];		// 18 * 1
    wire user_ibias [0:35];		// 18 * 2
    wire user_analog [0:71];		// 18 * 4
`else
    wire real user_vbias [0:17];	// 18 * 1
    wire real user_ibias [0:35];	// 18 * 2
    wire real user_analog [0:71];	// 18 * 4
`endif

    /* Analog block biases */
`ifdef LVS_STRUCTURAL
    wire bandgap_sink1_ibias;
    wire bandgap_sink2_ibias;
    wire voltgen_sink1_ibias;
    wire voltgen_sink2_ibias;
    wire voltgen_source_ibias;
`else
    wire real bandgap_sink1_ibias;
    wire real bandgap_sink2_ibias;
    wire real voltgen_sink1_ibias;
    wire real voltgen_sink2_ibias;
    wire real voltgen_source_ibias;
`endif

    /* Instantiate the housekeeping top module */
    housekeeping_top hk_top (
	`ifdef USE_POWER_PINS
	    .VPWR(DVDD),
	    .VGND(DVSS),
	`endif
	    .porb(porb),
	    .clk(clk),
	    .SCK(SCK),
	    .SDI(SDI),
	    .CSB(CSB),
	    .SDO(SDO),
	    .sdo_ena(sdo_ena),
	    .reset(reset),
	    .clk_out(clk_out),
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
	    .dbus_in_left(dbus_vec_left[119:108]),
	    .dbus_in_right(dbus_vec_right[119:108]),
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
            .voltgen_source(voltgen_source),
	    .project_zero(project_zero)
    );

    /* Instantiate the SRAM */

    RM_IHPSG13_1P_1024x8_c2_bm_bist sram (
	.A_CLK(sram_clk),
	.A_MEN(porb),
	.A_WEN(sram_write),	// write enable
	.A_REN(sram_read),	// read enable
	.A_ADDR(sram_addr),
	.A_DIN(sram_idata),
	.A_DLY(tie_hi),		// set to 1 per documentation recommendation
	.A_DOUT(sram_odata),
	.A_BM({8{tie_hi}}),	// bit mask (all bits used)
	.A_BIST_CLK(tie_lo),	// not using BIST
	.A_BIST_EN(tie_lo),
	.A_BIST_MEN(tie_lo),
	.A_BIST_WEN(tie_lo),
	.A_BIST_REN(tie_lo),
	.A_BIST_ADDR({10{tie_lo}}),
	.A_BIST_DIN({8{tie_lo}}),
	.A_BIST_BM({8{tie_lo}})
    );

    /* Signals between project control and project wrapper (18 instances) */

    wire [17:0] user_clk;
    wire [17:0] user_ena;
    wire [17:0] user_reset;
    wire [17:0] user_3v3_ena;
    wire [17:0] user_1v2_ena;
    wire [71:0] user_analog_ena;	// 4 bits * 18
    wire [35:0] user_ibias_ena;		// 2 bits * 18
    wire [17:0] user_vbias_ena;
    wire [431:0] user_dig_in;		// 24 bits * 18
    wire [215:0] user_dig_out;		// 12 bits * 18

    /* Low 12 bits on dbus_vec_* are zero:  the far end of each daisy
     * chain has nothing above it to relay.
     *
     * Structurally these are not a logical constant.  user_project_control
     * is a hard macro and dig_out_relay[11:0] are 12 real input pins on
     * it, so the schematic has to connect them to something --- which is
     * DVSS.  Writing 12'h000 in the structural view instead leaves a
     * bare constant attached to a bus port, which netgen rejects with
     * "Single net 12'h000 is connected to bus port dig_out_relay".
     * CHECK THIS AGAINST THE SCHEMATIC:  those 24 pins (12 on each
     * chain's top slot) must be tied to the digital ground.
     */
`ifdef LVS_STRUCTURAL
    assign dbus_vec_left[11:0] = {12{DVSS}};
    assign dbus_vec_right[11:0] = {12{DVSS}};
`else
    assign dbus_vec_left[11:0] = 12'h000;
    assign dbus_vec_right[11:0] = 12'h000;
`endif

    /* Instantiate 18 project control blocks */
    /* NOTE: Project zero is diagnostic;  user projects are numbered 1 to 18 */

    genvar i;

    generate
	/* NOTE:  bit_index must be declared inside the loop body.  It was
	 * a single wire in the generate scope with a continuous assignment
	 * per iteration, giving it 18 drivers;  it resolved to x, so every
	 * proj_addr was x, "select" never asserted, and none of the control
	 * blocks could be exercised at all.
	 */
	/* Right side column */
	for (i = 8; i >= 0; i = i - 1) begin : right_slot
	    localparam [4:0] bit_index = i + 1;	// Implicitly truncate

	    /* The hard-wired slot address, as five tied pins rather than a
	     * literal.  This is the ONLY thing that distinguishes one
	     * user_project_control from the other seventeen, so it is the
	     * one connection that most needs to be in the comparison ---
	     * and as a literal it was not.  tie_hi/tie_lo are 1 and 0 in
	     * the behavioural view, so this is exactly bit_index there.
	     */
	    wire [4:0] proj_addr_tie;
	    assign proj_addr_tie = {bit_index[4] ? tie_hi : tie_lo,
				    bit_index[3] ? tie_hi : tie_lo,
				    bit_index[2] ? tie_hi : tie_lo,
				    bit_index[1] ? tie_hi : tie_lo,
				    bit_index[0] ? tie_hi : tie_lo};

		user_project_control ctrl (
		    .proj_addr(proj_addr_tie),
		    .proj_sel(proj_sel),
		    .clk(clk),
		    .dig_ena(proj_dig_ena),
	  	    .enable(proj_ena),
	  	    .reset(reset),
		    .analog_ena(analog_bus_ena),
		    .ibias_ena(proj_ibias_ena),
		    .vbias_ena(proj_vbias_ena),
		    .power_3v3_ena(proj_3v3_ena),
		    .power_1v2_ena(proj_1v2_ena),
		    .dig_in(dbus_out),
		    .dig_out(dbus_vec_right[(9-i)*12 +: 12]),
		    .dig_out_relay(dbus_vec_right[(8-i)*12 +: 12]),

		    // These signals connect to the user project harness
		    .proj_clk(user_clk[i]),
		    .proj_ena(user_ena[i]),
		    .proj_reset(user_reset[i]),
		    .proj_3v3_ena(user_3v3_ena[i]),
		    .proj_1v2_ena(user_1v2_ena[i]),
		    .proj_analog_ena(user_analog_ena[i*4 +: 4]), // 4 bits
		    .proj_ibias_ena(user_ibias_ena[i*2 +: 2]),   // 2 bits
		    .proj_vbias_ena(user_vbias_ena[i]),
		    .proj_dig_in(user_dig_in[i*24 +: 24]),	 // 24 bits
		    .proj_dig_out(user_dig_out[i*12 +: 12])	 // 12 bits
		);
	end

	/* Left side column */
	for (i = 9; i < 18; i = i + 1) begin : left_slot
	    localparam [4:0] bit_index = i + 1;	// Implicitly truncate

	    /* The hard-wired slot address, as five tied pins rather than a
	     * literal.  This is the ONLY thing that distinguishes one
	     * user_project_control from the other seventeen, so it is the
	     * one connection that most needs to be in the comparison ---
	     * and as a literal it was not.  tie_hi/tie_lo are 1 and 0 in
	     * the behavioural view, so this is exactly bit_index there.
	     */
	    wire [4:0] proj_addr_tie;
	    assign proj_addr_tie = {bit_index[4] ? tie_hi : tie_lo,
				    bit_index[3] ? tie_hi : tie_lo,
				    bit_index[2] ? tie_hi : tie_lo,
				    bit_index[1] ? tie_hi : tie_lo,
				    bit_index[0] ? tie_hi : tie_lo};

		user_project_control ctrl (
		    .proj_addr(proj_addr_tie),
		    .proj_sel(proj_sel),
		    .clk(clk),
		    .dig_ena(proj_dig_ena),
	  	    .enable(proj_ena),
	  	    .reset(reset),
		    .analog_ena(analog_bus_ena),
		    .ibias_ena(proj_ibias_ena),
		    .vbias_ena(proj_vbias_ena),
		    .power_3v3_ena(proj_3v3_ena),
		    .power_1v2_ena(proj_1v2_ena),
		    .dig_in(dbus_out),
		    .dig_out(dbus_vec_left[(i-8)*12 +: 12]),
		    .dig_out_relay(dbus_vec_left[(i-9)*12 +: 12]),

		    // These signals connect to the user project harness
		    .proj_clk(user_clk[i]),
		    .proj_ena(user_ena[i]),
		    .proj_reset(user_reset[i]),
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

    /* Instantiate the three main analog resource blocks (bandgap, biasgen, and voltgen) */
    /* These are behavioral models, using real-type values for currents and voltages */

    sg13cmos5l_ocd_ip__bandgap_v2 bandgap (
	`ifdef USE_POWER_PINS
	    .dvdd(DVDD),
	    .dvss(DVSS),
	    .vdd(AVDD),
	    .vss(AVSS),
	`endif
	.ena(bandgap_ena),
	.trim(bandgap_trim),
	/* NOTE THE CROSSING.  The two blocks number their bias pins by
	 * different conventions, so matching them up by ordinal is wrong:
	 *
	 *   biasgen2   bandgap_sink1 is the 1 uA sink   (3-bit trim)
	 *              bandgap_sink2 is the 250 nA sink (2-bit trim)
	 *   bandgap    ibias1_250n   wants 250 nA
	 *              ibias2_1      wants 1 uA
	 *
	 * This was .ibias1_250n(bandgap_sink1_ibias) and
	 * .ibias2_1(bandgap_sink2_ibias), which delivered 1 uA where
	 * 250 nA was wanted and 250 nA where 1 uA was wanted --- a clean
	 * factor of four the wrong way on both pins, with the documented
	 * register settings (0x1D = 12) correctly programmed.  Caught by
	 * the bias range check in the bandgap model.
	 */
	.ibias1_250n(bandgap_sink2_ibias),
	.ibias2_1(bandgap_sink1_ibias),
	.vbg(vbandgap)
    );

    sg13cmos5l_ocd_ip__voltgen_v2 voltgen (
	`ifdef USE_POWER_PINS
	    .dvdd(DVDD),
	    .dvss(DVSS),
	    .vdd(AVDD),
	    .vss(AVSS),
	`endif
	.ena(voltgen_ena[0]),
	.ena1(voltgen_ena[1]),
	.ena2(voltgen_ena[2]),
	.high(voltgen_high),
	.s(voltgen_value),
	.ibias1u_1(voltgen_sink1_ibias),
	.ibias1u_2(voltgen_sink2_ibias),
	.ibias1u_3(voltgen_source_ibias),
	.vbg(vbandgap),
	.vout1(user_vbias_shared),
	.vout2()			/* Not used, maybe should provide a switch? */
    );
    
    sg13cmos5l_ocd_ip__biasgen2 biasgen (
	`ifdef USE_POWER_PINS
	    .dvdd(DVDD),
	    .dvss(DVSS),
	    .vdd(AVDD),
	    .vss(AVSS),
	`endif
	.ena(biasgen_ena),
	.ref_sel_vbg(biasgen_ref_vbg),
	.ref_sel_coarse(biasgen_coarse),
	.ref_sel_fine(biasgen_fine),
	.bandgap_sink1(bandgap_sink1),
	.bandgap_sink2(bandgap_sink2),
	.voltgen_sink1(voltgen_sink1),
	.voltgen_sink2(voltgen_sink2),
	.voltgen_source(voltgen_source),
	.idac1_source(idac1_value),
	.idac2_source(idac2_value),
	/* Must be avdd_rail, not AVDD:  AVDD only exists inside the
	 * USE_POWER_PINS guard, so without that define this became an
	 * implicit undeclared net driving a real port, which crashed vvp
	 * with "vpi_get_value: Assertion `expr' failed".  avdd_rail is
	 * also the correctly typed real value rather than a coerced bit.
	 */
	.ref_in(avdd_rail),
	.vbg(vbandgap),
	.bandgap_sink1_ibias(bandgap_sink1_ibias),
	.bandgap_sink2_ibias(bandgap_sink2_ibias),
	.voltgen_sink1_ibias(voltgen_sink1_ibias),
	.voltgen_sink2_ibias(voltgen_sink2_ibias),
	.voltgen_source_ibias(voltgen_source_ibias),
	.idac1_source_ibias(user_ibias_shared[0]),
	.idac2_source_ibias(user_ibias_shared[1])
    );

    /* A power-on-reset circuit generates the "porb" signal on power-up.
     * Keep the default parameter POR_DELAY_NS (= 1us) for simulation purposes.
     */

    sg13cmos5l_ocd_ip__por por (
	`ifdef USE_POWER_PINS
	    .vdd1v2(DVDD),
	    .vss(DVSS),
	`endif
	/* "ena" gates the amplifier's tail current and is tied to the
	 * 1.2 V supply in the layout.  It must NOT be written as DVDD
	 * unconditionally:  DVDD only exists inside the USE_POWER_PINS
	 * guard, so without that define it becomes an implicit undeclared
	 * net, the enable is x, and the part never leaves reset.  That is
	 * the same trap that .ref_in(AVDD) fell into on the biasgen.
	 */
	`ifdef USE_POWER_PINS
	    .ena(DVDD),
	`else
	    .ena(1'b1),
	`endif
	.por(),		// unused output
	.porb(porb),
	.por_unbuf()	// diagnostic output, not to be used
    );

    /* These four switches are diagnostic:  They provide a way to measure the outputs of the
     * bandgap, voltage bias generator, and current bias generator directly on the shared
     * analog pins.  They are enabled by selecting project 0, which is otherwise unassigned.
     */

    /* The two current bias switches */
    analog_pswitch_small #(.CURRENT_MODE(1)) switch_ibias0_diagnostic (
	`ifdef USE_POWER_PINS
	    .dvdd(DVDD),
	    .dvss(DVSS),
	    .avdd(AVDD),
	    .avss(AVSS),
	`endif
	.enable(project_zero),
	.in(user_ibias_shared[0]),
	.out(analog_diag[0])
    );

    analog_pswitch_small #(.CURRENT_MODE(1)) switch_ibias1_diagnostic (
	`ifdef USE_POWER_PINS
	    .dvdd(DVDD),
	    .dvss(DVSS),
	    .avdd(AVDD),
	    .avss(AVSS),
	`endif
	.enable(project_zero),
	.in(user_ibias_shared[1]),
	.out(analog_diag[1])
    );

    /* The voltage bias switch */
    analog_switch_small switch_vbias_diagnostic (
	`ifdef USE_POWER_PINS
	    .dvdd(DVDD),
	    .dvss(DVSS),
	    .avdd(AVDD),
	    .avss(AVSS),
	`endif
	.enable(project_zero),
	.in(user_vbias_shared),
	.out(analog_diag[2])
    );

    /* The bandgap value switch */
    analog_switch_small switch_vbg_diagnostic (
	`ifdef USE_POWER_PINS
	    .dvdd(DVDD),
	    .dvss(DVSS),
	    .avdd(AVDD),
	    .avss(AVSS),
	`endif
	.enable(project_zero),
	.in(vbandgap),
	.out(analog_diag[3])
    );

    /* Resolve each shared analog pin.
     *
     * A diagnostic switch that is conducting drives the pin;  when it is
     * off its output is NaN and the pad input drives instead.  "x == x"
     * is false only for NaN, which is the one reliable NaN test in
     * Verilog --- do not rewrite these as a comparison against a
     * constant, because every comparison against NaN is false and the
     * test would always take the same branch.
     *
     * Note this is the only place a real is resolved between two
     * sources in this design;  everywhere else a single source fans out
     * through switches.
     */
`ifdef LVS_STRUCTURAL
    /* Structurally there is no resolution to do:  the diagnostic switch
     * output, the pad and the on-chip distribution are ONE NET, which is
     * what the schematic draws and what the layout builds.  The mux
     * below exists only because a real cannot have two drivers.  Here
     * the four nets are simply tied together, which is what LVS has to
     * see.
     */
    assign user_analog_shared[0] = analog_pin0;
    assign user_analog_shared[1] = analog_pin1;
    assign user_analog_shared[2] = analog_pin2;
    assign user_analog_shared[3] = analog_pin3;

    assign analog_diag[0] = analog_pin0;
    assign analog_diag[1] = analog_pin1;
    assign analog_diag[2] = analog_pin2;
    assign analog_diag[3] = analog_pin3;
`else
    assign user_analog_shared[0] = (analog_diag[0] == analog_diag[0]) ?
					analog_diag[0] : analog_pin0_in;
    assign user_analog_shared[1] = (analog_diag[1] == analog_diag[1]) ?
					analog_diag[1] : analog_pin1_in;
    assign user_analog_shared[2] = (analog_diag[2] == analog_diag[2]) ?
					analog_diag[2] : analog_pin2_in;
    assign user_analog_shared[3] = (analog_diag[3] == analog_diag[3]) ?
					analog_diag[3] : analog_pin3_in;

    assign analog_pin0_out = user_analog_shared[0];
    assign analog_pin1_out = user_analog_shared[1];
    assign analog_pin2_out = user_analog_shared[2];
    assign analog_pin3_out = user_analog_shared[3];
`endif
    
    /*
     * Instantiate the set of switches that connect each user project to the shared
     * resources (current biases, voltage bias, power suppies, analog pins)
     */

    generate
	for (i = 0; i < 18; i = i + 1) begin : slot_switches
	    /* Primary analog/high voltage power switch */
	    power_stage2 switch3v3 (
		`ifdef USE_POWER_PINS
		    .DVDD(DVDD),
		    .DVSS(DVSS),
		    .IOVSS(AVSS),
		`endif
		.enable(user_3v3_ena[i]),
		.IOVDD_IN(avdd_rail),
		.IOVDD_OUT(user_avdd[i])
	    );

	    /* Primary digital/low voltage power switch */
	    power_stage1v2 switch1v2 (
		`ifdef USE_POWER_PINS
		    .DVSS(DVSS),
		`endif
		.enable(user_1v2_ena[i]),
		.DVDD_IN(dvdd_rail),
		.DVDD_OUT(user_dvdd[i])
	    );

	    /* The four shared analog bus switches */
	    analog_switch_med switch_analog0 (
		`ifdef USE_POWER_PINS
		    .dvdd(DVDD),
		    .dvss(DVSS),
		    .avdd(AVDD),
		    .avss(AVSS),
		`endif
		.enable(user_analog_ena[i*4]),
		.in(user_analog_shared[0]),
		.out(user_analog[i*4])
	    );

	    analog_switch_med switch_analog1 (
		`ifdef USE_POWER_PINS
		    .dvdd(DVDD),
		    .dvss(DVSS),
		    .avdd(AVDD),
		    .avss(AVSS),
		`endif
		.enable(user_analog_ena[i*4 + 1]),
		.in(user_analog_shared[1]),
		.out(user_analog[i*4 + 1])
	    );

	    analog_switch_med switch_analog2 (
		`ifdef USE_POWER_PINS
		    .dvdd(DVDD),
		    .dvss(DVSS),
		    .avdd(AVDD),
		    .avss(AVSS),
		`endif
		.enable(user_analog_ena[i*4 + 2]),
		.in(user_analog_shared[2]),
		.out(user_analog[i*4 + 2])
	    );

	    analog_switch_med switch_analog3 (
		`ifdef USE_POWER_PINS
		    .dvdd(DVDD),
		    .dvss(DVSS),
		    .avdd(AVDD),
		    .avss(AVSS),
		`endif
		.enable(user_analog_ena[i*4 + 3]),
		.in(user_analog_shared[3]),
		.out(user_analog[i*4 + 3])
	    );

	    /* The two current bias switches */
	    analog_pswitch_small #(.CURRENT_MODE(1)) switch_ibias0 (
		`ifdef USE_POWER_PINS
		    .dvdd(DVDD),
		    .dvss(DVSS),
		    .avdd(AVDD),
		    .avss(AVSS),
		`endif
		.enable(user_ibias_ena[i*2]),
		.in(user_ibias_shared[0]),
		.out(user_ibias[i*2])
	    );

	    analog_pswitch_small #(.CURRENT_MODE(1)) switch_ibias1 (
		`ifdef USE_POWER_PINS
		    .dvdd(DVDD),
		    .dvss(DVSS),
		    .avdd(AVDD),
		    .avss(AVSS),
		`endif
		.enable(user_ibias_ena[i*2 + 1]),
		.in(user_ibias_shared[1]),
		.out(user_ibias[i*2 + 1])
	    );

	    /* The voltage bias switch */
	    analog_switch_small switch_vbias (
		`ifdef USE_POWER_PINS
		    .dvdd(DVDD),
		    .dvss(DVSS),
		    .avdd(AVDD),
		    .avss(AVSS),
		`endif
		.enable(user_vbias_ena[i]),
		.in(user_vbias_shared),
		.out(user_vbias[i])
	    );

	end
    endgenerate

    /* Instantiate the per-project switches */

    /* Instantiate the 18 user project slot wrappers.
     *
     * One wrapper module per slot, not one per distinct pin count, so a
     * slot can be changed independently if a designer wants a different
     * I/O cell than the default on a dedicated pin.
     *
     * Slot N is driven by control block index N-1:  the right column
     * carries slots 1..9 and the left column slots 10..18 (see the
     * generate loops above).
     *
     * The dedicated analog pins are left unconnected here.  They face
     * the padframe, which this testbench deliberately does not model ---
     * there is nothing meaningful to check on that side.  The point of
     * instantiating the wrappers at all is that user_dig_in and
     * user_dig_out are no longer dangling, so the digital signalling to
     * and from each slot can be observed.
     */

    /* The padframe side of the slot wrappers is not modelled:  there is
     * nothing meaningful a testbench can check about it.  Tie the
     * dedicated analog pins to NaN rather than leaving them unconnected,
     * so that a project reading one sees "no value" rather than a
     * plausible 0.0 volts.
     */
`ifdef LVS_STRUCTURAL
    /* The dedicated per-slot analog pads are not exported yet, so
     * structurally they are a single dangling net.  LVS WILL FLAG THIS
     * as an unconnected pin on every slot wrapper, and that is the
     * correct complaint --- the schematic has real pads there.  Export
     * them (40 more ports) when something needs to drive them;  until
     * then this is a known, named discrepancy rather than a silent one.
     */
    wire pad_not_modelled;
`else
    wire real pad_not_modelled;
    assign pad_not_modelled = 0.0/0.0;
`endif

    slot1_wrapper slot1 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[0]),
	    .vdd_1v2(user_dvdd[0]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[0]),
	.clk(user_clk[0]),
	.reset(user_reset[0]),
	.dig_in(user_dig_in[0*24 +: 24]),
	.dig_out(user_dig_out[0*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[0*2 + 0]),
	.ibias1(user_ibias[0*2 + 1]),
	.vbias(user_vbias[0]),
	.analog_bus0(user_analog[0*4 + 0]),
	.analog_bus1(user_analog[0*4 + 1]),
	.analog_bus2(user_analog[0*4 + 2]),
	.analog_bus3(user_analog[0*4 + 3])
    );

    slot2_wrapper slot2 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[1]),
	    .vdd_1v2(user_dvdd[1]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[1]),
	.clk(user_clk[1]),
	.reset(user_reset[1]),
	.dig_in(user_dig_in[1*24 +: 24]),
	.dig_out(user_dig_out[1*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[1*2 + 0]),
	.ibias1(user_ibias[1*2 + 1]),
	.vbias(user_vbias[1]),
	.analog_bus0(user_analog[1*4 + 0]),
	.analog_bus1(user_analog[1*4 + 1]),
	.analog_bus2(user_analog[1*4 + 2]),
	.analog_bus3(user_analog[1*4 + 3])
    );

    slot3_wrapper slot3 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[2]),
	    .vdd_1v2(user_dvdd[2]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[2]),
	.clk(user_clk[2]),
	.reset(user_reset[2]),
	.dig_in(user_dig_in[2*24 +: 24]),
	.dig_out(user_dig_out[2*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[2*2 + 0]),
	.ibias1(user_ibias[2*2 + 1]),
	.vbias(user_vbias[2]),
	.analog_bus0(user_analog[2*4 + 0]),
	.analog_bus1(user_analog[2*4 + 1]),
	.analog_bus2(user_analog[2*4 + 2]),
	.analog_bus3(user_analog[2*4 + 3])
    );

    slot4_wrapper slot4 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[3]),
	    .vdd_1v2(user_dvdd[3]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[3]),
	.clk(user_clk[3]),
	.reset(user_reset[3]),
	.dig_in(user_dig_in[3*24 +: 24]),
	.dig_out(user_dig_out[3*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.ibias0(user_ibias[3*2 + 0]),
	.ibias1(user_ibias[3*2 + 1]),
	.vbias(user_vbias[3]),
	.analog_bus0(user_analog[3*4 + 0]),
	.analog_bus1(user_analog[3*4 + 1]),
	.analog_bus2(user_analog[3*4 + 2]),
	.analog_bus3(user_analog[3*4 + 3])
    );

    slot5_wrapper slot5 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[4]),
	    .vdd_1v2(user_dvdd[4]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[4]),
	.clk(user_clk[4]),
	.reset(user_reset[4]),
	.dig_in(user_dig_in[4*24 +: 24]),
	.dig_out(user_dig_out[4*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.analog_pin2(pad_not_modelled),
	.ibias0(user_ibias[4*2 + 0]),
	.ibias1(user_ibias[4*2 + 1]),
	.vbias(user_vbias[4]),
	.analog_bus0(user_analog[4*4 + 0]),
	.analog_bus1(user_analog[4*4 + 1]),
	.analog_bus2(user_analog[4*4 + 2]),
	.analog_bus3(user_analog[4*4 + 3])
    );

    slot6_wrapper slot6 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[5]),
	    .vdd_1v2(user_dvdd[5]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[5]),
	.clk(user_clk[5]),
	.reset(user_reset[5]),
	.dig_in(user_dig_in[5*24 +: 24]),
	.dig_out(user_dig_out[5*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[5*2 + 0]),
	.ibias1(user_ibias[5*2 + 1]),
	.vbias(user_vbias[5]),
	.analog_bus0(user_analog[5*4 + 0]),
	.analog_bus1(user_analog[5*4 + 1]),
	.analog_bus2(user_analog[5*4 + 2]),
	.analog_bus3(user_analog[5*4 + 3])
    );

    slot7_wrapper slot7 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[6]),
	    .vdd_1v2(user_dvdd[6]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[6]),
	.clk(user_clk[6]),
	.reset(user_reset[6]),
	.dig_in(user_dig_in[6*24 +: 24]),
	.dig_out(user_dig_out[6*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[6*2 + 0]),
	.ibias1(user_ibias[6*2 + 1]),
	.vbias(user_vbias[6]),
	.analog_bus0(user_analog[6*4 + 0]),
	.analog_bus1(user_analog[6*4 + 1]),
	.analog_bus2(user_analog[6*4 + 2]),
	.analog_bus3(user_analog[6*4 + 3])
    );

    slot8_wrapper slot8 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[7]),
	    .vdd_1v2(user_dvdd[7]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[7]),
	.clk(user_clk[7]),
	.reset(user_reset[7]),
	.dig_in(user_dig_in[7*24 +: 24]),
	.dig_out(user_dig_out[7*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.ibias0(user_ibias[7*2 + 0]),
	.ibias1(user_ibias[7*2 + 1]),
	.vbias(user_vbias[7]),
	.analog_bus0(user_analog[7*4 + 0]),
	.analog_bus1(user_analog[7*4 + 1]),
	.analog_bus2(user_analog[7*4 + 2]),
	.analog_bus3(user_analog[7*4 + 3])
    );

    slot9_wrapper slot9 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[8]),
	    .vdd_1v2(user_dvdd[8]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[8]),
	.clk(user_clk[8]),
	.reset(user_reset[8]),
	.dig_in(user_dig_in[8*24 +: 24]),
	.dig_out(user_dig_out[8*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.analog_pin2(pad_not_modelled),
	.ibias0(user_ibias[8*2 + 0]),
	.ibias1(user_ibias[8*2 + 1]),
	.vbias(user_vbias[8]),
	.analog_bus0(user_analog[8*4 + 0]),
	.analog_bus1(user_analog[8*4 + 1]),
	.analog_bus2(user_analog[8*4 + 2]),
	.analog_bus3(user_analog[8*4 + 3])
    );

    slot10_wrapper slot10 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[9]),
	    .vdd_1v2(user_dvdd[9]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[9]),
	.clk(user_clk[9]),
	.reset(user_reset[9]),
	.dig_in(user_dig_in[9*24 +: 24]),
	.dig_out(user_dig_out[9*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.analog_pin2(pad_not_modelled),
	.ibias0(user_ibias[9*2 + 0]),
	.ibias1(user_ibias[9*2 + 1]),
	.vbias(user_vbias[9]),
	.analog_bus0(user_analog[9*4 + 0]),
	.analog_bus1(user_analog[9*4 + 1]),
	.analog_bus2(user_analog[9*4 + 2]),
	.analog_bus3(user_analog[9*4 + 3])
    );

    slot11_wrapper slot11 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[10]),
	    .vdd_1v2(user_dvdd[10]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[10]),
	.clk(user_clk[10]),
	.reset(user_reset[10]),
	.dig_in(user_dig_in[10*24 +: 24]),
	.dig_out(user_dig_out[10*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.ibias0(user_ibias[10*2 + 0]),
	.ibias1(user_ibias[10*2 + 1]),
	.vbias(user_vbias[10]),
	.analog_bus0(user_analog[10*4 + 0]),
	.analog_bus1(user_analog[10*4 + 1]),
	.analog_bus2(user_analog[10*4 + 2]),
	.analog_bus3(user_analog[10*4 + 3])
    );

    slot12_wrapper slot12 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[11]),
	    .vdd_1v2(user_dvdd[11]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[11]),
	.clk(user_clk[11]),
	.reset(user_reset[11]),
	.dig_in(user_dig_in[11*24 +: 24]),
	.dig_out(user_dig_out[11*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[11*2 + 0]),
	.ibias1(user_ibias[11*2 + 1]),
	.vbias(user_vbias[11]),
	.analog_bus0(user_analog[11*4 + 0]),
	.analog_bus1(user_analog[11*4 + 1]),
	.analog_bus2(user_analog[11*4 + 2]),
	.analog_bus3(user_analog[11*4 + 3])
    );

    slot13_wrapper slot13 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[12]),
	    .vdd_1v2(user_dvdd[12]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[12]),
	.clk(user_clk[12]),
	.reset(user_reset[12]),
	.dig_in(user_dig_in[12*24 +: 24]),
	.dig_out(user_dig_out[12*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[12*2 + 0]),
	.ibias1(user_ibias[12*2 + 1]),
	.vbias(user_vbias[12]),
	.analog_bus0(user_analog[12*4 + 0]),
	.analog_bus1(user_analog[12*4 + 1]),
	.analog_bus2(user_analog[12*4 + 2]),
	.analog_bus3(user_analog[12*4 + 3])
    );

    slot14_wrapper slot14 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[13]),
	    .vdd_1v2(user_dvdd[13]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[13]),
	.clk(user_clk[13]),
	.reset(user_reset[13]),
	.dig_in(user_dig_in[13*24 +: 24]),
	.dig_out(user_dig_out[13*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.analog_pin2(pad_not_modelled),
	.ibias0(user_ibias[13*2 + 0]),
	.ibias1(user_ibias[13*2 + 1]),
	.vbias(user_vbias[13]),
	.analog_bus0(user_analog[13*4 + 0]),
	.analog_bus1(user_analog[13*4 + 1]),
	.analog_bus2(user_analog[13*4 + 2]),
	.analog_bus3(user_analog[13*4 + 3])
    );

    slot15_wrapper slot15 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[14]),
	    .vdd_1v2(user_dvdd[14]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[14]),
	.clk(user_clk[14]),
	.reset(user_reset[14]),
	.dig_in(user_dig_in[14*24 +: 24]),
	.dig_out(user_dig_out[14*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.ibias0(user_ibias[14*2 + 0]),
	.ibias1(user_ibias[14*2 + 1]),
	.vbias(user_vbias[14]),
	.analog_bus0(user_analog[14*4 + 0]),
	.analog_bus1(user_analog[14*4 + 1]),
	.analog_bus2(user_analog[14*4 + 2]),
	.analog_bus3(user_analog[14*4 + 3])
    );

    slot16_wrapper slot16 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[15]),
	    .vdd_1v2(user_dvdd[15]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[15]),
	.clk(user_clk[15]),
	.reset(user_reset[15]),
	.dig_in(user_dig_in[15*24 +: 24]),
	.dig_out(user_dig_out[15*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[15*2 + 0]),
	.ibias1(user_ibias[15*2 + 1]),
	.vbias(user_vbias[15]),
	.analog_bus0(user_analog[15*4 + 0]),
	.analog_bus1(user_analog[15*4 + 1]),
	.analog_bus2(user_analog[15*4 + 2]),
	.analog_bus3(user_analog[15*4 + 3])
    );

    slot17_wrapper slot17 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[16]),
	    .vdd_1v2(user_dvdd[16]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[16]),
	.clk(user_clk[16]),
	.reset(user_reset[16]),
	.dig_in(user_dig_in[16*24 +: 24]),
	.dig_out(user_dig_out[16*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[16*2 + 0]),
	.ibias1(user_ibias[16*2 + 1]),
	.vbias(user_vbias[16]),
	.analog_bus0(user_analog[16*4 + 0]),
	.analog_bus1(user_analog[16*4 + 1]),
	.analog_bus2(user_analog[16*4 + 2]),
	.analog_bus3(user_analog[16*4 + 3])
    );

    slot18_wrapper slot18 (
	`ifdef USE_POWER_PINS
	    .vdd_3v3(user_avdd[17]),
	    .vdd_1v2(user_dvdd[17]),
	    .vss_3v3(AVSS),
	    .vss_1v2(DVSS),
	`endif
	.enable(user_ena[17]),
	.clk(user_clk[17]),
	.reset(user_reset[17]),
	.dig_in(user_dig_in[17*24 +: 24]),
	.dig_out(user_dig_out[17*12 +: 12]),
	.analog_pin0(pad_not_modelled),
	.analog_pin1(pad_not_modelled),
	.ibias0(user_ibias[17*2 + 0]),
	.ibias1(user_ibias[17*2 + 1]),
	.vbias(user_vbias[17]),
	.analog_bus0(user_analog[17*4 + 0]),
	.analog_bus1(user_analog[17*4 + 1]),
	.analog_bus2(user_analog[17*4 + 2]),
	.analog_bus3(user_analog[17*4 + 3])
    );

endmodule
