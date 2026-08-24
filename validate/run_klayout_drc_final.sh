#!/bin/bash
#
# Run klayout DRC on the openframe test chip final (filled) version
# GDS is sg13cmos5l_caravel_openframe.gds.gz, top level cell name is
# sg13cmos5l_caravel_openframe (this *is* the version with fill)
#
# Set environment variable PROJECT to the name of the top level
# cell.  If not defined, it defaults to
# sg13cmos5l_caravel_openframe_final.
#

echo ${PROJECT:=sg13cmos5l_caravel_openframe_final}

echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

klayout -b -zz -r ${PDK_ROOT}/${PDK}/libs.tech/klayout/tech/drc/ihp-sg13cmos5l.drc -rd input=../gds/${PROJECT}.gds.gz -rd report=../validate/${PROJECT}.lyrdb -rd feol=True -rd beol=True -rd conn_drc=True -rd wedge=True -rd run_mode=deep -rd thr=16 -rd topcell=${PROJECT}

echo "Done!"
exit 0
