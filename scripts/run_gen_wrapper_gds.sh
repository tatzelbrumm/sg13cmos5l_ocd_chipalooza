#!/bin/bash
#
# Run layout GDS generation on the caravel_openframe project wrapper
# Run this script from the magic/ directory
# Note:  It is the user's responsibility to make sure that the layout
# "chipalooza_frame_wrapper" has a valid project in it.
#
# This is a compositor designed to do the following:
# (1) Source the scripts for reading layout with correct paths
# (2) Read the project "chipalooza_frame_wrapper", dereferenced
# (3) Write GDS of the project wrapper
# (4) Move the GDS file to ../gds
#
echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

echo "Generating GDS for chipalooza_frame_wrapper"

magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable
source ../scripts/layout_setup.tcl
addpath sg13cmos5l_stdcell
addpath paramcells
load chipalooza_frame_wrapper -dereference
gds compress 9
gds write chipalooza_frame_wrapper
EOF

mv chipalooza_frame_wrapper.gds.gz ../gds/
echo "Done!"
exit 0

