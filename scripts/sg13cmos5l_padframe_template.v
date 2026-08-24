/*-------------------------------------------------------------------------*/
/* sg13cmos5l_padframe:  An 80-pad frame for the Chipalooza analog harness */
/*									   */
/* Written by:								   */
/* Tim Edwards								   */
/* Open Circuit Design, LLC						   */
/* August 2026							   	   */
/*-------------------------------------------------------------------------*/

TEMPLATE_MESSAGE

`default_nettype none

module sg13cmos5l_padframe (
`ifdef USE_POWER_PINS
    // Pad power connections
    inout wire vdd1v2,		// User project 1.2V power
    inout wire vss1v2,		// Global 1.2V domain ground return
    inout wire vdd3v3,		// Global 3.3V power
    inout wire vss3v3,		// Global 3.3V domain ground return
    inout wire vddd,		// Housekeeping 1.2V power
`endif	/* USE_POWER_PINS */

    // Pad signal connections
    inout wire [11:0] gpio,
    inout wire [3:0]  analog,
    inout wire SDO,
    input wire SDI,
    input wire CSB,
    input wire SCK,
    input wire clk,
    inout wire [3:0] s1_an,
    inout wire [0:0] s2_an,
    inout wire [1:0] s3_an,
    inout wire [2:0] s4_an,
    inout wire [1:0] s5_an,
    inout wire [0:0] s6_an,
    inout wire [1:0] s7_an,
    inout wire [2:0] s8_an,
    inout wire [2:0] s9_an,
    inout wire [1:0] s10_an,
    inout wire [0:0] s11_an,
    inout wire [1:0] s12_an,
    inout wire [2:0] s13_an,
    inout wire [1:0] s14_an,
    inout wire [0:0] s15_an,
    inout wire [3:0] s16_an,

    // Core signal connections
    INPUT_OUTPUT_LIST

    // Core signal connections:  User ID ROM
    output wire [31:0] mask_rev
);

    // Instantiate the pads:

    // Corner pads

    sg13cmos5l_Corner corner_sw (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_Corner corner_se (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_Corner corner_nw (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_Corner corner_ne (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    // 1.2V domain power split cells (custom)

    sg13cmos5l_ocd_VddSplit200 splitter[1:0] (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vssl(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    // Bottom side pads

    sg13cmos5l_IOPadTriOut16mA pad_SDO (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(SDO),
	.c2p(SDO_out),
	.c2p_en(SDO_ena)
    );

    sg13cmos5l_IOPadIn pad_SDI (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(SDI),
	.p2c(SDI_in)
    );

    sg13cmos5l_IOPadIn pad_CSB (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(CSB),
	.p2c(CSB_in)
    );

    sg13cmos5l_IOPadIn pad_SCK (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(SCK),
	.p2c(SCK_in)
    );

    sg13cmos5l_IOPadIn pad_clk (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(clk),
	.p2c(clk_in)
    );

    sg13cmos5l_IOPadVdd pad_vddd (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadVdd pad_vddd (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );


    sg13cmos5l_IOPadInOut16mA pad_gpio_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[0]),
	.p2c(gpio_0_in),
	.c2p(gpio_0_out),
	.c2p_en(gpio_0_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[1]),
	.p2c(gpio_1_in),
	.c2p(gpio_1_out),
	.c2p_en(gpio_1_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[2]),
	.p2c(gpio_2_in),
	.c2p(gpio_2_out),
	.c2p_en(gpio_2_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_3 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[3]),
	.p2c(gpio_3_in),
	.c2p(gpio_3_out),
	.c2p_en(gpio_3_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_4 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[4]),
	.p2c(gpio_4_in),
	.c2p(gpio_4_out),
	.c2p_en(gpio_4_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_5 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[5]),
	.p2c(gpio_5_in),
	.c2p(gpio_5_out),
	.c2p_en(gpio_5_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_6 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[6]),
	.p2c(gpio_6_in),
	.c2p(gpio_6_out),
	.c2p_en(gpio_6_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_7 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[7]),
	.p2c(gpio_7_in),
	.c2p(gpio_7_out),
	.c2p_en(gpio_7_oe)
    );

    // Right side pads

    sg13cmos5l_IOPadVss pad_vss1v2_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadVss pad_vss1v2_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadIOVdd pad_vdd3v3_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadIOVdd pad_vdd3v3_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_1_0_TYPE pad_s1_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s1_an[0]),
	PAD_1_0_SIGNALS
    );

    PAD_1_1_TYPE pad_s1_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s1_an[1]),
	PAD_1_1_SIGNALS
    );

    PAD_1_2_TYPE pad_s1_an_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s1_an[2]),
	PAD_1_2_SIGNALS
    );

    PAD_1_3_TYPE pad_s1_an_3 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s1_an[3]),
	PAD_1_3_SIGNALS
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_2_0_TYPE pad_s2_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s2_an[0]),
	PAD_2_0_SIGNALS
    );

    PAD_3_0_TYPE pad_s3_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s3_an[0]),
	PAD_3_0_SIGNALS
    );

    PAD_3_1_TYPE pad_s3_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s3_an[1]),
	PAD_3_1_SIGNALS
    );

    sg13cmos5l_IOPadVss pad_vss1v2_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_4_0_TYPE pad_s4_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s4_an[0]),
	PAD_4_0_SIGNALS
    );

    PAD_4_1_TYPE pad_s4_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s4_an[1]),
	PAD_4_1_SIGNALS
    );

    PAD_4_2_TYPE pad_s4_an_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s4_an[2]),
	PAD_4_2_SIGNALS
    );

    PAD_5_0_TYPE pad_s5_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s5_an[0]),
	PAD_5_0_SIGNALS
    );

    PAD_5_1_TYPE pad_s5_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s5_an[1]),
	PAD_5_1_SIGNALS
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_6_0_TYPE pad_s6_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s6_an[0]),
	PAD_6_0_SIGNALS
    );

    PAD_7_0_TYPE pad_s7_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s7_an[0]),
	PAD_7_0_SIGNALS
    );

    PAD_7_1_TYPE pad_s7_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s7_an[1]),
	PAD_7_1_SIGNALS
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_8_0_TYPE pad_s8_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s8_an[0]),
	PAD_8_0_SIGNALS
    );

    PAD_8_1_TYPE pad_s8_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s8_an[1]),
	PAD_8_1_SIGNALS
    );

    PAD_8_2_TYPE pad_s8_an_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s8_an[2]),
	PAD_8_2_SIGNALS
    );

    // Top side pads

    sg13cmos5l_IOPadVss pad_vss1v2_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_8 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[8]),
	.p2c(gpio_8_in),
	.c2p(gpio_8_out),
	.c2p_en(gpio_8_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_9 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[9]),
	.p2c(gpio_9_in),
	.c2p(gpio_9_out),
	.c2p_en(gpio_9_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_10 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[10]),
	.p2c(gpio_10_in),
	.c2p(gpio_10_out),
	.c2p_en(gpio_10_oe)
    );

    sg13cmos5l_IOPadInOut16mA pad_gpio_11 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(gpio[11]),
	.p2c(gpio_11_in),
	.c2p(gpio_11_out),
	.c2p_en(gpio_11_oe)
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadAnalog pad_analog_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(analog[0]),
	.padres(analog_esd[0])
    );

    sg13cmos5l_IOPadAnalog pad_analog_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(analog[1]),
	.padres(analog_esd[1])
    );

    sg13cmos5l_IOPadAnalog pad_analog_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(analog[2]),
	.padres(analog_esd[2])
    );

    sg13cmos5l_IOPadAnalog pad_analog_3 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(analog[3]),
	.padres(analog_esd[3])
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_3 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_4 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadIOVdd pad_vdd3v3_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadIOVdd pad_vdd3v3_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadIOVdd pad_vdd3v3_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadIOVdd pad_vdd3v3_3 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    // Right side pads

    PAD_9_0_TYPE pad_s9_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s9_an[0]),
	PAD_9_0_SIGNALS
    );

    PAD_9_1_TYPE pad_s9_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s9_an[1]),
	PAD_9_1_SIGNALS
    );

    PAD_9_2_TYPE pad_s9_an_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s9_an[2]),
	PAD_9_2_SIGNALS
    );

    sg13cmos5l_IOPadVss pad_vss1v2_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_10_0_TYPE pad_s10_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s10_an[0]),
	PAD_10_0_SIGNALS
    );

    PAD_10_1_TYPE pad_s10_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s10_an[1]),
	PAD_10_1_SIGNALS
    );

    PAD_11_0_TYPE pad_s11_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s11_an[0]),
	PAD_11_0_SIGNALS
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_3 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_12_0_TYPE pad_s12_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s12_an[0]),
	PAD_12_0_SIGNALS
    );

    PAD_12_1_TYPE pad_s12_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s12_an[1]),
	PAD_12_1_SIGNALS
    );

    PAD_13_0_TYPE pad_s13_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s13_an[0]),
	PAD_13_0_SIGNALS
    );

    PAD_13_1_TYPE pad_s13_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s13_an[1]),
	PAD_13_1_SIGNALS
    );

    PAD_13_2_TYPE pad_s13_an_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s13_an[2]),
	PAD_13_2_SIGNALS
    );

    sg13cmos5l_IOPadIOVss pad_vss3v3_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_14_0_TYPE pad_s14_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s14_an[0]),
	PAD_14_0_SIGNALS
    );

    PAD_14_1_TYPE pad_s14_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s14_an[1]),
	PAD_14_1_SIGNALS
    );

    PAD_15_0_TYPE pad_s15_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s15_an[0]),
	PAD_15_0_SIGNALS
    );

    sg13cmos5l_IOPadVss pad_vss1v2_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    PAD_16_0_TYPE pad_s16_an_0 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s16_an[0]),
	PAD_16_0_SIGNALS
    );

    PAD_16_1_TYPE pad_s16_an_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s16_an[1]),
	PAD_16_1_SIGNALS
    );

    PAD_16_2_TYPE pad_s16_an_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s16_an[2]),
	PAD_16_2_SIGNALS
    );

    PAD_16_3_TYPE pad_s16_an_3 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2),
	`endif	/* USE_POWER_PINS */
	.pad(s16_an[3]),
	PAD_16_3_SIGNALS
    );

    sg13cmos5l_IOPadVdd pad_vdd1v2_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadVdd pad_vdd1v2_2 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_IOPadVss pad_vss1v2_1 (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    /* Filler pads between each bond pad */
    /* 72 fillers total, 14 on the bottom (vddd/vss1v2 domain),
     * 56 on the other sides.  Note that at the two points
     * on the sides at the bottom where the vddd/vss1v2 domain
     * ends and the vdd1v2/vss1v2 domain begins, there are
     * domain splitter cells taking up the space of the 1um
     * filler cell.
     */

    sg13cmos5l_Filler1000 spacer5a [56:0] (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_Filler200 spacer1a [55:0] (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vdd1v2),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_Filler1000 spacer5b [14:0] (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    sg13cmos5l_Filler200 spacer1b [13:0] (
	`ifdef USE_POWER_PINS
	    .iovdd(vdd3v3),
	    .iovss(vss3v3),
	    .vdd(vddd),
	    .vss(vss1v2)
	`endif	/* USE_POWER_PINS */
    );

    /* Non-electrically-connected modules */

    caravel_logo caravel_logo ();
    caravel_motto caravel_motto ();
    copyright_block copyright_block ();
    user_id_textblock user_id_textblock ();
    open_source open_source ();

    /* Add in user_id_programming (32-bit ROM block) */

    user_id_programming user_id_programming (
	`ifdef USE_POWER_PINS
	    .VDD(vddd),
	    .VSS(vss1v2),
	`endif  /* USE_POWER_PINS */
	.mask_rev(mask_rev)
    );

    /* Add in constant blocks (digital 1/0 near each digital pad) */

   CONSTANT_BLOCKS

endmodule

`default_nettype wire
