#! /bin/bash
#
# get_project_gds.sh ---
#
# Find each user project's GDS in its submodule and write the Tcl that
# drops those layouts into the chip top level.  Run from the repository
# top level:
#
#	scripts/get_project_gds.sh [options] [<slot> ...]
#
#	  -n, --dry-run	  say what would be written, write nothing
#	  -h, --help
#
# The output is scripts/user_projects.tcl, which run_gen_prefill_gds.sh
# sources while the chip top level is the edit cell.  Each populated slot
# contributes a "gds read" of the user's file and a "getcell" that places
# it over the matching slot wrapper.  Nothing else needs to source it:
# run_gen_filled_final_gds.sh builds from the pre-fill GDS, which by then
# already contains the projects.
#
# Users are instructed to provide a file named slot_<N>.gds holding a top
# cell of the same name, generated with full hierarchical processing.  It
# is read with "gds readonly true" so that it goes in verbatim.
#
# Reading it read-only is not by itself enough to keep user cell names
# apart.  A read-only cell records the byte range of its own definition in
# GDS_START and GDS_END, and magic copies exactly that range back out, so
# the names inside it survive untouched and two users who both started
# from slot<N>_wrapper.gds would collide.  Clearing GDS_END and setting
# GDS_START to 0 makes magic take the whole file instead and give every
# cell below the top level a unique prefix.  The top cell keeps its name,
# which is why that name has to be agreed in advance.
#
# WHERE THE GDS IS LOOKED FOR, in order:
#
#	<repo>/final/gds/	the structure IHP prefers
#	<repo>/gds/		the structure this project prefers
#	anywhere in <repo>	last resort, for any other layout
#
# Both slot_<N>.gds and slot_<N>.gds.gz are accepted, but finding both is
# an error rather than a preference:  the point of this script is to pin
# down exactly what went into a tapeout, and quietly choosing one of two
# candidates is the kind of decision nobody discovers until they ask which
# one shipped.  A slot with no project assigned in config.txt is skipped
# without complaint;  every other failure is reported, all slots are
# processed regardless, and the exit status is nonzero if any failed.
#
# WHY THE PLACEMENTS COME FROM MAGIC AND NOT FROM THE .mag FILES.  The
# positions exist already, as the transforms on the slot<N>_wrapper_0
# instances in chipalooza_frame.  Reading them out of the file by hand is
# a trap:  .mag integers are internal units scaled by the "magscale" line
# at the top of each file, and the two files involved here do not agree
# --- chipalooza_frame.mag is "magscale 1 2" (200 units/micron) while
# sg13cmos5l_ocd_chipalooza.mag has no magscale line at all (100 units/
# micron).  Composing across them gives every project a position wrong by
# a factor of two on the frame offset, which is 8.05um of silent, DRC-
# clean misplacement.  So this script asks magic, with "units microns" in
# force, and merely transcribes the answer.  Only the mirror flag is read
# from the file, as the sign of the transform's first element, which no
# scaling can affect.
#
#--------------------------------------------------------------------

set -u

config="config.txt"
depdir="dependencies"
magdir="magic"
frame="chipalooza_frame"
topcell="sg13cmos5l_ocd_chipalooza"
outfile="scripts/user_projects.tcl"
nslots=18

export PDK_ROOT=${PDK_ROOT:-/home/tim/gits}
export PDK=${PDK:-ihp-sg13cmos5l}

dryrun=0
slots=()

usage() {
    awk 'NR >= 3 { if (/^#-----/) exit; sub(/^# ?/, ""); print }' "$0"
    exit 0
}

note() { echo "$@"; }
warn() { echo "$@" >&2; }

#--------------------------------------------------------------------

# Add two micron values and format the result.  Four SIGNIFICANT digits
# is not enough: the grid here is 0.005um, and %.4g silently turned
# 1379.95 into 1380 --- a 0.05um misplacement that nothing downstream
# would have complained about.  Four DECIMAL places covers the grid;
# trailing zeros are trimmed only for legibility.

um_sum() {		# $1 + $2, in microns
    awk -v a="$1" -v b="$2" 'BEGIN {
	s = sprintf("%.4f", a + b);
	sub(/0+$/, "", s); sub(/\.$/, "", s);
	print s;
    }'
}

config_field() {	# $1 = key, $2 = field number within the value
    awk -v key="$1:" -v fld="$2" '
	{ sub(/#.*/, "") }
	$1 == key { $1 = ""; n = split($0, a); print (fld <= n ? a[fld] : ""); exit }
    ' "$config"
}

usable_url() {
    case "$1" in
	"") return 1 ;;
	*://*/?*) return 0 ;;
	*@*:?*)   return 0 ;;
	*) return 1 ;;
    esac
}

#--------------------------------------------------------------------
# Ask magic where every slot wrapper sits, in microns.
#
# The wrapper bounding boxes come from chipalooza_frame, in the frame's
# own coordinates;  the frame is then instantiated in the top level at an
# offset, which is the difference between the frame instance's box as the
# top level sees it and the frame's box in its own right.  Both are read
# with "units microns" so no scaling arithmetic is needed here.

declare -A WBOX	  # slot -> "llx lly urx ury", frame coordinates, microns
OFFX=""
OFFY=""

query_placements() {
    local out rc
    out=$(cd "$magdir" && magic -dnull -noconsole \
	    -rcfile "${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc" 2>&1 <<EOF
drc off
crashbackups stop
locking disable
source ../scripts/layout_setup.tcl
units microns
load $frame
select top cell
expand
puts "QFRAME [box values]"
for {set i 1} {\$i <= $nslots} {incr i} {
    select cell slot\${i}_wrapper_0
    puts "QWRAP \$i [box values]"
}
load $topcell
select top cell
expand
select cell ${frame}_wrapper_0
puts "QINST [box values]"
quit -noprompt
EOF
    )
    rc=$?

    local fllx flly illx illy
    fllx=$(echo "$out" | awk '$1 == "QFRAME" { print $2; exit }')
    flly=$(echo "$out" | awk '$1 == "QFRAME" { print $3; exit }')
    illx=$(echo "$out" | awk '$1 == "QINST"  { print $2; exit }')
    illy=$(echo "$out" | awk '$1 == "QINST"  { print $3; exit }')

    if [ -z "$fllx" ] || [ -z "$illx" ]; then
	warn "get_project_gds.sh: magic did not report the frame placement."
	warn "(exit $rc)  Output was:"
	echo "$out" | tail -20 >&2
	return 1
    fi

    OFFX=$(um_sum "$illx" "-$fllx")
    OFFY=$(um_sum "$illy" "-$flly")

    local n line count=0
    while read -r n line; do
	[ -n "$n" ] || continue
	WBOX[$n]="$line"
	count=$((count + 1))
    done < <(echo "$out" | awk '$1 == "QWRAP" { print $2, $3, $4, $5, $6 }')

    if [ $count -ne $nslots ]; then
	warn "get_project_gds.sh: magic reported $count wrapper positions, expected $nslots."
	return 1
    fi
    return 0
}

# The mirror flag is the sign of the transform's first element on the
# slot<N>_wrapper_0 instance.  A sign is immune to magscale, so this one
# fact is safe to read straight out of the file.

mirrored() {		# $1 = slot;  true if the wrapper is flipped in X
    local a
    a=$(awk -v want="slot$1_wrapper_0" '
	$1 == "use" && $3 == want { inuse = 1; next }
	inuse && $1 == "transform" { print $2; exit }
	inuse && $1 == "use" { inuse = 0 }
    ' "$magdir/$frame.mag")
    [ "$a" = "-1" ]
}

#--------------------------------------------------------------------
# Locate one slot's GDS.  Prints the path;  a diagnostic goes to stderr
# and the return code says what happened.

find_slot_gds() {	# $1 = slot
    local n="$1" dir="$depdir/slot_$1" d found=() f
    local -a dirs=("$dir/final/gds" "$dir/gds")

    for d in "${dirs[@]}"; do
	[ -d "$d" ] || continue
	found=()
	for f in "$d/slot_$n.gds" "$d/slot_$n.gds.gz"; do
	    [ -f "$f" ] && found+=("$f")
	done
	if [ ${#found[@]} -eq 2 ]; then
	    warn "slot_$n: ERROR both slot_$n.gds and slot_$n.gds.gz exist in $d/"
	    warn "    remove one;  which of the two shipped must not be a guess."
	    return 1
	fi
	if [ ${#found[@]} -eq 1 ]; then
	    echo "${found[0]}"
	    return 0
	fi
	# The directory exists but holds no slot_<N>.gds.  Fall through to
	# the next tier rather than stopping;  a repository may well have
	# a gds/ directory full of something else.
    done

    # Last resort:  anywhere in the submodule.
    found=()
    while IFS= read -r f; do
	found+=("$f")
    done < <(find "$dir" -name "slot_$n.gds" -o -name "slot_$n.gds.gz" 2>/dev/null | sort)

    if [ ${#found[@]} -eq 0 ]; then
	warn "slot_$n: ERROR no slot_$n.gds or slot_$n.gds.gz anywhere in $dir/"
	return 1
    fi
    if [ ${#found[@]} -gt 1 ]; then
	warn "slot_$n: ERROR more than one candidate:"
	printf '        %s\n' "${found[@]}" >&2
	warn "    leave exactly one;  which of them shipped must not be a guess."
	return 1
    fi
    warn "slot_$n: note --- found outside final/gds/ and gds/:  ${found[0]}"
    echo "${found[0]}"
    return 0
}

#--------------------------------------------------------------------

while [ $# -gt 0 ]; do
    case "$1" in
	-n|--dry-run)	dryrun=1 ;;
	-h|--help)	usage ;;
	[1-9]|1[0-8])	slots+=("$1") ;;
	*)
	    warn "get_project_gds.sh: unrecognized argument \"$1\""
	    warn "Try \"get_project_gds.sh --help\"."
	    exit 1
	    ;;
    esac
    shift
done

if [ ! -f "$config" ] || [ ! -d .git ]; then
    warn "get_project_gds.sh: run this from the repository top level."
    exit 1
fi

if [ ${#slots[@]} -eq 0 ]; then
    for n in $(seq 1 $nslots); do slots+=("$n"); done
fi

note "Reading slot wrapper placements from magic ..."
query_placements || exit 1
note "  frame offset in the top level:  $OFFX $OFFY microns"
note ""

#--------------------------------------------------------------------
# Work out what goes in the file before writing any of it, so that a
# failure does not leave a half-written script behind.

failed=0
placed=()
empty=()
declare -A GDSPATH ANCHORX ANCHORY MIRROR

for n in "${slots[@]}"; do
    url=$(config_field "s${n}_source" 1)
    if ! usable_url "$url"; then
	empty+=("$n")
	continue
    fi
    if [ ! -d "$depdir/slot_$n" ] || [ -z "$(ls -A "$depdir/slot_$n" 2>/dev/null)" ]; then
	warn "slot_$n: ERROR $depdir/slot_$n is not populated --- run \"make projects\""
	failed=$((failed + 1))
	continue
    fi

    gds=$(find_slot_gds "$n") || { failed=$((failed + 1)); continue; }

    set -- ${WBOX[$n]}
    llx="$1"; lly="$2"; urx="$3"
    # getcell anchors the cell's own origin, not its bounding box, so a
    # project that does not fill its slot still lands correctly.  Under a
    # horizontal flip the origin maps to the RIGHT edge of the placement.
    if mirrored "$n"; then
	MIRROR[$n]="h"
	ANCHORX[$n]=$(um_sum "$urx" "$OFFX")
    else
	MIRROR[$n]=""
	ANCHORX[$n]=$(um_sum "$llx" "$OFFX")
    fi
    ANCHORY[$n]=$(um_sum "$lly" "$OFFY")
    GDSPATH[$n]="$gds"
    placed+=("$n")
done

for n in "${placed[@]}"; do
    note "slot_$n: ${GDSPATH[$n]}"
    note "    place at ${ANCHORX[$n]} ${ANCHORY[$n]}${MIRROR[$n]:+  (flipped in X)}"
done
[ ${#empty[@]} -gt 0 ] && note "" && note "No project assigned:  ${empty[*]}"

if [ $dryrun -eq 1 ]; then
    note ""
    note "(dry run --- $outfile not written)"
    [ $failed -gt 0 ] && exit 1
    exit 0
fi

#--------------------------------------------------------------------
# Write the Tcl.  All GDS is read first and the top level loaded once,
# so that the placements are not interleaved with reads that change the
# edit cell underneath them.

{
    echo "#"
    echo "# user_projects.tcl --- GENERATED by scripts/get_project_gds.sh"
    echo "#"
    echo "# Do not edit.  Regenerate with \"make projects-gds\" whenever a user"
    echo "# project GDS changes or a slot moves in chipalooza_frame."
    echo "#"
    echo "# Sourced from run_gen_prefill_gds.sh with $topcell"
    echo "# as the edit cell, from the magic/ directory.  The final (filled) GDS"
    echo "# is built from the pre-fill GDS and so needs no separate placement."
    echo "#"
    if [ ${#placed[@]} -gt 0 ]; then
	echo "# Projects placed:      ${placed[*]}"
    else
	echo "# Projects placed:      (none)"
    fi
    if [ ${#empty[@]} -gt 0 ]; then
	echo "# Slots left empty:     ${empty[*]}"
    fi
    echo "#"
    echo ""
    echo "# Positions are in microns, so that the internal-unit scaling of any"
    echo "# .mag file cannot come into it."
    echo "units microns"
    echo ""
    echo "# readonly drops each user GDS in verbatim.  The GDS_START/GDS_END"
    echo "# properties are cleared per cell below, which is what makes magic"
    echo "# prefix the subcells so user cell names cannot collide.  This must"
    echo "# be done in conjunction with the noduplicates option, otherwise"
    echo "# name collision can still occur when reading the cells."
    echo "gds readonly true"
    echo "gds drccheck off"
    echo "gds noduplicates true"
    echo ""
    for n in "${placed[@]}"; do
	echo "gds read ../${GDSPATH[$n]}"
    done
    echo "# Slots whose GDS turned out not to contain the expected top level"
    echo "# cell.  A missing cell is recorded here and the slot is skipped at"
    echo "# placement time below, so that one bad project leaves its own slot"
    echo "# empty rather than aborting magic and losing the whole chip GDS."
    echo "set missing_slots {}"
    echo ""
    for n in "${placed[@]}"; do
	echo "# slot $n --- ${GDSPATH[$n]}"
	echo "if {[lsearch [cellname list allcells] slot_$n] < 0} {"
	echo "    puts \"ERROR: slot_$n.gds contains no cell named slot_$n\""
	echo "    puts \"       slot $n not placed:  no getcell was done.\""
	echo "    puts \"       NOTE:  if the project was laid out directly in\""
	echo "    puts \"       slot${n}_wrapper it replaces the harness wrapper of\""
	echo "    puts \"       that name and may still appear in the chip anyway.\""
	echo "    puts \"       Check the slot visually, and rely on chip level LVS\""
	echo "    puts \"       to confirm the slot pins survived.\""
	echo "    lappend missing_slots $n"
	echo "} else {"
	echo "    load slot_$n"
	echo "    # Properties apply to the current edit cell, so these must stay"
	echo "    # inside the else, after the load."
	echo "    property GDS_END \"\""
	echo "    property GDS_START 0"
	echo "    property LEFview true"
	echo "}"
    done
    echo ""
    echo "load $topcell"
    echo ""
    for n in "${placed[@]}"; do
        echo "if {[lsearch \$missing_slots $n] >= 0} {"
        echo "    puts \"skipping slot $n (top level cell not found)\""
        echo "} else {"
        echo "    # Remove any existing slot instance"
        echo "    if {[instance list exists slot_${n}_0] != \"\"} {"
        echo "        select cell slot_${n}_0"
        echo "        delete"
        echo "    }"
	if [ -n "${MIRROR[$n]}" ]; then
	    echo "    getcell slot_$n h child 0 0 parent ${ANCHORX[$n]} ${ANCHORY[$n]}"
	else
	    echo "    getcell slot_$n child 0 0 parent ${ANCHORX[$n]} ${ANCHORY[$n]}"
	fi
        echo "}"
	echo ""
    done
    echo "# Final tally, so a missing slot cannot scroll past unnoticed in"
    echo "# magic's output."
    echo "if {[llength \$missing_slots] > 0} {"
    echo "    puts \"\""
    echo "    puts \"WARNING: slot(s) not placed, no top level cell found: \$missing_slots\""
    echo "    puts \"The chip GDS was still written.  Those slots are empty unless\""
    echo "    puts \"the project was laid out directly in its slotN_wrapper cell.\""
    echo "    puts \"\""
    echo "}"
} > "$outfile"

note ""
note "Wrote $outfile (${#placed[@]} project(s) placed)."

if [ $failed -gt 0 ]; then
    warn ""
    warn "$failed slot(s) had problems (see above).  $outfile was written for"
    warn "the slots that succeeded, but the chip is not complete."
    exit 1
fi
exit 0
