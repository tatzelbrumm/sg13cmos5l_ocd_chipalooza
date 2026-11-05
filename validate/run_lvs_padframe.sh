#!/bin/sh
#
# Run LVS on the chipalooza padframe (sg13cmos5l_padframe)
#
export PROJECT=${PROJECT:-sg13cmos5l_padframe}

export PDK_ROOT=${PDK_ROOT:-/home/tim/gits}
export PDK=${PDK:-ihp-sg13cmos5l}

export NETGEN_COLUMNS=75

cat > netgen.tcl << EOF
# Tcl script for project ${PROJECT} LVS

set circuit1 [readnet spice ../netlist/layout/${PROJECT}.spice]
# Read in libraries first, followed by all the verilog modules.

set circuit2 [readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice]

# NOTE:  Replaced foundry I/O netlist with a corrected version (too many issues related to
# the use of global "sub!")
# readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_io/spice/sg13cmos5l_io.spice \$circuit2
readnet spice ../netlist/schematic/sg13cmos5l_io.spice \$circuit2
# Custom (non-foundry) I/O pad cells (magic/custom_io/)
readnet spice ../netlist/schematic/custom_io.spice \$circuit2

# Read verilog submodules
readnet verilog ../verilog/gl/netlists_lvs.v \$circuit2

# Read the project padframe from structural verilog
readnet verilog ../verilog/gl/${PROJECT}.v \$circuit2

# Flatten the splitter cell (NOTE:  This has been removed from the netlist)
# flatten class "\$circuit2 sg13cmos5l_ocd_Split2000"

# The secondary protection circuit has issues with
# mismatched pins but will try to match anyway and
# screw up the LVS.
flatten class "\$circuit1 sg13cmos5l_SecondaryProtection"
flatten class "\$circuit2 sg13cmos5l_SecondaryProtection"

# Same for these I/O top level cells
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

