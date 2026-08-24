#!/bin/bash
#
# Open Circuit Design "Caravel" open frame harness for IHP SG13CMOS5L
#
# Project setup:
#
# Source this script to from the "gs13cmos5l_ocd_openframe" project
# top level directory to initialize the project.  This creates local
# libraries to hold .mag views of the IHP library cells read from the
# IHP open PDK sources.  This avoids the need to re-import GDS every
# time magic is run.
#
# The created directories are in .gitignore so they do not become
# part of the project repository, but can be generated on the fly
# as needed.  This script can be run at any time without affecting
# the rest of the project.
#
# Usage:
#	setenv PDK <path/to/IHP/pdk>
#	./setup.sh
#
#	Run this script in the repository top level directory.
#
# Note:
#	This project is based on the process "ihp-sg13cmos5l".
#	Currently (Feb. 17, 2026) the PDK for this process is in a
#	private repository.  By the time this project is published,
#	the SG13CMOS5L open PDK should have been made public.
#
# Warning:
#	The generated .mag files contain references back to the IHP
#	PDK.  If the IHP PDK gets updated, then the references may
#	become invalid, and this setup should be re-run.

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

cd magic

# Import the I/O library
# Create directory under magic/ for the library
mkdir -p sg13cmos5l_io

magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable
# 
# Prepare for library import
gds readonly true
gds rescale false
cd sg13cmos5l_io
gds read ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_io/gds/sg13cmos5l_io.gds
load sg13cmos5l_Gallery
cellname delete {(UNNAMED)}

# Annotate with LEF
lef read ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_io/lef/sg13cmos5l_io.lef

# Annotate with SPICE
readspice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_io/spice/sg13cmos5l_io.spice

# Write all the .mag files out
writeall force
EOF

# Import the standard cell library
# Create directory under magic/ for the library
mkdir -p sg13cmos5l_stdcell

magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable
# 
# Prepare for library import
gds readonly true
gds rescale false
cd sg13cmos5l_stdcell
gds read ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/gds/sg13cmos5l_stdcell.gds
load CoreSite
cellname delete {(UNNAMED)}

# Annotate with LEF
lef read ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/lef/sg13cmos5l_stdcell.lef

# Annotate with SPICE
readspice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice

# Write all the .mag files out
writeall force
EOF

# Import the SRAM 1024x8 macro
# Create directory under magic/ for the library
mkdir -p sg13cmos5l_sram

magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable
# 
# Prepare for library import
gds readonly true
gds rescale false
cd sg13cmos5l_sram
source ${PDK_ROOT}/${PDK}/libs.tech/magic/read_sram_gds.tcl
gds read ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_sram/gds/RM_IHPSG13_1P_1024x8_c2_bm_bist.gds
load RM_IHPSG13_1P_1024x8_c2_bm_bist
cellname delete {(UNNAMED)}

# Annotate with LEF
lef read ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_sram/lef/RM_IHPSG13_1P_1024x8_c2_bm_bist.lef

# Annotate with CDL
readspice ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_sram/cdl/RM_IHPSG13_1P_1024x8_c2_bm_bist.cdl

# Write all the .mag files out
writeall force
EOF

echo "Done!"
exit 0
