#!/bin/sh
#
# Run LVS on the caravel openframe top level
# (final, after fill generation)
#
# The name of the project top level defaults to
# "sg13cmos5l_caravel_openframe_final".  To change to something else
# (e.g., the IHP assigned project name), set the environment variable
# PROJECT to the name of the top level (which is assumed to also be
# the name of the GDS file.)
#
echo ${PROJECT:=sg13cmos5l_caravel_openframe_final} > /dev/null

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

export NETGEN_COLUMNS=75

cat > netgen.tcl << EOF
# Tcl script for project ${PROJECT} LVS
set circuit1 [readnet spice ../netlist/layout/${PROJECT}.spice]
# Read in libraries first, followed by all the verilog modules.
set circuit2 [readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice]
readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_io/spice/sg13cmos5l_io.spi \$circuit2
# housekeeping_top must be read before the user project since it is a
# component of the user project.  Source of housekeeping_top is:
# ../librelane/runs/RUN_2026-03-19_17-09-26/51-openroad-fillinsertion/
readnet verilog ../verilog/gl/housekeeping_top.pnl.v \$circuit2
readnet spice ../netlist/schematic/openframe_user_project.spice \$circuit2
readnet verilog ../verilog/gl/netlists_lvs.v \$circuit2
readnet verilog ../verilog/gl/${PROJECT}.v \$circuit2

lvs "\$circuit1 ${PROJECT}" "\$circuit2 ${PROJECT}" \
${PDK_ROOT}/${PDK}/libs.tech/netgen/${PDK}_setup.tcl \
comp_${PROJECT}.out
EOF

netgen -batch source netgen.tcl
rm netgen.tcl
echo "Done!"
exit 0

