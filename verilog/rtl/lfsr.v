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
 * LFSR PRNG
 *
 * Made from two LFSRs at two different long cycles, shifting in
 * opposite directions and XOR'd together.
 */ 

module lfsr_prng(
    input wire clk,		// PRNG clock
    input wire reset,		// PRNG reset
    output wire [15:0] prng_out	// PRNG output
);

reg  [19:0] lfsr_pipe1;
reg  [20:0] lfsr_pipe2;

// To do:  add an enable?  This does not even need to run if it is not
// selected for sequencer output.

always @(posedge clk or posedge reset) begin
    if (reset) begin
	lfsr_pipe1 <= 19'h6b5d3;
	lfsr_pipe2 <= 19'h4821e;
    end else begin
	lfsr_pipe2 <= {lfsr_pipe2[19:0], lfsr_pipe2[20] ^ lfsr_pipe2[18]}; 
	lfsr_pipe1 <= {lfsr_pipe1[18:0], lfsr_pipe1[19] ^ lfsr_pipe1[16]}; 
    end
end

assign prng_out = lfsr_pipe2[16 -: 16] ^ lfsr_pipe1[1 +: 16];

endmodule
