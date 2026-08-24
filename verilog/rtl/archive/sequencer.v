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
 * Digital sequencer for the analog harness chip.
 * Enhances the test capability of the harness chip by allowing sequences
 * of vectors to be placed on the control bus at regular clocked intervals.
 * Also allows digital output pins to be set, synchronized to the internal
 * bus updates.
 *
 * Requires a 1024x8 (?) SRAM to store arbitrary vectors.  Also allows
 * binary and grayscale up/down counts, walking ones/zeros, and pseudorandom
 * sequences from an LFSR.
 */ 

/*
 * General architecture:
 *
 * Each project gets 24 digital input bits, 8 digital output bits.
 * The sequencer is set up to assign each project input bit to a function,
 * where the functions are:
 *
 * 0) Constant 0
 * 1) Constant 1
 * 2) Counter/Function (up to 16 bits may be assigned to this), or
 *    Arbitrary value from memory (up to 8 bits may be assigned to this)
 * 3) (unused?)
 * 4-15) Pass-through from I/O pin (up to 12 bits)
 *
 * To avoid a huge crossbar switch, the counter/function bits are assigned
 * directly to project bits 0-15 and the SRAM output is assigned directly to
 * project bits 16-23.  It is the responsibility of the project designer to
 * ensure that these connect to the right locations in the project.
 *
 * Output bits can be assigned to specific I/O pins to be routed in real time.
 * (up to 8 bits).  Note that there are 12 digital I/O pins available for either
 * input or output, which can be divided 6 and 6, 8 and 4, 10 and 2, etc.
 *
 * An output pin can also be assigned to signal a pulse on a counter/function
 * start or restart, or assigned to a memory bit (up to 12 memory bits can be
 * assigned to 12 digital output pins).
 *
 * Each counter/function operates based on the number of bits assigned
 * to it, and may be set to do the following:
 *
 * 0) Binary up count
 * 1) Binary down count
 * 2) Grayscale up count
 * 3) Grayscale down count
 * 4) Pseudorandom values
 * 5) Constant zero (sequencer off)
 * 6) Constant one (sequencer off)
 *
 * The counter/function generator only needs to support sequences which are
 * longer than the depth of the memory block;  e.g., there is not enough
 * memory to hold a 16-bit count.  For all short sequence types, such as a
 * pulse, walking ones, walking zeros, etc., use the arbitrary sequence
 * generator.
 *
 * The arbitrary sequence generator with constant time steps walks through
 * memory.  The first memory location holds the count at which the sequence
 * recycles.  A memory value of all ones at the 1st location past the end of
 * the sequence indicates a one-shot.
 *
 * The arbitrary sequence generator with variable time steps uses every
 * other memory location to store the bit pattern, and the locations in
 * between store a clock count indicating the delay before the next step in
 * the sequence.  The first memory value is interpreted the same way as for
 * the constant-delay sequence.
 *
 * A separate counter counts intervals between steps.  For the variable time
 * step sequencer, the variable time is multiplied by the interval counter.
 *
 * The housekeeping SPI contains registers for the interval timer, the
 * function per bit, and sequencer start and stop controls.
 */

module sequencer(
    input wire        clk,		// Sequencer clock
    input wire 	      reset,		// Sequencer reset
    output reg [15:0] seq_out,		// Sequencer output
    input wire [2:0]  seq_mode,		// sequencer modes
    input wire	      loop_mode,	// loop or one-shot

    /* Note:  The SRAM write cycles are controlled from housekeeping.  The
     * sequencer only reads from SRAM.
     */
    output [9:0] sram_addr,	// SRAM address (10 bits)
    input [7:0] sram_data	// data in from SRAM
);

wire [15:0] seq_out_more;
wire [15:0] seq_out_less;
wire [15:0] lfsr_out;

assign seq_out_more = seq_out + 1;
assign seq_out_less = seq_out - 1;

always @(posedge clk or posedge reset) begin
    if (reset) begin
	seq_out <= 16'd0;
    end else begin
    	case (seq_mode)
	3'b000: begin
	    seq_out <= seq_out_more;	// Binary up count
	end
	3'b001: begin
	    seq_out <= seq_out_less;	// Binary down count
	end
	3'b010: begin
	    seq_out <= (seq_out_more) ^ ((seq_out_more) >> 1);	// Grayscale up count
	end
	3'b011: begin
	    // Grayscale down count
	    seq_out <= (seq_out_less) ^ ((seq_out_less) >> 1);	// Grayscale up count
	end
	3'b100: begin
	    seq_out <= lfsr_out;	// Pseudorandom LFSR output
	end
	3'b101: begin
	    seq_out <= 16'h0000;
	end
	3'b110: begin
	    seq_out <= 16'hffff;
	end
	3'b111: begin
	    /* Unassigned or TBD */
	end
	endcase
    end
end

/* Instantiation of the LFSR */

lfsr_prng lfsr_prng (
    .clk(clk),
    .reset(reset),
    .prng_out(lfsr_out)
);

endmodule
