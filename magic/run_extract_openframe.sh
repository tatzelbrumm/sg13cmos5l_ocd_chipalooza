#!/bin/bash
#
# set PROJECT to the final top level name.  If not set, the top level
# name defaults to sg13cmos5l_caravel_openframe_final

echo ${PROJECT:=sg13cmos5l_caravel_openframe_final} > /dev/null

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null


magic -dnull -noconsole -rcfile $PDK_ROOT/$PDK/libs.tech/magic/${PDK}.magicrc << EOF
source ../scripts/layout_setup.tcl

# Create a fake fill pattern cell.  One is instantiated in the project, but there
# is no .mag file for it (to avoid creating the huge file in addition to the GDS).
# This is an empty placeholder and is never saved.
load sg13cmos5l_caravel_openframe_fill_pattern -silent
property FIXED_BBOX 0 0 1 1
property LEFview true

# Now read the project top level and extract it.
load $PROJECT -dereference
select top cell
extract path extfiles
extract no all
extract do unique
extract all
ext2spice lvs
ext2spice -p extfiles -o ../netlist/layout/${PROJECT}.spice
quit -noprompt
EOF
rm -r extfiles
exit 0

