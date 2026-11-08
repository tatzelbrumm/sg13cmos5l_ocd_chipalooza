#!/bin/bash
# LVS of slot 7 with the harness's own tools (magic extraction + netgen), as a substitute for
# the full "make lvs-top" (see RUNLOG):  dependencies/slot_7/final/gds/slot_7.gds against the
# slot repository's netlist dependencies/slot_7/netlist/slot_7.spice.
# Run from the repository top level.  Output: validate/comp_slot_7.out
set -e
export PDK_ROOT=${PDK_ROOT:-/foss/pdks} PDK=${PDK:-ihp-sg13cmos5l}
mkdir -p netlist/layout
cd magic
magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable
source ../scripts/layout_setup.tcl
gds read ../dependencies/slot_7/final/gds/slot_7.gds
# slot_7.gds has a cell named like the device it holds, pnpMPA (netgen: "Class pnpMPA is instanced
# inside of itself").  Rename the cell; netgen then flattens it.  (gds flatglob instead loses the
# device.)  The "$$$CONTEXT_INFO$$$" read error is harmless (KLayout PCell metadata, not instanced.)
cellname rename pnpMPA pnpMPA_cell
load slot_7
select top cell
extract path extfiles
extract no all
extract do unique
extract all
ext2spice lvs
ext2spice -p extfiles -o ../netlist/layout/slot_7.spice
quit -noprompt
EOF
cd ../validate
# schematic side:  IHP standard cells + the slot repository's complete LVS netlist slot_7.cdl
# (slot_7.spice defines only the top levels; its sub-blocks would be black boxes)
cat ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice ../dependencies/slot_7/netlist/slot_7.cdl \
    | sed -E 's/^([MQR])([^ ]+ )/X\1\2/' > slot_7_schem.spice
# (CDL writes devices as M, Q, R cards, magic's ext2spice as X cards:  netgen gives them different pins)
netgen -batch lvs "../netlist/layout/slot_7.spice slot_7" "slot_7_schem.spice slot_7" ${PDK_ROOT}/${PDK}/libs.tech/netgen/${PDK}_setup.tcl comp_slot_7.out < /dev/null
rm -f slot_7_schem.spice
grep -n "Final result" comp_slot_7.out || true
