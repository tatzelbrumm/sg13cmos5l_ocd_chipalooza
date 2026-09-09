#!/bin/bash
#
# gen_user_wrappers.sh
#
# Run magic and source a script which creates 18 layouts, one for each slot,
# with the names "slot<N>_wrapper.mag" for <N> = 1 to 18.
#
# After this is done, the wrappers are parsed to replace any non-switched
# (global) power supply with an equivalent area of obstruction metal.
#
# The Tcl script generates the user project wrappers from the frame layout.
# This requires that the frame layout (chipalooza_frame) be completed, with
# the user project areas well-defined.  So this script must be run after the
# chipalooza_frame layout is complete.
#
# This script walks each side and copies the area inside the project area to
# a new cell, which then contains the full set of I/Os for each slot, which
# in turn depends on the user choices of pad in "config.txt" in the top level
# directory.

# This script to be run from the top level directory;  it automatically cd's
# to the magic/ directory to run magic.


echo ${PDK_ROOT:=/home/tim/gits} > /dev/null
echo ${PDK:=ihp-sg13cmos5l} > /dev/null

# Back up any existing slot wrapper layouts
for i in {1..18}; do
    [ -f "slot${i}_wrapper.mag" ] && mv "slot${i}_wrapper.mag" ../archive/
done

echo "Generating slot wrappers"

cd magic
magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
locking disable
tech unlock *

source ../scripts/layout_setup.tcl
load chipalooza_frame
select top cell
expand

units microns
snap internal

# Place box at slot 18 position
box position 279 503.95
box width 537.15
box height 273

# Generate wrapper layouts for slots 10 to 18
for {set i 18} {\$i >= 10} {incr i -1} {
    select area
    select save slot\${i}_wrapper
    box move n 275
}

# Place box at slot 1 position
box position 1363.85 503.95

# Generate wrapper layouts for slots 1 to 9
for {set i 1} {\$i <= 9} {incr i} {
    select area
    select save slot\${i}_wrapper
    box move n 275
}

# Now edit each slot wrapper in turn
for {set i 1} {\$i <= 18} {incr i} {
    load slot\${i}_wrapper
    select top cell

    # Find and replace power connections on the frame with obstructions
    set result [goto vdd1v2]
    if {\$result == "metal5"} {
	box grow c 1
	select area m5
	box select
	erase m5
	paint obsm5
    }
    # Note:  No slots have "vdd3v3" adjacent.
    # Grounds are okay to connect to, but need to have the same name as the
    # other ground connection.
    set result [goto vss1v2]
    if {\$result == "metal2"} {
	select area label
	setlabel text vss_1v2
    }
    set result [goto vss3v3]
    if {\$result == "metal2"} {
	select area label
	setlabel text vss_3v3
    }

    # Remove other stuff under the keep-out area (may need to enforce the
    # keepout area with more obstruction layers?)

    select top cell
    erase alldiff,metal1,digisub

    # Now make all of the connections into ports
    select top cell
    port makeall

    # save this result
    writeall force slot\${i}_wrapper
}

quit -noprompt
EOF

