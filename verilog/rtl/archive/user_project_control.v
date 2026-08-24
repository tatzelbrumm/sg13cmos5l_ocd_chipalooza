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
 *
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
 * There are 3 enable bits to individually connect to the three
 *	shared analog buses/pins.
 * There are 2 enable bits to individually connect to the two
 *	shared current biases.
 * There is 1 enable bit to individually connect to the
 *	shared voltage bias.
 * There is an enable for the 3.3V power switch
 * There is an enable for the 1.2V power switch
 */

module user_project_control #(
    .PROJ_ADDRESS(5'h0)
) (
    /* Infrastructure-facing signals */

    input wire [4:0] proj_sel,		// Selected project
    input wire clk,			// Master system clock
    input wire dig_ena,			// Digital connect enable
    input wire enable,			// Enable signal for project
    input wire [2:0] analog_ena,	// analog bus enables
    input wire [1:0] ibias_ena,		// Current bias enables
    input wire vbias_ena,		// Voltage bias enable
    input wire power_3v3_ena,		// 3.3V power gate switch enable
    input wire power_1v2_ena,		// 1.2V power gate switch enable

    input  wire [23:0] dig_in,		// 24 digital bit shared bus
    output wire [11:0] dig_out,		// 12 digital bit shared bus

    /* Project-facing signals */

    output wire proj_clk,
    output wire proj_ena,

    output wire proj_3v3_ena,
    output wire proj_1v2_ena,
    output wire [2:0] proj_analog_ena,
    output wire [1:0] proj_ibias_ena,
    output wire proj_vbias_ena,

    /* Per-bit operational modes (from housekeeping registers) */
    output wire [23:0] proj_dig_in,	// 24 digital input bits to project
    input wire [11:0] proj_dig_out	// 12 digital output bits from project
);

/* If the incoming address matches the defined project address of this
 * instance, then the corresponding project is selected.
 */
wire select;

assign select = (proj_sel == PROJ_ADDRESS) ? 1'b1 : 1'b0;

/* Outputs are high impedence when project is not enabled.
 * Inputs are zero when project is not enabled.
 */ 

assign dig_out = (select & proj_dig_ena) ? proj_dig_out : 12'bz;

/* TO BE DONE: proj_dig_ena should act as a latch---Use latches
 * (or can the synthesis tools infer a latch?)
 */
assign dig_in = select & proj_dig_ena & proj_dig_in;

/* Clock and enable */

assign proj_clk = select & clk;
assign proj_ena = select & enable;

/* Analog and power switches */

assign proj_3v3_ena = select & power_3v3_enable;
assign proj_1v2_ena = select & power_1v2_enable;
assign proj_analog_ena[2] = select & analog_ena[2];
assign proj_analog_ena[1] = select & analog_ena[1];
assign proj_analog_ena[0] = select & analog_ena[0];
assign proj_ibias_ena[1] = select & ibias_ena[1];
assign proj_ibias_ena[0] = select & ibias_ena[0];
assign proj_vbias_ena = select & vbias_ena;

endmodule
