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
/* 
 *---------------------------------------------------------------------
 * A simple module that generates buffered high and low outputs
 * in the 1.8V domain.
 *---------------------------------------------------------------------
 */

module constant_block (
    `ifdef USE_POWER_PINS
         inout vdd,
         inout vss,
    `endif

    output	 one,
    output	 zero
);

    wire	one_unbuf;
    wire	zero_unbuf;

    sg13cmos5l_tiehi const_one (
`ifdef USE_POWER_PINS
            .VDD(vdd),
            .VSS(vss),
`endif
            .L_HI(one_unbuf)
    );

    sg13cmos5l_tielo const_zero (
`ifdef USE_POWER_PINS
            .VDD(vdd),
            .VSS(vss),
`endif
            .L_LO(zero_unbuf)
    );

    /* Buffer the constant outputs (could be synthesized) */

    sg13cmos5l_buf_8 const_one_buf (
`ifdef USE_POWER_PINS
            .VDD(vdd),
            .VSS(vss),
`endif
            .A(one_unbuf),
            .X(one)
    );

    sg13cmos5l_buf_8 const_zero_buf (
`ifdef USE_POWER_PINS
            .VDD(vdd),
            .VSS(vss),
`endif
            .A(zero_unbuf),
            .X(zero)
    );

    /* For LVS purposes, enumerate the decap cells */

`ifdef LVS
    sg13cmos5l_decap_4 const_decap [3:0] (
    `ifdef USE_POWER_PINS
            .VDD(vdd),
            .VSS(vss)
    `endif
    );
`endif

endmodule
`default_nettype wire
