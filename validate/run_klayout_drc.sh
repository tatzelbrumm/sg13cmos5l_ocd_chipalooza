#!/bin/bash
#
# Run klayout DRC on the openframe test chip final version
# GDS is sg13cmos5l_caravel_openframe.gds.gz, top level cell name is
# sg13cmos5l_caravel_openframe (this is not the version with fill)
#
echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

klayout -b -zz -r ${PDK_ROOT}/${PDK}/libs.tech/klayout/tech/drc/ihp-sg13cmos5l.drc -rd input=../gds/sg13cmos5l_caravel_openframe.gds.gz -rd report=../validate/sg13cmos5l_caravel_openframe.lyrdb -rd feol=True -rd beol=True -rd conn_drc=True -rd wedge=True -rd run_mode=deep -rd thr=16 -rd topcell=sg13cmos5l_caravel_openframe

echo "Done!"
exit 0
