#!/bin/bash
#
# setup_custom_io.sh --- import the custom I/O pad cells into magic/custom_io/.
#
# Companion of scripts/setup.sh for pad cells that are NOT in the foundry
# I/O library.  Same import method as the foundry library (gds readonly,
# gds rescale false), with two additions:
#
#  1. The sub-cells of each pad GDS are first renamed with a per-pad
#     prefix (scripts/custom_io_uniquify.py), because the custom pads share
#     sub-cell names with different content, and readonly GDS is copied
#     to the output byte for byte.
#  2. The top cell gets FIXED_BBOX 0 0 80 180 um, the 80 um ring pitch of
#     the foundry pads (which get it from the foundry LEF).  The geometry
#     extends 0.62 um beyond on both sides, exactly as in the foundry pads.
#
# Unlike magic/sg13cmos5l_io/, magic/custom_io/ is tracked in git:  the
# source GDS, the uniquified GDS and the generated .mag are all committed.
#
# Usage (from the repository top level):
#	export PDK_ROOT=/foss/pdks PDK=ihp-sg13cmos5l
#	./scripts/setup_custom_io.sh
#
# CUSTOM_IO lists each custom pad cell and its sub-cell prefix.

export PDK_ROOT=${PDK_ROOT:-/home/tim/gits}
export PDK=${PDK:-ihp-sg13cmos5l}

CUSTOM_IO="sg13cmos5l_IOPadDiff2Single:cm_d2s_ sg13cmos5l_IOPadSingle2Diff:cm_s2d_"

cd magic/custom_io || exit 1
for entry in $CUSTOM_IO; do
    cell=${entry%%:*}
    prefix=${entry##*:}
    python3 ../../scripts/custom_io_uniquify.py gds/${cell}.gds gds/${cell}.uniq.gds ${prefix} || exit 1
    rm -f ${prefix}*.mag ${cell}.mag
done
cd ..

# Read from magic/ so that GDS_FILE in the .mag files is "custom_io/gds/...",
# valid from magic/, where every harness script runs magic.
for entry in $CUSTOM_IO; do
    cell=${entry%%:*}
    prefix=${entry##*:}
    magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << ENDMAGIC
drc off
crashbackups stop
locking disable
gds readonly true
gds rescale false
gds read custom_io/gds/${cell}.uniq.gds
load ${cell}
cellname delete {(UNNAMED)}
foreach c [cellname list allcells] {
    if {[string match ${prefix}* \$c] || \$c == "${cell}"} {
        cellname filepath \$c custom_io
    }
}
writeall force
quit -noprompt
ENDMAGIC
    # Second pass on the written .mag (magscale 1 2, no GDS rescaling in
    # effect):  set the ring pitch 80 um x 180 um.  The property command
    # takes lambda (2 internal units at magscale 1 2), so 8000 x 18000
    # lambda is written as FIXED_BBOX 0 0 16000 36000, as in the foundry pads.
    magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << ENDMAGIC
drc off
crashbackups stop
locking disable
addpath custom_io
load ${cell}
property FIXED_BBOX {0 0 8000 18000}
property LEFclass {PAD INOUT}
save custom_io/${cell}
quit -noprompt
ENDMAGIC
done
echo "Done!"
exit 0
