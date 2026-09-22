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
 * Each project gets 1 enable bit (not used for anything else).  This goes
 *	directly to the project and is not represented here.
 * There is 1 digital enable bit that connects the project to the
 *	shared 24-bit digital input bus and the shared 12-bit digital
 *	output bus.
 * There are 4 enable bits to individually connect to the three
 *	shared analog buses/pins.
 * There is an enable for the 3.3V power switch
 * There is an enable for the 1.2V power switch
 */

module user_project_wrapper_4a (
`ifdef USE_POWER_PINS
    inout wire vdd_3v3,		// 3.3V gated power
    inout wire vdd_1v2,		// 1.2V gated power
    inout wire vss_3v3,
    inout wire vss_1v2,
`endif

    input wire enable,		// project enable
    input wire clk,		// shared external clock
    input wire reset,		// digital reset
    
    input  wire [23:0] dig_in,	// 24 digital bit shared bus
    output wire [11:0]  dig_out, // 12 digital bit shared bus

    // Analog I/O (here marked as verilog wires)

    inout wire [3:0] analog_pin, // project dedicated analog pins (4)
    input wire [1:0] ibias, 	// shared current biases
    input wire	     vbias,	// shared voltage bias
  
    inout wire [3:0] analog_bus	// shared analog busses
);

/* Instantiate and wire up user project analog circuit here */

endmodule
