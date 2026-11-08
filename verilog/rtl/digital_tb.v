/*
 * Testbench for digital subsystem simulation
 */

`include "sim_defs.v"			// Includes all the other files

module digital_tb ();

    /* Define inputs to the digital top module */

    reg SCK, SDI, CSB;
    reg clk;
    wire SDO, sdo_ena;
    reg [31:0] mask_rev_in;
    reg [11:0] io_in;
    wire [11:0] io_out;
    wire [11:0] io_oe;

    `ifdef USE_POWER_PINS
	reg AVDD, AVSS, DVDD, DVSS;
    `endif

    integer i;
    reg [7:0] tbdata;

    /* Define tasks for SPI functions */
    task start_csb;
	begin
	    SCK <= 1'b0;
	    SDI <= 1'b0;
	    CSB <= 1'b0;
	    #50;
	end
    endtask

    task end_csb;
	begin
	    SCK <= 1'b0;
	    SDI <= 1'b0;
	    CSB <= 1'b1;
	    #50;
	end
    endtask

    task write_byte;
	input [7:0] odata;
	begin
	    SCK <= 1'b0;
	    for (i = 7; i >= 0; i--) begin
		#50;
	 	SDI <= odata[i];
		#50;
		SCK <= 1'b1;
		#100;
		SCK <= 1'b0;
	    end
	end
    endtask

    task read_byte;
	output [7:0] idata;
	begin
	    SCK <= 1'b0;
	    SDI <= 1'b0;
	    for (i = 7; i >= 0; i--) begin
		#50;
	 	idata[i] = SDO;
		#50;
		SCK <= 1'b1;
		#100;
		SCK <= 1'b0;
	    end
	end
    endtask

    task read_write_byte (
	input [7:0] odata,
	output [7:0] idata);
	begin
	    SCK <= 1'b0;
	    for (i = 7; i >= 0; i--) begin
		#50;
		SDI <= odata[i];
		idata[i] = SDO;
		#50;
		SCK <= 1'b1;
		#100;
		SCK <= 1'b0;
	    end
	end
    endtask

    /* Set the register initial values */
    initial begin 
	$dumpfile("digital_tb.vcd");
	$dumpvars(0, digital_tb);

	`ifdef USE_POWER_PINS
	AVDD <= 1'b1;
	AVSS <= 1'b0;
	DVDD <= 1'b1;
	DVSS <= 1'b0;
	`endif

	SCK <= 1'b0;
	SDI <= 1'b0;
	CSB <= 1'b1;	// SPI disabled
	clk <= 1'b0;
	mask_rev_in <= 32'hdeadbeef;
	io_in <= 12'h000;

	/* Wait out the on-chip POR (POR_DELAY_NS = 1 us by default),
	 * then let the released reset propagate. */
	#1000;
	#1000;
	if (harness_core.porb !== 1'b1)
	    $display("ERROR: porb = %b after the POR should have released",
		     harness_core.porb);

	// Test 1:  Read from housekeeping fixed value register

	start_csb();
	write_byte(8'h40);	// Read stream command
	write_byte(8'h03);	// Address (register 0x3 = product ID)
	read_byte(tbdata);
	end_csb();
	#10;
	$display("Read data = 0x%02x (should be 0x18)", tbdata);

	// Test 2:  Write to clock prescaler (test clock scales)

	start_csb();
	write_byte(8'h01);	// Run sequencer, looping (starts clock)
	write_byte(8'h80);	// Write stream command
	write_byte(8'h0e);	// Address (register 0x0e = clock prescaler)
	write_byte(8'h00);
	end_csb();
	#10;
	$display("Wrote 0x00 to clock prescaler (1x)");

	start_csb();
	write_byte(8'h80);	// Write stream command
	write_byte(8'h0e);	// Address (register 0x1e = clock prescaler)
	write_byte(8'h01);
	end_csb();
	#10;
	$display("Wrote 0x01 to clock prescaler (2x)");

	start_csb();
	write_byte(8'h80);	// Write stream command
	write_byte(8'h0e);	// Address (register 0x0e = clock prescaler)
	write_byte(8'h02);
	end_csb();
	#10;
	$display("Wrote 0x02 to clock prescaler (3x)");

	start_csb();
	write_byte(8'h80);	// Write stream command
	write_byte(8'h0e);	// Address (register 0x0e = clock prescaler)
	write_byte(8'h03);
	end_csb();
	#10;
	$display("Wrote 0x03 to clock prescaler (4x)");

	start_csb();
	write_byte(8'h80);	// Write stream command
	write_byte(8'h0e);	// Address (register 0x0e = clock prescaler)
	write_byte(8'h0b);
	end_csb();
	#10;
	$display("Wrote 0x0b to clock prescaler (12x)");

	write_byte(8'h03);	// Command, no data (start sequencer)
	#10;
	$display("Stopped sequencer");

	// Test 3:  Write 4 bytes to SRAM at address 0xff and read them back

	start_csb();
	write_byte(8'h20);	// Write SRAM stream command
	write_byte(8'hff);	// Address (location 0xff with auto-increment)
	write_byte(8'h55);
	write_byte(8'haa);
	write_byte(8'h3c);
	write_byte(8'hc3);
	end_csb();
	#10;
	$display("Wrote 0x55aa3cc3 to SRAM");

	// NOTE:  The SRAM can't latch the full address by the next
	// SCK edge, so the data are always 1 byte late.  This is a
	// quirk of the SRAM read cycle, which is only diagnostic,
	// so it's not worth trying to avoid the dummy output byte.
	start_csb();
	write_byte(8'h10);	// Read SRAM stream command
	write_byte(8'hff);	// Address (location 0xff with auto-increment)
	read_byte(tbdata);	// Read dummy byte, and discard
	read_byte(tbdata);
	$display("Read data = 0x%02x (should be 0x55)", tbdata);
	read_byte(tbdata);
	$display("Read data = 0x%02x (should be 0xaa)", tbdata);
	read_byte(tbdata);
	$display("Read data = 0x%02x (should be 0x3c)", tbdata);
	read_byte(tbdata);
	$display("Read data = 0x%02x (should be 0xc3)", tbdata);
	end_csb();
	#10;

	// Test 4:  Run sequencer in count up mode

	start_csb();
	write_byte(8'h80);	// Write mode 0 (count up) to register 0x10
	write_byte(8'h10);
	write_byte(8'h00);
	end_csb();

	start_csb();
	write_byte(8'h01);	// Command, no data (start sequencer)
	end_csb();
	#10;
	$display("Sequencer started in loop mode");

	// Test 5:  Stop sequencer

	start_csb();
	write_byte(8'h03);	// Command, no data
	end_csb();
	#10;
	$display("Sequencer stopped");

	// Test 6:  Write sequencer start and stop values, run in loop mode

	start_csb();
	write_byte(8'h80);	// Write stream command
	write_byte(8'h12);	// Sequencer start/stop (4 bytes)
	write_byte(8'h12);
	write_byte(8'h11);
	write_byte(8'h15);
	write_byte(8'h11);
	end_csb();
	#10;
	start_csb();
	write_byte(8'h01);	// Command, no data
	end_csb();
	#10;
	$display("Sequencer short segment looping");
	start_csb();
	write_byte(8'h03);	// Command, no data
	end_csb();
	#10;
	$display("Sequencer stopped");
	start_csb();
	write_byte(8'h02);	// Command, no data
	end_csb();
	#10;
	$display("Sequencer short segment single-shot");
	start_csb();
	write_byte(8'h03);	// Command, no data
	end_csb();
	#10;
	$display("Sequencer stopped");

	// Test 7:  Write walking ones sequence into SRAM and run sequencer
	//	    in SRAM looping mode

	start_csb();
	write_byte(8'h20);	// Write SRAM stream command
	write_byte(8'h00);	// Address (location 0x00 with auto-increment)
	write_byte(8'h01);
	write_byte(8'h02);
	write_byte(8'h04);
	write_byte(8'h08);
	write_byte(8'h10);
	write_byte(8'h20);
	write_byte(8'h40);
	write_byte(8'h80);
	end_csb();
	#10;
	$display("Wrote walking ones to SRAM");

	start_csb();
	write_byte(8'h80);	// Write register
	write_byte(8'h16);	// Pattern generator stop address
	write_byte(8'h07);	// Value 7
	write_byte(8'h00);
	end_csb();
	#10;
	$display("Set SRAM stop address to 7");

	start_csb();
	write_byte(8'h01);	// Run sequencer, looping
	end_csb();
	#10;
	$display("Running sequencer in looping mode");

	// Test 8:  Digital reset

	start_csb();
	write_byte(8'h04);	// Command, no data
	end_csb();
	#10;
	$display("Digital reset");

	#100;

	// Test 9:  Select a project
	start_csb();
	write_byte(8'h80);
	write_byte(8'h50);	// 0x50 = project selection
	write_byte(8'h02);	// select project slot 2
	end_csb();
	#10;
	$display("Project 2 selected");

	// NOTE:  Need to test analog functions such as the iDAC and
	// voltage reference---But the analog blocks need functional
	// verilog descriptions and analog switches.
	
	// Test 10:  Configure all 12 digital pins as inputs to the
	// project.  Confirm that the digital bits appear at the project
	// location.
	
	start_csb();
	write_byte(8'h80);
	write_byte(8'h20);	// Hex 20 = first input bit (up to 24)
	write_byte(8'h0b);	// assign input bit 0 to digital line 11
	write_byte(8'h0a);	// assign input bit 1 to digital line 10
	write_byte(8'h09);	// assign input bit 2 to digital line 9
	write_byte(8'h0d);	// assign input bit 3 to constant 0
	write_byte(8'h0e);	// assign input bit 4 to constant 1
	write_byte(8'h0f);	// assign input bit 5 to sequencer output
	write_byte(8'h08);	// assign input bit 6 to digital line 8
	write_byte(8'h07);	// assign input bit 7 to digital line 7
	write_byte(8'h00);	// assign input bit 8 to digital line 6
	write_byte(8'h01);	// assign input bit 9 to digital line 5
	write_byte(8'h02);	// assign input bit 10 to digital line 4
	write_byte(8'h03);	// assign input bit 11 to digital line 3
	write_byte(8'h04);	// assign input bit 12 to digital line 2
	write_byte(8'h0e);	// assign input bit 13 to constant 1
	write_byte(8'h0d);	// assign input bit 14 to constant 0
	write_byte(8'h05);	// assign input bit 15 to digital line 1
	write_byte(8'h06);	// assign input bit 16 to digital line 0
	end_csb();
	#10;
	$display("Set digital inputs for project 2");

	start_csb();
	write_byte(8'h80);
	write_byte(8'h51);	// Hex 51 = user project configuration
	write_byte(8'h06);	// Switch on project power supplies
	end_csb();
	#10;
	$display("Switch on power supplies for project 2");

	start_csb();
	write_byte(8'h80);
	write_byte(8'h51);	// Hex 51 = user project configuration
	write_byte(8'h07);	// Set project enable and power supplies
	end_csb();
	#10;
	$display("Set project enable for project 2");

	start_csb();
	write_byte(8'h80);
	write_byte(8'h51);	// Hex 51 = user project configuration
	write_byte(8'hff);	// Set project enable, power, + digital and analog
	end_csb();
	#10;
	$display("Set all project enables for project 2");

	// Additional tests needed:
	// (2) Test of the SRAM and strobe monitoring through the router
	// (3) Test PRNG.
	// (4) Test variable-rate SRAM mode
	// (5) Test SRAM change on sequencer roll-over

	#5000;
	$finish;
    end
	
    /* External clock */
    always #10 clk <= (clk === 1'b0);

    /* Instantiate the digital top module */
    /* The four shared analog pins.
     *
     * These MUST be connected even though this testbench does not use
     * them.  An unconnected "input real" port is 0.0, not NaN, and 0.0
     * is a legitimate voltage --- so leaving them dangling would quietly
     * tell the design that something outside is holding all four shared
     * pins at ground.  NaN is "nothing is connected", which is the truth
     * here.
     */
    wire real analog_pin_unconnected;
    assign analog_pin_unconnected = 0.0/0.0;

    wire real analog_pin0_out, analog_pin1_out;
    wire real analog_pin2_out, analog_pin3_out;

    chipalooza_frame harness_core (
	    .analog_pin0_in(analog_pin_unconnected),
	    .analog_pin1_in(analog_pin_unconnected),
	    .analog_pin2_in(analog_pin_unconnected),
	    .analog_pin3_in(analog_pin_unconnected),
	    .analog_pin0_out(analog_pin0_out),
	    .analog_pin1_out(analog_pin1_out),
	    .analog_pin2_out(analog_pin2_out),
	    .analog_pin3_out(analog_pin3_out),
	`ifdef USE_POWER_PINS
	    .vdd3v3(AVDD),
	    .vss3v3(AVSS),
	    .vdd1v2(DVDD),
	    .vss1v2(DVSS),
	    .vddd(DVDD),
	`endif
	    .clk_in(clk),
	    .SCK_in(SCK),
	    .SDI_in(SDI),
	    .CSB_in(CSB),
	    .SDO_out(SDO),
	    .SDO_ena(sdo_ena),
	    .mask_rev(mask_rev_in),
	    .gpio_in(io_in),
	    .gpio_out(io_out),
	    .gpio_oe(io_oe),

	    /* Additional pins left unconnected here */
	    .analog_esd(),
	    .s1_an(),
	    .s2_an(),
	    .s3_an(),
	    .s4_an(),
	    .s5_an(),
	    .s6_an(),
	    .s7_an_0_vref(),
	    .s7_an_0_outp(),
	    .s7_an_0_outn(),
	    .s7_an_0_vcm(),
	    .s7_an_0_en_3v3(),
	    .s7_an_0_en_3v3_b(),
	    .s7_an_0_iref(),
	    .s7_an_1_vinp(),
	    .s7_an_1_vinn(),
	    .s7_an_1_vref(),
	    .s7_an_1_iref(),
	    .s7_an_1_en_3v3_b(),
	    .s7_an_1_en_3v3(),
	    .s8_an(),
	    .s9_an(),
	    .s10_an(),
	    .s11_an(),
	    .s12_an(),
	    .s13_an(),
	    .s14_an(),
	    .s15_an(),
	    .s16_an(),
	    .s17_an(),
	    .s18_an()
    );

endmodule
