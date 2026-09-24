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
 * User project control ----
 * Wrapper for user_project_control_base.
 * This block controls signal access to and from the user project wrapper.
 *
 * See user_project_control_base.v for details of the module wrapped by
 * this interface layer.
 */ 

module user_project_control (
    /* Infrastructure-facing signals */

    input wire [4:0] proj_addr,		// Project address (external)
    input wire [4:0] proj_sel,		// Selected project (from houskeeping)
    input wire clk,			// Master system clock
    input wire dig_ena,			// Digital connect enable
    input wire enable,			// Enable signal for project
    input wire reset,			// Digital reset signal for project
    input wire [3:0] analog_ena,	// analog bus enables
    input wire [1:0] ibias_ena,		// Current bias enables
    input wire vbias_ena,		// Voltage bias enable
    input wire power_3v3_ena,		// 3.3V power gate switch enable
    input wire power_1v2_ena,		// 1.2V power gate switch enable

    input  wire [23:0] dig_in,		// 24 digital bit shared bus
    input  wire [11:0] dig_out_relay,	// 12 digital bits from previous slot
    output wire [11:0] dig_out,		// 12 digital bits to next slot

    /* Project-facing signals */

    output wire proj_clk,
    output wire proj_ena,
    output wire proj_reset,

    output wire proj_3v3_ena,
    output wire proj_1v2_ena,
    output wire [3:0] proj_analog_ena,
    output wire [1:0] proj_ibias_ena,
    output wire proj_vbias_ena,

    /* Per-bit operational modes (from housekeeping registers) */
    output wire [23:0] proj_dig_in,	// 24 digital input bits to project
    input wire [11:0] proj_dig_out	// 12 digital output bits from project
);

    /* Used by interface for gating the latches */
    wire select;

    /* unbuffered outputs from base module */
    wire [11:0] dig_out_unbuf;
    wire proj_clk_unbuf;
    wire proj_ena_unbuf;
    wire proj_reset_unbuf;
    wire proj_3v3_ena_unbuf;
    wire proj_1v2_ena_unbuf;
    wire [3:0] proj_analog_ena_unbuf;
    wire [1:0] proj_ibias_ena_unbuf;
    wire proj_vbias_ena_unbuf;
    wire [23:0] proj_dig_in_unbuf;

    /* dig_ena acts as a latch to the digital input.  This allows the user
     * to set up the digital input signal routing in advance, and then
     * release the latch to present all signals to the user project at the
     * same time.  The latch also acts to hold the state of the digital
     * inputs.
     */

    genvar i;
    generate
	for (i = 0; i < 24; i = i + 1) begin:  dig_in_gen
	    (* keep *)
	    sg13cmos5l_dlhrq_1 dig_in_latch (
		.Q(proj_dig_in_unbuf[i]),
		.D(dig_in[i]),
		.GATE(dig_ena),
		/* RESET_B is ACTIVE LOW, so it is driven by "select", not by
		 * "~select".  With the inversion the latch was held in reset
		 * on whichever slot was selected --- that project could never
		 * receive anything on the shared bus, its 24 inputs were
		 * pinned to zero --- while every unselected slot had its reset
		 * released and went transparent on dig_ena, so all seventeen
		 * of them latched the bus instead.  Covered by
		 * verilog/dv/test_project_control.py.
		 */
		.RESET_B(select)
	    );
	end
    endgenerate

    /* Generate the gated clock for the user project.
     *
     * An integrated clock-gating cell is used rather than a plain AND of
     * "select" and "clk".  The latch inside the cell captures "select"
     * while clk is low, so proj_clk cannot produce a runt pulse or a
     * spurious rising edge when the selected project changes --- which a
     * plain AND gate can do, in particular when clk has been stopped in
     * the high state (permitted here, since some analog projects prefer
     * to stop the clock to eliminate digital noise).
     *
     * NOTE:  sg13cmos5l_lgcp_1 appears in the PDK's synth_exclude.cells
     * and pnr_exclude.cells lists.  Those only stop yosys from inferring
     * clock gates and stop the OpenROAD resizer from substituting the
     * cell; an explicitly instantiated one is kept and placed normally.
     */
    (* keep *)
    sg13cmos5l_lgcp_1 clockgate (
	.CLK(clk),
	.GATE(select),
	.GCLK(proj_clk_unbuf)
    );

    /* Place antenna diodes on all of the digital inputs (except select,
     * which just runs from the base to the wrapper)
     */

    (* keep *)
    sg13cmos5l_antennanp tiedowns [70:0] (
	// no. signals = 5, 5, 1, 1, 1, 1, 4, 2, 1, 1, 1, 24, 12, 12 = 71
	.A({proj_addr, proj_sel, clk, dig_ena, enable, reset, analog_ena,
		ibias_ena, vbias_ena, power_3v3_ena, power_1v2_ena, dig_in,
		dig_out_relay, proj_dig_out})
    );

    /* Buffer all of the long-haul outputs, which is everything that goes back to
     * the housekeeping block.  The daisy-chained outputs are effectively long-
     * haul as well, although they might get by with smaller buffers.
     */

    /* Buffer all of the outputs to the user block.  These don't need especially
     * high drive, but since the contents of the user project area are unknown,
     * use a reasonably large buffer to account for a wide variety of possible
     * use cases.
     */
    (* keep *)
    sg13cmos5l_buf_8 userbuffers [26:0] (
        // no. signals:  1, 1, 1, 24 = 27
        .A({proj_clk_unbuf, proj_ena_unbuf, proj_reset_unbuf, proj_dig_in_unbuf}),
        .X({proj_clk, proj_ena, proj_reset, proj_dig_in})
    );

    /* Buffer outputs to the switches.  These are relatively short-haul with
     * not much load at the destination.
     */
    (* keep *)
    sg13cmos5l_buf_4 switchbuffers [8:0] (
        // no. signals:  1, 1, 4, 2, 1 = 9
        .A({proj_3v3_ena_unbuf, proj_1v2_ena_unbuf, proj_analog_ena_unbuf,
		proj_ibias_ena_unbuf, proj_vbias_ena_unbuf}),
        .X({proj_3v3_ena, proj_1v2_ena, proj_analog_ena, proj_ibias_ena,
		proj_vbias_ena})
    );

    /* Instantiate buffers on the digital out lines going back to the
     * housekeeping module.  These are daisy-chained;  because the blocks
     * are oriented so that the buffer width subtracts from the project
     * height, each hop is only about 170 um, or ~21 fF of Metal3.
     *
     * buf_4 rather than buf_8:  measured on the post-PnR netlist against
     * extracted parasitics at nom_slow_1p08V_125C and a 21 fF load, the
     * dig_out_relay -> dig_out path is
     *     buf_4  0.309 ns    buf_8  0.337 ns    buf_16  0.395 ns
     * so buf_4 is ~27 ps/slot faster (about 0.5 ns over all 18 slots)
     * and 109 um2 smaller.  Upsizing is counterproductive here because
     * the buffer's input capacitance loads the mux2_1 driving it, and
     * that mux has a 4.87 ns/pF load slope.  buf_8 only overtakes buf_4
     * above roughly 70 fF, which would be a ~760 um hop.
     */
    (* keep *)
    sg13cmos5l_buf_4 outbuffers [11:0] (
        // no. signals:  12
        .A(dig_out_unbuf),
        .X(dig_out)
    );

    /* Instantiate the underlying circuit */

    user_project_control_base control_base (
	.proj_addr(proj_addr),
	.proj_sel(proj_sel),
	.clk(clk),
	.dig_ena(dig_ena),
	.enable(enable),
	.reset(reset),
	.select(select),
	.analog_ena(analog_ena),
	.ibias_ena(ibias_ena),
	.vbias_ena(vbias_ena),
	.power_3v3_ena(power_3v3_ena),
	.power_1v2_ena(power_1v2_ena),
	.dig_in(dig_in),
	.dig_out_relay(dig_out_relay),
	.dig_out(dig_out_unbuf),
	.proj_ena(proj_ena_unbuf),
	.proj_reset(proj_reset_unbuf),
	.proj_3v3_ena(proj_3v3_ena_unbuf),
	.proj_1v2_ena(proj_1v2_ena_unbuf),
	.proj_analog_ena(proj_analog_ena_unbuf),
	.proj_ibias_ena(proj_ibias_ena_unbuf),
	.proj_vbias_ena(proj_vbias_ena_unbuf),
	.proj_dig_out(proj_dig_out)
    );

endmodule
