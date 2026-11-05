#!/bin/bash
# Phase 3 DRC of the custom pad area of the padframe, against the Phase 0 baseline.
# 1. magic saves the region x 1860..2180, y 2180..2540 um (pads s6_an_1 .. s8_an_0 with spacers,
#    bond pads and the straps into the core) of the current and of the baseline padframe
#    (.mag given as $1) as a cell of its own ("select area" + "select save":  every instance
#    inside the box plus the padframe paint in it) and writes its GDS.  Writing the GDS of the
#    whole padframe took more than 15 min in the top cell and was stopped.
# 2. the PDK KLayout DRC deck (feol, beol) runs on both.
# Run from the repository top level.  Outputs in $OUT.
set -e
BASE_MAG=$1
OUT=${OUT:-/tmp/padframe_drc}; mkdir -p $OUT
cp $BASE_MAG magic/base_padframe.mag
cd magic
for v in now base; do
  src=sg13cmos5l_padframe; [ $v = base ] && src=base_padframe
  magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << ENDMAGIC
drc off
crashbackups stop
locking disable
source ../scripts/layout_setup.tcl
addpath paramcells
load $src
select top cell
units microns
box values 1860 2180 2180 2540
select area
select save clip_$v
load clip_$v
gds write $OUT/clip_$v.gds
quit -noprompt
ENDMAGIC
  rm -f clip_$v.mag
done
rm -f base_padframe.mag
cd ..
for v in now base; do
  klayout -b -zz -r ${PDK_ROOT}/${PDK}/libs.tech/klayout/tech/drc/ihp-sg13cmos5l.drc \
    -rd input=$OUT/clip_$v.gds -rd report=$OUT/clip_$v.lyrdb -rd feol=True -rd beol=True \
    -rd run_mode=deep -rd thr=4 -rd topcell=clip_$v > $OUT/drc_$v.log 2>&1
done
echo "Done!"
