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
 * Digital input and output router for the analog harness chip.
 *
 * Assigns the 12 shared digital pads on the chip, based on configuration
 * data from the housekeeping registers.
 *
 */ 

/*
 * General architecture:
 *
 * Each project gets 24 digital input bits, 12 digital output bits.
 *
 * Input bits can be taking from specific I/O pins to be routed in real time.
 * Output bits can be assigned to specific I/O pins to be routed in real time.
 * Note that there are 12 digital I/O pins available for either input or output,
 * which can be divided 6 and 6, 8 and 4, 12 and 0, etc.
 *
 * The SPI register definitions allow a pin to be assigned both to input and
 * output.  If this happens, then the pin is configured as an output (the input
 * is looped back from the pad).
 *
 * If the configuration attempts to route more than one signal to an output,
 * then the lowest numbered output is the one that is connected to that
 * signal.  One output signal, however, can be connected to more than one
 * output pin.
 *
 */

module router(
    input wire [11:0] io_in,		// Digital inputs from pads
    output wire [11:0] io_out,		// Digital outputs to pads
    output wire [11:0] io_oe,		// Bidirectional pad control
    input wire [11:0] dbus_in,		// Digital bus from user projects (status)
    output wire [23:0] dbus_out,	// Digital bus to user projects (control)

    /* Sequencer and SRAM routed values */
    input wire [7:0] sram_out,
    input wire [15:0] seq_out,
    input wire [1:0] strobe_out,

    /* Per-bit operational modes (from housekeeping registers) */
    input wire [95:0] user_in_route,	// pin assignments
    input wire [47:0] user_out_route, 	// pin assignments

    /* SRAM, strobe, and sequencer monitor settings (diagnostic) */
    input wire [7:0] sram_monitor,
    input wire [1:0] strobe_monitor,
    input wire [1:0] seq_monitor
);

/* Special functions bundled into 12 bits to match the digital out.
 * These special functions allow the SRAM bits to be routed to
 * digital outputs [7:0] and the sequencer and pattern generator
 * strobes to be routed to digital outputs [9:8] when configured.
 * This allows external use of the strobes for triggering based on
 * the sequencer or pattern looping, or one or more bits can be
 * set up in the SRAM to present as triggers on the digital outputs.
 */
wire [11:0] spec_func;
wire [11:0] spec_ena;

assign spec_func = {2'b00, strobe_out, sram_out};
assign spec_ena  = {2'b00, strobe_monitor, sram_monitor};

/* Multiplexed outputs---Assign data bus and pins according to bit modes */

genvar i;

generate
for (i = 0; i < 12; i = i + 1) begin : out_mux
    assign io_out[i] =
	(seq_monitor[0] == 1'b1) ? seq_out[i] :
	(seq_monitor[1] == 1'b1) ? seq_out[i + 4] :
	(spec_ena[i] == 1'b1) ? spec_func[i] :
	(user_out_route[0*4 +: 4] == i) ? dbus_in[0] :
	(user_out_route[1*4 +: 4] == i) ? dbus_in[1] :
	(user_out_route[2*4 +: 4] == i) ? dbus_in[2] :
	(user_out_route[3*4 +: 4] == i) ? dbus_in[3] :
	(user_out_route[4*4 +: 4] == i) ? dbus_in[4] :
	(user_out_route[5*4 +: 4] == i) ? dbus_in[5] :
	(user_out_route[6*4 +: 4] == i) ? dbus_in[6] :
	(user_out_route[7*4 +: 4] == i) ? dbus_in[7] :
	(user_out_route[8*4 +: 4] == i) ? dbus_in[8] :
	(user_out_route[9*4 +: 4] == i) ? dbus_in[9] :
	(user_out_route[10*4 +: 4] == i) ? dbus_in[10] :
	(user_out_route[11*4 +: 4] == i) ? dbus_in[11] :
	1'b0;

    /* Output enables:  Take precedence over input configuration */
    assign io_oe[i] =
	(seq_monitor != 2'b00) ? 1'b1 :
	((user_out_route[0*4 +: 4] == i) ||
	(user_out_route[1*4 +: 4] == i) || (user_out_route[2*4 +: 4] == i) || 
	(user_out_route[3*4 +: 4] == i) || (user_out_route[4*4 +: 4] == i) ||
	(user_out_route[5*4 +: 4] == i) || (user_out_route[6*4 +: 4] == i) ||
	(user_out_route[7*4 +: 4] == i) || (user_out_route[8*4 +: 4] == i) ||
	(user_out_route[9*4 +: 4] == i) || (user_out_route[10*4 +: 4] == i) ||
	(user_out_route[11*4 +: 4] == i)) ? 1'b1 : spec_ena[i]; 

end

for (i = 0; i < 16; i = i + 1) begin : in_mux1
    /* Input assignments */
    assign dbus_out[i] =
	(user_in_route[i*4 +: 4] == 4'h0) ? io_in[0] :
	(user_in_route[i*4 +: 4] == 4'h1) ? io_in[1] :
	(user_in_route[i*4 +: 4] == 4'h2) ? io_in[2] :
	(user_in_route[i*4 +: 4] == 4'h3) ? io_in[3] :
	(user_in_route[i*4 +: 4] == 4'h4) ? io_in[4] :
	(user_in_route[i*4 +: 4] == 4'h5) ? io_in[5] :
	(user_in_route[i*4 +: 4] == 4'h6) ? io_in[6] :
	(user_in_route[i*4 +: 4] == 4'h7) ? io_in[7] :
	(user_in_route[i*4 +: 4] == 4'h8) ? io_in[8] :
	(user_in_route[i*4 +: 4] == 4'h9) ? io_in[9] :
	(user_in_route[i*4 +: 4] == 4'ha) ? io_in[10] :
	(user_in_route[i*4 +: 4] == 4'hb) ? io_in[11] :
	(user_in_route[i*4 +: 4] == 4'hd) ? 1'b0 :
	(user_in_route[i*4 +: 4] == 4'he) ? 1'b1 :
	(user_in_route[i*4 +: 4] == 4'hf) ? seq_out[i] :
	1'b0;
end

for (i = 16; i < 24; i = i + 1) begin : in_mux2
    /* Input assignments */
    assign dbus_out[i] =
	(user_in_route[i*4 +: 4] == 4'h0) ? io_in[0] :
	(user_in_route[i*4 +: 4] == 4'h1) ? io_in[1] :
	(user_in_route[i*4 +: 4] == 4'h2) ? io_in[2] :
	(user_in_route[i*4 +: 4] == 4'h3) ? io_in[3] :
	(user_in_route[i*4 +: 4] == 4'h4) ? io_in[4] :
	(user_in_route[i*4 +: 4] == 4'h5) ? io_in[5] :
	(user_in_route[i*4 +: 4] == 4'h6) ? io_in[6] :
	(user_in_route[i*4 +: 4] == 4'h7) ? io_in[7] :
	(user_in_route[i*4 +: 4] == 4'h8) ? io_in[8] :
	(user_in_route[i*4 +: 4] == 4'h9) ? io_in[9] :
	(user_in_route[i*4 +: 4] == 4'ha) ? io_in[10] :
	(user_in_route[i*4 +: 4] == 4'hb) ? io_in[11] :
	(user_in_route[i*4 +: 4] == 4'hd) ? 1'b0 :
	(user_in_route[i*4 +: 4] == 4'he) ? 1'b1 :
	(user_in_route[i*4 +: 4] == 4'hf) ? sram_out[i - 16] :
	1'b0;
end
endgenerate

endmodule
