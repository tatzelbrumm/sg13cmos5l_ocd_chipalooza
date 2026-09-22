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

/* This module implements a simple interface between the housekeeping
 * block and the SRAM.  The housekeeping block assumes a 1024-word (1k)
 * depth memory with 8 bit data input and output.  However, the SRAM
 * itself can have a different arrangement of the same number of bits.
 * This interface translates between the two.
 */

`timescale 1ns/10ps
`celldefine

module sram_interface (
    input wire [9:0] sram_addr_hk,		/* 10-bit addressing */
    input wire [7:0] sram_idata_hk,		/* 8-bit data input */
    output wire [7:0] sram_odata_hk,		/* 8-bit data output */

    output wire [7:0] sram_addr,		/* 8-bit addressing */
    output wire [31:0] sram_idata,		/* 32-bit data input */
    input wire [31:0] sram_odata,		/* 32-bit data output */
    output wire [31:0] sram_bitmask		/* 32-bit data bitmask */
);

    wire [1:0] bytesel;

    /* Lower bits of the address translate to the byte selection */
    assign bytesel = sram_addr_hk[1:0];

    /* Upper bits of the address translate to the SRAM address */
    assign sram_addr = sram_addr_hk[9:2];

    /* Output is muxed depending on the lower 2 address bits */
    assign sram_odata_hk = (bytesel == 2'b11) ? sram_odata[31:24] :
			   (bytesel == 2'b10) ? sram_odata[23:16] :
			   (bytesel == 2'b01) ? sram_odata[15:8] :
 			   sram_odata[7:0];

    /* Input is shifted depending on the lower 2 address bits */
    assign sram_idata = (bytesel == 2'b11) ? {sram_idata_hk, 24'h000000} :
			(bytesel == 2'b10) ? {8'h00, sram_idata_hk, 16'h0000} :
			(bytesel == 2'b01) ? {16'h0000, sram_idata_hk, 8'h00} :
			{24'h000000, sram_idata_hk};

    /* Bitmask (for writing) is muxed depending on the lower 2 address bits */
    assign sram_bitmask = (bytesel == 2'b11) ? 32'hff000000 :
			  (bytesel == 2'b10) ? 32'h00ff0000 :
			  (bytesel == 2'b01) ? 32'h0000ff00 :
					       32'h000000ff;

endmodule
