# Phase 1 test: load both custom pads and the foundry pads in ONE magic session.
# Run from magic/:  magic -dnull -noconsole -rcfile $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc < ../docs/custom_pads/tools/coexist_test.tcl
drc off
crashbackups stop
source ../scripts/layout_setup.tcl
load coexist_test -silent
box 0 0 0 0
getcell sg13cmos5l_IOPadAnalog
box move e 100
getcell sg13cmos5l_IOPadDiff2Single
box move e 100
getcell sg13cmos5l_IOPadSingle2Diff
select top cell
expand
set all [cellname list allcells]
puts "COEXIST cells loaded: [llength $all]"
puts "COEXIST d2s sub-cells: [llength [lsearch -all $all cm_d2s_*]]  s2d sub-cells: [llength [lsearch -all $all cm_s2d_*]]"
foreach c {sg13cmos5l_IOPadDiff2Single sg13cmos5l_IOPadSingle2Diff sg13cmos5l_IOPadAnalog} {
    load $c
    puts "COEXIST bbox $c: [property FIXED_BBOX]"
}
puts "COEXIST done"
quit -noprompt
