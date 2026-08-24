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

`default_nettype none
// This module represents an unprogrammed mask revision
// block that is configured with via programming on the
// chip top level.  This value is passed to the block as
// a parameter

module user_id_programming #(
    parameter USER_PROJECT_ID = 32'h20260330
) (
`ifdef USE_POWER_PINS
    inout VDD,
    inout VSS,
`endif
    output wire [31:0] mask_rev
);
    wire [31:0] user_proj_id_high;
    wire [31:0] user_proj_id_low;

    // For the mask revision input, use an array of digital constant logic cells
    // These must be manually placed in pairs, always in the same order.

    sg13cmos5l_tiehi mask_rev_value_one [31:0] (
`ifdef USE_POWER_PINS
	    .VDD(VDD),
	    .VSS(VSS),
`endif
            .L_HI(user_proj_id_high)
    );

    sg13cmos5l_tielo mask_rev_value_zero [31:0] (
    `ifdef USE_POWER_PINS
	    .VDD(VDD),
	    .VSS(VSS),
    `endif
            .L_LO(user_proj_id_low)
    );

    /* Replacing the assignment with a hard-coded connection
     * until netgen can be made to understand the RHS expression
     * as structural verilog.
     */
    // genvar i;
    // generate
    //	for (i = 0; i < 32; i = i+1) begin
    //	    assign mask_rev[i] = (USER_PROJECT_ID & (32'h01 << i)) ?
    //		user_proj_id_high[i] : user_proj_id_low[i];
    //	end
    // endgenerate

    assign mask_rev[31] = user_proj_id_low[31];  /* 0 */
    assign mask_rev[30] = user_proj_id_low[30];  /* 0 */
    assign mask_rev[29] = user_proj_id_high[29]; /* 1 */
    assign mask_rev[28] = user_proj_id_low[28];  /* 0 */
    assign mask_rev[27] = user_proj_id_low[27];  /* 0 */
    assign mask_rev[26] = user_proj_id_low[26];  /* 0 */
    assign mask_rev[25] = user_proj_id_low[25];  /* 0 */
    assign mask_rev[24] = user_proj_id_low[24];  /* 0 */
    assign mask_rev[23] = user_proj_id_low[23];  /* 0 */
    assign mask_rev[22] = user_proj_id_low[22];  /* 0 */
    assign mask_rev[21] = user_proj_id_high[21]; /* 1 */
    assign mask_rev[20] = user_proj_id_low[20];  /* 0 */
    assign mask_rev[19] = user_proj_id_low[19];  /* 0 */
    assign mask_rev[18] = user_proj_id_high[18]; /* 1 */
    assign mask_rev[17] = user_proj_id_high[17]; /* 1 */
    assign mask_rev[16] = user_proj_id_low[16];  /* 0 */
    assign mask_rev[15] = user_proj_id_low[15];  /* 0 */
    assign mask_rev[14] = user_proj_id_low[14];  /* 0 */
    assign mask_rev[13] = user_proj_id_low[13];  /* 0 */
    assign mask_rev[12] = user_proj_id_low[12];  /* 0 */
    assign mask_rev[11] = user_proj_id_low[11];  /* 0 */
    assign mask_rev[10] = user_proj_id_low[10];  /* 0 */
    assign mask_rev[9] = user_proj_id_high[9];   /* 1 */
    assign mask_rev[8] = user_proj_id_high[8];   /* 1 */
    assign mask_rev[7] = user_proj_id_low[7];    /* 0 */
    assign mask_rev[6] = user_proj_id_low[6];    /* 0 */
    assign mask_rev[5] = user_proj_id_high[5];   /* 1 */
    assign mask_rev[4] = user_proj_id_high[4];   /* 1 */
    assign mask_rev[3] = user_proj_id_low[3];    /* 0 */
    assign mask_rev[2] = user_proj_id_low[2];    /* 0 */
    assign mask_rev[1] = user_proj_id_low[1];    /* 0 */
    assign mask_rev[0] = user_proj_id_low[0];    /* 0 */

`ifdef LVS
    /* Enumerate the decap cells for LVS only */

    sg13cmos5l_decap_4 user_id_decap [37:0] (
    `ifdef USE_POWER_PINS
            .VDD(VDD),
            .VSS(VSS)
    `endif
    );
`endif

endmodule
`default_nettype wire
