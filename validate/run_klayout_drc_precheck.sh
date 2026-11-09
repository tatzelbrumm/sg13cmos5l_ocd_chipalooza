#!/bin/bash
#
# Run klayout DRC on the openframe test chip final (filled) version
# GDS is sg13cmos5l_ocd_chipalooza.gds.gz, top level cell name is
# sg13cmos5l_ocd_chipalooza (this *is* the version with fill)
# This is the minimal pre-check DRC as defined by IHP.
#
# Set environment variable PROJECT to the name of the top level
# cell.  If not defined, it defaults to
# sg13cmos5l_ocd_chipalooza_final.
#

echo ${PROJECT:=sg13cmos5l_ocd_chipalooza_final}

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

python3 $PDK_ROOT/$PDK/libs.tech/klayout/tech/drc/run_drc.py \
	--precheck_drc --mp=22 --no_offgrid --density_thr=22 \
	--no_angle --disable_extra_rules --no_recommended --path=../gds/${PROJECT}.gds.gz

echo "Done!"
exit 0
