#!/bin/bash
# LVS of slot 7 with the harness's own tools (magic extraction + netgen), as a substitute for
# the full "make lvs-top" (see RUNLOG):  dependencies/slot_7/final/gds/slot_7.gds against the
# slot repository's netlist dependencies/slot_7/netlist/slot_7.spice.
# Run from the repository top level.  Output: validate/comp_slot_7.out
set -e
export PDK_ROOT=${PDK_ROOT:-/foss/pdks} PDK=${PDK:-ihp-sg13cmos5l}
mkdir -p magic/extfiles_slot7 netlist/layout
cd magic
magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable
source ../scripts/layout_setup.tcl
gds read ../dependencies/slot_7/final/gds/slot_7.gds
load slot_7
select top cell
extract path extfiles_slot7
extract no all
extract do unique
extract all
ext2spice lvs
ext2spice -p extfiles_slot7 -o ../netlist/layout/slot_7.spice
quit -noprompt
EOF
cd ../validate
# schematic side:  IHP standard cells + the slot repository's netlist, in one file
cat ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice ../dependencies/slot_7/netlist/slot_7.spice > slot_7_schem.spice
netgen -batch lvs "../netlist/layout/slot_7.spice slot_7" "slot_7_schem.spice slot_7" ${PDK_ROOT}/${PDK}/libs.tech/netgen/${PDK}_setup.tcl comp_slot_7.out < /dev/null
rm -f slot_7_schem.spice
grep -n "Final result" comp_slot_7.out || true
