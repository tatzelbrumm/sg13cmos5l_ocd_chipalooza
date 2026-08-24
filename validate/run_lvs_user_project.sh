#!/bin/sh
#
# Run LVS on the bandgap
#
echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

project=openframe_user_project

export NETGEN_COLUMNS=75

cat > netgen.tcl << EOF
# Tcl script for project ${project} LVS
set circuit1 [readnet spice ../netlist/layout/${project}.spice]
set circuit2 [readnet spice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice]
# NOTE:  The housekeeping digital subsystem is a black-box subcircuit
readnet ../netlist/schematic/housekeeping_top.spice \$circuit2
readnet ../netlist/schematic/${project}.spice \$circuit2
lvs "\$circuit1 ${project}" "\$circuit2 ${project}" \
${PDK_ROOT}/${PDK}/libs.tech/netgen/${PDK}_setup.tcl \
comp_${project}.out
EOF

netgen -batch source netgen.tcl
rm netgen.tcl
echo "Done!"
exit 0

