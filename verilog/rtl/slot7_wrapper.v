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
 * User project wrapper for slot 7.
 *
 * One wrapper per slot rather than one per distinct pin count, so that a
 * slot can be changed independently:  if a designer asks for a different
 * I/O cell than the default on a dedicated pin, only this file changes.
 *
 * The number of dedicated analog pins is fixed per slot by the padframe
 * and is taken from config.txt (the sN_an[] entries).  This slot has 2,
 * both custom pads (see below).
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

module slot7_wrapper (
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

    /* Dedicated analog pads.
     *
     * These are plain wires, not reals, unlike every other analog
     * port here.  The bias, bus and supply ports carry a value the
     * harness computes through a switch or a power gate, which is
     * the thing worth modelling;  a dedicated pad runs straight to
     * the bond pad with nothing in between, so there is no value to
     * compute and a real would only invite the silent wire/real
     * coercion warned about above.
     *
     * The names match the layout and the documented chip pinout,
     * which is also what LVS compares against.
     */
    /* Custom pads (config.txt):  s7_an[0] = sg13cmos5l_IOPadSingle2Diff
     * (core signal s7_an_0), s7_an[1] = sg13cmos5l_IOPadDiff2Single
     * (core signal s7_an_1).  One port per core-side pad pin, named
     * <core signal>_<pad pin> (scripts/parse_config.py CUSTOM_PADS).
     * The pads themselves (s7_an[1:0]) are not core ports any more.
     * Plain wires, for the same reason as the dedicated pads above.
     */
    inout wire s7_an_0_vref,	// S2D output common-mode reference
    inout wire s7_an_0_outp,	// S2D differential output +
    inout wire s7_an_0_outn,	// S2D differential output -
    inout wire s7_an_0_vcm,	// S2D output common mode
    inout wire s7_an_0_en_3v3,	// S2D enable (3.3 V)
    inout wire s7_an_0_en_3v3_b,	// S2D enable complement (3.3 V)
    inout wire s7_an_0_iref,	// S2D bias current (sourced)
    inout wire s7_an_1_vinp,	// D2S differential input +
    inout wire s7_an_1_vinn,	// D2S differential input -
    inout wire s7_an_1_vref,	// D2S output reference
    inout wire s7_an_1_iref,	// D2S bias current (sourced)
    inout wire s7_an_1_en_3v3_b,	// D2S enable complement (3.3 V)
    inout wire s7_an_1_en_3v3,	// D2S enable (3.3 V)
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
