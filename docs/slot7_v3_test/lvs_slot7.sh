#!/bin/bash
# LVS of slot 7 v3 with the harness's tools (magic extraction + netgen):
# dependencies/slot_7/final/gds/slot_7.gds against the slot's netgen netlist
# dependencies/slot_7/netlist/slot_7_netgen.spice (X cards, complete).  v3 needs no cell rename
# (the slot renamed pnpMPA to bgc_pnpMPA).  Writes nothing into the submodule.
# Run from the repository top level.  Output: validate/comp_slot_7.out
set -e
export PDK_ROOT=${PDK_ROOT:-/foss/pdks} PDK=${PDK:-ihp-sg13cmos5l}
mkdir -p netlist/layout
cd magic
magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << MEOF
drc off
crashbackups stop
locking disable
source ../scripts/layout_setup.tcl
gds read ../dependencies/slot_7/final/gds/slot_7.gds
load slot_7
select top cell
extract path extfiles
extract no all
extract do unique
extract all
ext2spice lvs
ext2spice -p extfiles -o ../netlist/layout/slot_7.spice
quit -noprompt
MEOF
cd ../validate
cat ${PDK_ROOT}/${PDK}/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice ../dependencies/slot_7/netlist/slot_7_netgen.spice > slot_7_schem.spice
netgen -batch lvs "../netlist/layout/slot_7.spice slot_7" "slot_7_schem.spice slot_7" ${PDK_ROOT}/${PDK}/libs.tech/netgen/${PDK}_setup.tcl comp_slot_7.out < /dev/null
rm -f slot_7_schem.spice
grep -n "Final result" comp_slot_7.out || true
