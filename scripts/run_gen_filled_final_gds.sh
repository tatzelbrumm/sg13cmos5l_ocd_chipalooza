#!/bin/bash
#
# Run layout GDS generation on sg13cmos5l_caravel_openframe
# Run this script from the magic/ directory
#
# This is a compositor designed to do the following:
# (1) Read the top level sg13cmos5l_caravel_openframe
# (2) Add the fill pattern cell
# (3) Write out everything with a new top level.
#
# NOTE:  If PROJECT is set as an environment variable, then the final
# top level cell name and GDS file name will be set to its value.  If
# not, then the default top level name is "sg13cmos5l_caravel_openframe_final".
# When submitting for an IHP shuttle run, the project name will be dictated
# by the IHP submission process (e.g., PROJECT=IHP__MPC9763).

echo ${PROJECT:=sg13cmos5l_caravel_openframe_final} > /dev/null

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

echo "Generating final (filled) GDS for $PROJECT"

# Like the project top level pre-fill, the new top level layout (.mag) is
# always automatically generated.  Any existing one needs to be deleted or
# this script will fail.

rm -f ${PROJECT}.mag

magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable

gds readonly true
gds rescale false
gds read ../gds/sg13cmos5l_caravel_openframe.gds.gz
gds read ../gds/sg13cmos5l_caravel_openframe_fill_pattern.gds.gz

units microns
snap internal

load $PROJECT -silent
box values 0 0 0 0
getcell sg13cmos5l_caravel_openframe child 0 0
box position 0 0
getcell sg13cmos5l_caravel_openframe_fill_pattern child 0 0

# Regenerate the pad pins on the new top level.
box position 16.1 16.1
dump padframe_pins child 0 0

# Write out the .mag file for LVS purposes
writeall force $PROJECT

cif *hier write disable
cif *array write disable
gds compress 9
gds write $PROJECT
quit -noprompt
EOF
mv ${PROJECT}.gds.gz ../gds/
echo "Done!"
exit 0
