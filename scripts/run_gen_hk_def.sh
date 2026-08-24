#!/bin/bash
#
# Open Circuit Design "Caravel" open frame harness for IHP SG13CMOS5L
#
# Padframe generation
#
# Source this script to from the "gs13cmos5l_ocd_openframe" project
# top level directory to generate the padframe layout.
#
# Usage:
#	setenv PDK <path/to/IHP/pdk>
#	./run_gen_padframe.sh
#
#	Run this script in the repository top level directory.
#
# Warning:
#	This script needs to be run only once.  It cannot be run again until
#	the padframe cell is deleted.

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

cd magic

magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
source ../scripts/run_gen_hk_def.tcl
EOF

echo "Done!"
exit 0
