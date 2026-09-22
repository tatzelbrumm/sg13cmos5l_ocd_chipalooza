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
 * User project wrapper for slot 16.
 *
 * One wrapper per slot rather than one per distinct pin count, so that a
 * slot can be changed independently:  if a designer asks for a different
 * I/O cell than the default on a dedicated pin, only this file changes.
 *
 * The number of dedicated analog pins is fixed per slot by the padframe
 * and is taken from config.txt (the sN_an[] entries).  This slot has 2.
 *
 * ANALOG PORTS ARE SCALAR "real", ONE PER LINE.  This looks verbose next
 * to a packed bus, and it is the only form that works:
 *
 *   - "real" is not a vector type, so "input real [3:0] x" is a syntax
 *     error.  An unpacked array ("input real x [0:3]") compiles but
 *     silently passes zeros through the port, and slicing an unpacked
 *     array into a port is rejected outright ("Array slices are not yet
 *     supported").  Scalars are what actually carries a value.
 *   - Direction is "input" rather than "inout" because iverilog rejects
 *     a real inout port, and because the behavioural switch models are
 *     unidirectional:  a real has no high-impedance state, and two
 *     drivers on one real is an elaboration error.  These therefore
 *     model the pad-to-project direction.  The reverse direction is
 *     modelled in digital_top by a resolving mux, not by these ports.
 *   - Do NOT connect a real to a "wire" port or vice versa:  iverilog
 *     coerces silently, so a 3.3 V rail arrives as 1.0 with no warning.
 *
 * The gated supplies are real for the same reason:  their voltage is
 * what the power gate controls, and it is the thing worth checking.
 */

module slot16_wrapper (
`ifdef USE_POWER_PINS
    input real vdd_3v3,		// 3.3V gated power (NaN when gated off)
    input real vdd_1v2,		// 1.2V gated power (NaN when gated off)
    inout wire vss_3v3,
    inout wire vss_1v2,
`endif

    input wire enable,		// project enable
    input wire clk,		// shared external clock
    input wire reset,		// digital reset

    input  wire [23:0] dig_in,	// 24 digital bit shared bus
    output wire [11:0] dig_out,	// 12 digital bit shared bus

    /* Analog I/O.  See the note above on why these are scalar reals. */
    input real analog_pin0,	// dedicated analog pin 0
    input real analog_pin1,	// dedicated analog pin 1
    input real ibias0,		// shared current bias 0
    input real ibias1,		// shared current bias 1
    input real vbias,		// shared voltage bias

    input real analog_bus0,	// shared analog bus line 0
    input real analog_bus1,	// shared analog bus line 1
    input real analog_bus2,	// shared analog bus line 2
    input real analog_bus3	// shared analog bus line 3
);

/* Instantiate and wire up the user project analog circuit here */

endmodule
