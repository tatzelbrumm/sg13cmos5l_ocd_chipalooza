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
 * Arbitrary value digital sequencer for the analog harness chip.
 * Enhances the test capability of the harness chip by allowing sequences
 * of vectors to be placed on the control bus at regular clocked intervals.
 * Requires a 1024x8 SRAM to store arbitrary vectors.
 */ 

/*
 * General architecture:
 *
 * Each project gets 24 digital input bits, 12 digital output bits.
 * The housekeeping block assigns each project input bit to a function.
 * 16 of the digital input bits come from a sequencer/counter, and
 * the other 8 (bits 16-23) are arbitrary data from an SRAM.
 * It is the responsibility of the project designer to ensure that these
 * connect to the right locations in the project.
 *
 * The arbitrary pattern generator with constant time steps walks through
 * memory.  The first memory location holds the count at which the sequence
 * recycles.  A memory value of all ones at the 1st location past the end of
 * the sequence indicates a one-shot.
 *
 * The arbitrary pattern generator with variable time steps uses every
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

module pattern(
    input wire        clk,		// Sequencer clock
    input wire 	      reset,		// Sequencer reset
    input wire	      sync_reset,	// Syncronous reset
    input wire [7:0]  prescaler,	// Clock prescaler count
    input wire	      loop_mode,	// loop or one-shot
    input wire	      strobe_in,	// strobe from counter/sequencer

    /* Note:  The SRAM write cycles are controlled from housekeeping.  The
     * sequencer only reads from SRAM, and only provides the address.
     */
    input wire [1:0] sram_mode,	// SRAM mode (when to increment SRAM address)
    input wire [9:0] sram_stop_addr,	// stop address when auto-incrementing
    input wire [7:0] sram_data_in,
    output reg [7:0] sram_data_out,
    output reg [9:0] sram_addr,	// SRAM address (10 bits)
    output reg       strobe_out	// strobe output on loop or end
);

reg  [1:0]  ena_pipe;	// startup behavior
reg	    pat_end;	// halts pattern generator at end if not looping
reg  [7:0]  count;	// prescaler counter
reg  [7:0]  timer;	// interval timer
wire	    enabled;	// enable signal (level)
reg  [2:0]  state;	// state for variable length patterns

`define IDLE	    3'b000
`define DATA_LATCH  3'b001
`define INCR_ADDR_1 3'b010
`define TIMER_LATCH 3'b011
`define INCR_ADDR_2 3'b100

assign enabled = ena_pipe[1] && ~pat_end;

// NOTE:  Sequencer runs when the clock is activated.  When the clock
// is deactivated, the sequencer is effectively paused.  A reset pulse
// will reset the sequencer to the default state.

always @(posedge clk or posedge reset) begin
    if (reset) begin
	sram_addr <= 10'd0;
	strobe_out <= 1'b0;
	pat_end <= 1'b0;
	timer <= 8'b0;
	state <= `IDLE;
	count <= 8'b0;
	ena_pipe <= 2'b00;
    end else if (sync_reset) begin
	sram_addr <= 10'd0;
	strobe_out <= 1'b0;
	pat_end <= 1'b0;
	timer <= 8'b0;
	state <= `IDLE;
	count <= 8'h00;
	ena_pipe <= 2'b00;
    end else begin
	ena_pipe <= {ena_pipe[0], 1'b1};

	if (sram_mode == 2'b10) begin
	    count <= {7'h00, ~strobe_in};
	end else begin
	    if (count < prescaler) begin
	        count <= count + 1;
	    end else begin
	        count <= 8'h00;
	    end
	end

	if (sram_mode == 2'b01) begin
	    /* Mode 1:  Read data and timer values from SRAM, output the data,
	     * and wait for the timer interval times the prescaler before
	     * fetching the next data.
     	     */
	    if (state == `IDLE) begin
	        if ((timer == 8'h00) && (count == 8'h00) && (enabled == 1'b1)) begin
		    state <= `DATA_LATCH;
	        end else if ((count == 8'h00) && (enabled == 1'b1)) begin
		    timer <= timer - 1;
		end
	    end else if (state == `DATA_LATCH) begin
		sram_data_out <= sram_data_in;
		state <= `INCR_ADDR_1;
	    end else if (state == `INCR_ADDR_1) begin
		sram_addr <= sram_addr + 1;
		state <= `TIMER_LATCH;
	    end else if (state == `TIMER_LATCH) begin
		timer <= sram_data_in;
		state <= `INCR_ADDR_2;
	    end else if (state == `INCR_ADDR_2) begin
		if (sram_addr >= sram_stop_addr) begin
		    strobe_out <= 1'b1;
		    if (loop_mode == 1'b1) begin
			sram_addr <= 1'b0;
		    end else begin
			pat_end <= 1'b1;
		    end
		end else begin
		    sram_addr <= sram_addr + 1;
		    strobe_out <= 1'b0;
		end
		state <= `IDLE;
	    end
	end else begin
	    /* Mode 0:  Increment address every (prescaled) clock
	     * Mode 2:  Increment address every sequencer cycle
	     */
	    sram_data_out <= sram_data_in;
	    if (count == 8'h00) begin
	        if (enabled == 1'b1) begin
		    if (sram_addr == sram_stop_addr) begin
		        strobe_out <= 1'b1;
		        if (loop_mode == 1'b1) begin
			    sram_addr <= 8'h00;
		        end else begin
			    pat_end <= 1'b1;
			end
		    end else begin
		        sram_addr <= sram_addr + 1;
		        strobe_out <= 1'b0;
		    end
	        end
	    end
	end
    end
end

endmodule
