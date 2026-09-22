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
 * User project control definition
 * This is not the user project wrapper definition.  This block controls
 * signal access to and from the user project wrapper.
 */ 

/*
 * General architecture:
 *
 * Each project gets 24 digital input bits, 12 digital output bits.
 * There is 1 digital enable bit that connects the project to the
 *	shared 24-bit digital input bus and the shared 12-bit digital
 *	output bus.  This is a latching input that holds the value
 *	when released, so that all digital bits may be updated at
 *	once after programming the configuration into the SPI
 *	registers.
 * Each project gets 1 enable bit (not used for anything else).
 * Each project gets 1 reset bit (usage defined by the project).
 * There are 4 enable bits to individually connect to the four
 *	shared analog buses/pins.
 * There are 2 enable bits to individually connect to the two
 *	shared current biases.
 * There is 1 enable bit to individually connect to the
 *	shared voltage bias.
 * There is an enable for the 3.3V power switch
 * There is an enable for the 1.2V power switch
 *
 * Note that this block needs to be synthesizable and should be able
 * to service 18 analog project locations, so instead of supplying
 * the address to match as a parameter, the address to match is
 * hardwired outside of the block and passed as an input vector.
 */

module user_project_control_base (
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

    /* Wrapper-facing signals */
    output wire select,

    /* Project-facing signals */
    /* NOTE:  proj_clk is not generated here.  The gated clock is produced
     * by an explicitly instantiated clock-gating cell in the wrapper
     * module (user_project_control.v), along with all other technology
     * cells, so that this module remains technology-independent.
     */
    output wire proj_ena,
    output wire proj_reset,

    output wire proj_3v3_ena,
    output wire proj_1v2_ena,
    output wire [3:0] proj_analog_ena,
    output wire [1:0] proj_ibias_ena,
    output wire proj_vbias_ena,

    input wire [11:0] proj_dig_out	// 12 digital output bits from project
);

/* If the incoming address matches the defined project address of this
 * instance, then the corresponding project is selected.
 */

assign select = (proj_sel == proj_addr) ? 1'b1 : 1'b0;

/* Only one project is selected at a time.  Therefore the 12 digital
 * outputs are either taken from the project if selected, or repeated
 * from the neighboring slot if not.  The topmost slots must have
 * dig_out_relay = 12'h000.  Outputs travel down in two daisy chains
 * from the chip top, and are OR'd together in the housekeeping module.
 */ 

assign dig_out = (select & dig_ena) ? proj_dig_out : dig_out_relay;

/* Clock and enable. */

/* The gated project clock is generated in the wrapper module by a
 * sg13cmos5l_lgcp_1 integrated clock-gating cell driven by "select",
 * so a change in project selection cannot produce a runt pulse or a
 * spurious edge on proj_clk (which the old "select & clk" could do,
 * notably when clk happens to be stopped in the high state).
 *
 * The reset is still synchronized to the clock here.  Note that there
 * is no guarantee that a clock even exists, as some analog projects may
 * prefer to stop the clock to eliminate digital noise.  Therefore only
 * the reset signal is sync'd to the clock.  Projects that do not use a
 * clock should also not use the reset ("enable" can be used instead).
 */

reg [1:0] reset_sync;

always @(posedge clk or negedge enable) begin
    if (enable == 1'b0) begin
	reset_sync <= 2'b00;
    end else begin
	reset_sync <= {reset_sync[0], select & reset};
    end
end

assign proj_ena = select & enable;
assign proj_reset = reset_sync[1];

/* Analog and power switches */

assign proj_3v3_ena = select & power_3v3_ena;
assign proj_1v2_ena = select & power_1v2_ena;
assign proj_analog_ena[3] = select & analog_ena[3];
assign proj_analog_ena[2] = select & analog_ena[2];
assign proj_analog_ena[1] = select & analog_ena[1];
assign proj_analog_ena[0] = select & analog_ena[0];
assign proj_ibias_ena[1] = select & ibias_ena[1];
assign proj_ibias_ena[0] = select & ibias_ena[0];
assign proj_vbias_ena = select & vbias_ena;

endmodule
