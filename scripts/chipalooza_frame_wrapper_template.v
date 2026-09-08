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
 *-------------------------------------------------------------------------
 * chipalooza_frame_wrapper ---
 *
 * RTL verilog definition of the user project area for the open-frame
 * version of the Caravel harness chip, IHP SG13CMOS5L process, dual voltage
 * (1.2V core, 3.3V pad) padframe.
 *
 * Written by Tim Edwards
 * February 2026
 * Updated September 2026
 *
 * TEMPLATE_MESSAGE
 *-------------------------------------------------------------------------
 */

// `default_nettype none

module chipalooza_frame_wrapper (
	`ifdef USE_POWER_PINS
		// Power buses
		inout  vddio,	// Core 5.0V supply
		inout  vssio,	// Core 5.0V ground
		inout  vccd,	// Core 3.3V supply
		inout  vssd,	// Core 3.3V ground
	`endif

	// Core infrastructure (padframe-facing pins)

	INPUT_OUTPUT_LIST

	output SDO,
	output sdoena,
	input  SDI,
	input  CSB,
	input  SCK,
	input  clk,
	input [11:0] gpio,
	inout [3:0] analog,
	input  porb,
	input  [31:0] mask_rev
);

	// Declare a user project by defining HAS_USER_PROJECT
	// and specifying the "netlists.v" file to include the
	// RTL source code for it.

	`ifdef HAS_USER_PROJECT

	    /* The user is responsible for defining the user project
	     * instance and connecting the appropriate signals.  The
	     * user project itself is normally a schematic.
	     */

	`endif

endmodule
// `default_nettype wire
