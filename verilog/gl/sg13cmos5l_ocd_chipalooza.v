/*------------------------------------------------------*/
/* sg13cmos5l_ocd_chipalooza.v				*/
/* Verilog netlist of the harness chip top level	*/
/*							*/
/* Contains the padframe and "chipalooza_frame"		*/
/* containing everything else.				*/
/*							*/
/* Written by Tim Edwards, Open Circuit Design		*/
/* September 23, 2026					*/
/*------------------------------------------------------*/

module sg13cmos5l_ocd_chipalooza (
    `ifdef USE_POWER_PINS
	inout vdd3v3,		// 3.3V domain supply
	inout vss3v3,		// 3.3V domain ground
	inout vdd1v2,		// 1.2V domain supply
	inout vss1v2,		// 1.2V domain ground
	inout vddd,		// 1.2V digital supply
    `endif
    output wire SDO,
    input  wire SDI,
    input  wire CSB,
    input  wire SCK,
    input  wire clk,
    inout  wire [11:0] gpio,
    inout  wire [3:0] analog,
    inout  wire [1:0] s1_an,
    inout  wire [1:0] s2_an,
    inout  wire [1:0] s3_an,
    inout  wire [0:0] s4_an,
    inout  wire [2:0] s5_an,
    inout  wire [1:0] s6_an,
    inout  wire [1:0] s7_an,
    inout  wire [0:0] s8_an,
    inout  wire [2:0] s9_an,
    inout  wire [2:0] s10_an,
    inout  wire [0:0] s11_an,
    inout  wire [1:0] s12_an,
    inout  wire [1:0] s13_an,
    inout  wire [2:0] s14_an,
    inout  wire [0:0] s15_an,
    inout  wire [1:0] s16_an,
    inout  wire [1:0] s17_an,
    inout  wire [1:0] s18_an
);

    /* Internally-defined wires */

    wire SDO_out;
    wire SDO_ena;
    wire CSB_in;
    wire SDK_in;
    wire SDI_in;
    wire clk_in;

    wire [11:0] gpio_in;
    wire [11:0] gpio_out;
    wire [11:0] gpio_oe;

    wire s1_an_0_esd;
    wire s1_an_1_esd;
    wire s2_an_0_esd;
    wire s2_an_1_esd;
    wire s3_an_0_esd;
    wire s3_an_1_esd;
    wire s4_an_0_esd;
    wire s5_an_0_esd;
    wire s5_an_1_esd;
    wire s5_an_2_esd;
    wire s6_an_0_esd;
    wire s6_an_1_esd;
    wire s7_an_0_vref;
    wire s7_an_0_outp;
    wire s7_an_0_outn;
    wire s7_an_0_vcm;
    wire s7_an_0_en_3v3;
    wire s7_an_0_en_3v3_b;
    wire s7_an_0_iref;
    wire s7_an_1_vinp;
    wire s7_an_1_vinn;
    wire s7_an_1_vref;
    wire s7_an_1_iref;
    wire s7_an_1_en_3v3_b;
    wire s7_an_1_en_3v3;
    wire s8_an_0_esd;
    wire s9_an_0_esd;
    wire s9_an_1_esd;
    wire s9_an_2_esd;
    wire s10_an_0_esd;
    wire s10_an_1_esd;
    wire s10_an_2_esd;
    wire s11_an_0_esd;
    wire s12_an_0_esd;
    wire s12_an_1_esd;
    wire s13_an_0_esd;
    wire s13_an_1_esd;
    wire s14_an_0_esd;
    wire s14_an_1_esd;
    wire s14_an_2_esd;
    wire s15_an_0_esd;
    wire s16_an_0_esd;
    wire s16_an_1_esd;
    wire s17_an_0_esd;
    wire s17_an_1_esd;
    wire s18_an_0_esd;
    wire s18_an_1_esd;
    wire [3:0] analog_esd;
    wire [31:0] mask_rev;

    /* Instantiate the padframe (sg13cmos5l_padframe) */

    sg13cmos5l_padframe padframe (
	`ifdef USE_POWER_PINS
	    .vdd3v3(vdd3v3),
	    .vss3v3(vss3v3),
	    .vdd1v2(vdd1v2),
	    .vss1v2(vss1v2),
	    .vddd(vddd),
	`endif
	.gpio(gpio),
	.analog(analog),
	.SDO(SDO),
	.SDI(SDI),
	.CSB(CSB),
	.clk(clk),
	.s1_an(s1_an),
	.s2_an(s2_an),
	.s3_an(s3_an),
	.s4_an(s4_an),
	.s5_an(s5_an),
	.s6_an(s6_an),
	.s7_an(s7_an),
	.s8_an(s8_an),
	.s9_an(s9_an),
	.s10_an(s10_an),
	.s11_an(s11_an),
	.s12_an(s12_an),
	.s13_an(s13_an),
	.s14_an(s14_an),
	.s15_an(s15_an),
	.s16_an(s16_an),
	.s17_an(s17_an),
	.s18_an(s18_an),

	// Core-facing signals
	.SDO_out(SDO_out),
	.SDO_ena(SDO_ena),
	.CSB_in(CSB_in),
	.SCK_in(SCK_in),
	.SDI_in(SDI_in),
	.clk_in(clk_in),
	.gpio_0_in(gpio_in[0]),
	.gpio_0_out(gpio_out[0]),
	.gpio_0_oe(gpio_oe[0]),
	.gpio_1_in(gpio_in[1]),
	.gpio_1_out(gpio_out[1]),
	.gpio_1_oe(gpio_oe[1]),
	.gpio_2_in(gpio_in[2]),
	.gpio_2_out(gpio_out[2]),
	.gpio_2_oe(gpio_oe[2]),
	.gpio_3_in(gpio_in[3]),
	.gpio_3_out(gpio_out[3]),
	.gpio_3_oe(gpio_oe[3]),
	.gpio_4_in(gpio_in[4]),
	.gpio_4_out(gpio_out[4]),
	.gpio_4_oe(gpio_oe[4]),
	.gpio_5_in(gpio_in[5]),
	.gpio_5_out(gpio_out[5]),
	.gpio_5_oe(gpio_oe[5]),
	.gpio_6_in(gpio_in[6]),
	.gpio_6_out(gpio_out[6]),
	.gpio_6_oe(gpio_oe[6]),
	.gpio_7_in(gpio_in[7]),
	.gpio_7_out(gpio_out[7]),
	.gpio_7_oe(gpio_oe[7]),
	.gpio_8_in(gpio_in[8]),
	.gpio_8_out(gpio_out[8]),
	.gpio_8_oe(gpio_oe[8]),
	.gpio_9_in(gpio_in[9]),
	.gpio_9_out(gpio_out[9]),
	.gpio_9_oe(gpio_oe[9]),
	.gpio_10_in(gpio_in[10]),
	.gpio_10_out(gpio_out[10]),
	.gpio_10_oe(gpio_oe[10]),
	.gpio_11_in(gpio_in[11]),
	.gpio_11_out(gpio_out[11]),
	.gpio_11_oe(gpio_oe[11]),

	.s1_an_0_esd(s1_an_0_esd),
	.s1_an_1_esd(s1_an_1_esd),
	.s2_an_0_esd(s2_an_0_esd),
	.s2_an_1_esd(s2_an_1_esd),
	.s3_an_0_esd(s3_an_0_esd),
	.s3_an_1_esd(s3_an_1_esd),
	.s4_an_0_esd(s4_an_0_esd),
	.s5_an_0_esd(s5_an_0_esd),
	.s5_an_1_esd(s5_an_1_esd),
	.s5_an_2_esd(s5_an_2_esd),
	.s6_an_0_esd(s6_an_0_esd),
	.s6_an_1_esd(s6_an_1_esd),
	.s7_an_0_vref(s7_an_0_vref),
	.s7_an_0_outp(s7_an_0_outp),
	.s7_an_0_outn(s7_an_0_outn),
	.s7_an_0_vcm(s7_an_0_vcm),
	.s7_an_0_en_3v3(s7_an_0_en_3v3),
	.s7_an_0_en_3v3_b(s7_an_0_en_3v3_b),
	.s7_an_0_iref(s7_an_0_iref),
	.s7_an_1_vinp(s7_an_1_vinp),
	.s7_an_1_vinn(s7_an_1_vinn),
	.s7_an_1_vref(s7_an_1_vref),
	.s7_an_1_iref(s7_an_1_iref),
	.s7_an_1_en_3v3_b(s7_an_1_en_3v3_b),
	.s7_an_1_en_3v3(s7_an_1_en_3v3),
	.s8_an_0_esd(s8_an_0_esd),
	.s9_an_0_esd(s9_an_0_esd),
	.s9_an_1_esd(s9_an_1_esd),
	.s9_an_2_esd(s9_an_2_esd),
	.s10_an_0_esd(s10_an_0_esd),
	.s10_an_1_esd(s10_an_1_esd),
	.s10_an_2_esd(s10_an_2_esd),
	.s11_an_0_esd(s11_an_0_esd),
	.s12_an_0_esd(s12_an_0_esd),
	.s12_an_1_esd(s12_an_1_esd),
	.s13_an_0_esd(s13_an_0_esd),
	.s13_an_1_esd(s13_an_1_esd),
	.s14_an_0_esd(s14_an_0_esd),
	.s14_an_1_esd(s14_an_1_esd),
	.s14_an_2_esd(s14_an_2_esd),
	.s15_an_0_esd(s15_an_0_esd),
	.s16_an_0_esd(s16_an_0_esd),
	.s16_an_1_esd(s16_an_1_esd),
	.s17_an_0_esd(s17_an_0_esd),
	.s17_an_1_esd(s17_an_1_esd),
	.s18_an_0_esd(s18_an_0_esd),
	.s18_an_1_esd(s18_an_1_esd),

	.analog_esd(analog_esd),

	.mask_rev(mask_rev)
    );

    /* Instantiate the harness core (chipalooza_frame) */

    chipalooza_frame harness_core (
	`ifdef USE_POWER_PINS
	    .vdd3v3(vdd3v3),
	    .vss3v3(vss3v3),
	    .vdd1v2(vdd1v2),
	    .vss1v2(vss1v2),
	    .vddd(vddd),
	`endif
	.s1_an_0(s1_an[0]),
	.s1_an_1(s1_an[1]),
	.s2_an_0(s2_an[0]),
	.s2_an_1(s2_an[1]),
	.s3_an_0(s3_an[0]),
	.s3_an_1(s3_an[1]),
	.s4_an_0(s4_an[0]),
	.s5_an_0(s5_an[0]),
	.s5_an_1(s5_an[1]),
	.s5_an_2(s5_an[2]),
	.s6_an_0(s6_an[0]),
	.s6_an_1(s6_an[1]),
	.s8_an_0(s8_an[0]),
	.s9_an_0(s9_an[0]),
	.s9_an_1(s9_an[1]),
	.s9_an_2(s9_an[2]),
	.s10_an_0(s10_an[0]),
	.s10_an_1(s10_an[1]),
	.s10_an_2(s10_an[2]),
	.s11_an_0(s11_an[0]),
	.s12_an_0(s12_an[0]),
	.s12_an_1(s12_an[1]),
	.s13_an_0(s13_an[0]),
	.s13_an_1(s13_an[1]),
	.s14_an_0(s14_an[0]),
	.s14_an_1(s14_an[1]),
	.s14_an_2(s14_an[2]),
	.s15_an_0(s15_an[0]),
	.s16_an_0(s16_an[0]),
	.s16_an_1(s16_an[1]),
	.s17_an_0(s17_an[0]),
	.s17_an_1(s17_an[1]),
	.s18_an_0(s18_an[0]),
	.s18_an_1(s18_an[1]),

	.s1_an_0_esd(s1_an_0_esd),
	.s1_an_1_esd(s1_an_1_esd),
	.s2_an_0_esd(s2_an_0_esd),
	.s2_an_1_esd(s2_an_1_esd),
	.s3_an_0_esd(s3_an_0_esd),
	.s3_an_1_esd(s3_an_1_esd),
	.s4_an_0_esd(s4_an_0_esd),
	.s5_an_0_esd(s5_an_0_esd),
	.s5_an_1_esd(s5_an_1_esd),
	.s5_an_2_esd(s5_an_2_esd),
	.s6_an_0_esd(s6_an_0_esd),
	.s6_an_1_esd(s6_an_1_esd),
	.s7_an_0_vref(s7_an_0_vref),
	.s7_an_0_outp(s7_an_0_outp),
	.s7_an_0_outn(s7_an_0_outn),
	.s7_an_0_vcm(s7_an_0_vcm),
	.s7_an_0_en_3v3(s7_an_0_en_3v3),
	.s7_an_0_en_3v3_b(s7_an_0_en_3v3_b),
	.s7_an_0_iref(s7_an_0_iref),
	.s7_an_1_vinp(s7_an_1_vinp),
	.s7_an_1_vinn(s7_an_1_vinn),
	.s7_an_1_vref(s7_an_1_vref),
	.s7_an_1_iref(s7_an_1_iref),
	.s7_an_1_en_3v3_b(s7_an_1_en_3v3_b),
	.s7_an_1_en_3v3(s7_an_1_en_3v3),
	.s8_an_0_esd(s8_an_0_esd),
	.s9_an_0_esd(s9_an_0_esd),
	.s9_an_1_esd(s9_an_1_esd),
	.s9_an_2_esd(s9_an_2_esd),
	.s10_an_0_esd(s10_an_0_esd),
	.s10_an_1_esd(s10_an_1_esd),
	.s10_an_2_esd(s10_an_2_esd),
	.s11_an_0_esd(s11_an_0_esd),
	.s12_an_0_esd(s12_an_0_esd),
	.s12_an_1_esd(s12_an_1_esd),
	.s13_an_0_esd(s13_an_0_esd),
	.s13_an_1_esd(s13_an_1_esd),
	.s14_an_0_esd(s14_an_0_esd),
	.s14_an_1_esd(s14_an_1_esd),
	.s14_an_2_esd(s14_an_2_esd),
	.s15_an_0_esd(s15_an_0_esd),
	.s16_an_0_esd(s16_an_0_esd),
	.s16_an_1_esd(s16_an_1_esd),
	.s17_an_0_esd(s17_an_0_esd),
	.s17_an_1_esd(s17_an_1_esd),
	.s18_an_0_esd(s18_an_0_esd),
	.s18_an_1_esd(s18_an_1_esd),

	.SDO(SDO_out),
	.sdoena(SDO_ena),
	.SDI(SDI_in),
	.CSB(CSB_in),
	.SCK(SCK_in),
	.clk(clk_in),
	.gpio_in(gpio_in),
	.gpio_out(gpio_out),
	.gpio_oe(gpio_oe),
	.analog(analog),
	.mask_rev(mask_rev)
    );

endmodule
