#!/bin/sh
#
# Run LVS on the chipalooza top level (sg13cmos5l_ocd_chipalooza)
#
export PROJECT=${PROJECT:-sg13cmos5l_ocd_chipalooza}

export PDK_ROOT=${PDK_ROOT:-/home/tim/gits}
export PDK=${PDK:-ihp-sg13cmos5l}

export NETGEN_COLUMNS=75

cat > netgen.tcl << EOF
# Tcl script for project ${PROJECT} LVS
set circuit1 [readnet spice ../netlist/layout/${PROJECT}.spice]
# Read in libraries first, followed by all the verilog modules.
set circuit2 [readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice]

# Issues in foundry I/O netlist require custom version.
readnet spice ../netlist/schematic/sg13cmos5l_io.spice \$circuit2
# Custom (non-foundry) I/O pad cells (magic/custom_io/)
readnet spice ../netlist/schematic/custom_io.spice \$circuit2
# readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_io/spice/sg13cmos5l_io.spice \$circuit2

# housekeeping_top must be read before the user project since it is a
# component of the user project.  Source of housekeeping_top is:
# ../librelane/runs/RUN_{latest}/51-openroad-fillinsertion/

readnet verilog ../verilog/gl/housekeeping_top.pnl.v \$circuit2
readnet verilog ../verilog/gl/user_project_control.pnl.v \$circuit2
readnet verilog ../verilog/gl/netlists_lvs.v \$circuit2

# The slot wrappers need their LVS view, not the simulation view in
# verilog/rtl:  that one names the analog pins analog_pin0/analog_pin1,
# has no ESD pins, and orders its ports for a human reader, none of which
# matches the layout.  verilog/gl/slot<N>_wrapper_lvs.v is generated from
# magic/slot<N>_wrapper.mag by scripts/run_gen_xschem_syms.sh, alongside
# the xschem symbol, so all three agree by construction.

for {set i 1} {\$i <= 18} {incr i} {
    readnet verilog ../verilog/gl/slot\${i}_wrapper_lvs.v \$circuit2
}

# NOTE: SRAM read from CDL; this has incorrect devices but the layout
# SRAM has been replaced with an abstract view and so the contents
# will not be compared.

readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_sram/cdl/RM_IHPSG13_1P_1024x8_c2_bm_bist.cdl \$circuit2

# Read the project padframe
readnet verilog ../verilog/gl/sg13cmos5l_padframe.v \$circuit2

# The project is assumed to be a schematic-captured netlist
readnet spice ../netlist/schematic/${PROJECT}.spice \$circuit2

# Make "in" and "out" of all the switches permutable, since they are symmetric and layouts
# have been placed for the convenience of routing, not with respect to any concept of "in"
# and "out".
permute "\$circuit1 analog_pswitch_small" in out
permute "\$circuit2 analog_pswitch_small" in out
permute "\$circuit1 analog_switch_small" in out
permute "\$circuit2 analog_switch_small" in out
permute "\$circuit1 analog_switch_med" in out
permute "\$circuit2 analog_switch_med" in out

# These cells need to be flattened or else pin differences will cause an LVS mismatch
flatten class "\$circuit1 sg13cmos5l_SecondaryProtection"
flatten class "\$circuit2 sg13cmos5l_SecondaryProtection"
flatten class "\$circuit1 sg13cmos5l_IOPadVdd"
flatten class "\$circuit2 sg13cmos5l_IOPadVdd"
flatten class "\$circuit1 sg13cmos5l_IOPadIOVdd"
flatten class "\$circuit2 sg13cmos5l_IOPadIOVdd"

lvs "\$circuit1 ${PROJECT}" "\$circuit2 ${PROJECT}" \
${PDK_ROOT}/${PDK}/libs.tech/netgen/${PDK}_setup.tcl \
comp_${PROJECT}.out
EOF

netgen -batch source netgen.tcl
rm netgen.tcl
echo "Done!"
exit 0

