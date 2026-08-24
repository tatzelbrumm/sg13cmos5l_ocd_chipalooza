#!/bin/bash

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

project=openframe_user_project

magic -dnull -noconsole -rcfile $PDK_ROOT/$PDK/libs.tech/magic/${PDK}.magicrc << EOF
source ../scripts/layout_setup.tcl
load $project
select top cell
extract path extfiles
extract no all
extract do unique
extract all
ext2spice lvs
ext2spice -p extfiles -o ../netlist/layout/${project}.spice
quit -noprompt
EOF
rm -r extfiles
exit 0

