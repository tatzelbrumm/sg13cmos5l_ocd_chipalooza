#!/bin/bash
# Phase 2 (ii): build the padframe with the custom pads in three variants and compare.
#  A  as committed: FIXED_BBOX set by setup_custom_io.sh, no LEF          (already built)
#  B  LEF written by magic ("lef write") and read back to annotate the .mag, like setup.sh
#  C  no FIXED_BBOX at all (shows what FIXED_BBOX does)
# Run from the repository top level.  Restores magic/custom_io/*.mag from git at the end.
set -x
H=$(pwd); OUT=$H/docs/custom_pads/lef_experiment; mkdir -p $OUT magic/custom_io/lef
cp magic/sg13cmos5l_padframe.mag $OUT/A_sg13cmos5l_padframe.mag
for c in sg13cmos5l_IOPadDiff2Single sg13cmos5l_IOPadSingle2Diff; do
cd magic; magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << ENDMAGIC
drc off
locking disable
addpath custom_io
load $c
lef write custom_io/lef/$c.lef -hide
lef read custom_io/lef/$c.lef
save custom_io/$c
quit -noprompt
ENDMAGIC
cd ..; done
make clean-config && make config && make padframe
cp magic/sg13cmos5l_padframe.mag $OUT/B_sg13cmos5l_padframe.mag
for c in sg13cmos5l_IOPadDiff2Single sg13cmos5l_IOPadSingle2Diff; do
  git checkout -- magic/custom_io/$c.mag; sed -i '/^string FIXED_BBOX/d' magic/custom_io/$c.mag; done
make clean-config && make config && make padframe
cp magic/sg13cmos5l_padframe.mag $OUT/C_sg13cmos5l_padframe.mag
git checkout -- magic/custom_io/
make clean-config && make config && make padframe
cmp magic/sg13cmos5l_padframe.mag $OUT/A_sg13cmos5l_padframe.mag
for v in B C; do echo "== A vs $v (timestamps ignored)"; diff <(grep -v '^timestamp' $OUT/A_sg13cmos5l_padframe.mag) <(grep -v '^timestamp' $OUT/${v}_sg13cmos5l_padframe.mag) | grep -c '^[<>]'; done
