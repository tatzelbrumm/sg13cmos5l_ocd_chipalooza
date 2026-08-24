#! /bin/bash
mkdir -p ../netlist/schematic

project=openframe_user_project

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

# Source the local xschemrc, which recursively reads the xschemrc files
# of the dependencies, then reads the PDK xschemrc file.

xschem -n -s -r -x -q --tcl "set top_is_subckt 1" --rcfile ./xschemrc -o ../netlist/schematic -N $project.spice $project.sch

echo "Done!"
exit 0
