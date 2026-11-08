#----------------------------------------------------------------
# custom_io.tcl --
#
# Label procedures for custom (non-foundry) I/O pad cells, the
# counterpart of label_right_analog / label_left_analog in
# gen_padframe_template.tcl.  Sourced by gen_padframe.tcl (only used
# if config.txt names a custom pad type) and by
# run_update_frame_custom_io.sh.  Units:  microns.
#
# A custom pad brings each core-side signal out on Metal2 at the
# core edge of the pad (0.29 um wide stubs, pitch down to 0.54 um).
# Per pin, label_<side>_custom paints, in the cell being edited:
#
#   - a Via2 (0.2 x 0.2) on the pad's own M2 stub, 0.05 um inside the
#     pad's core edge (M2 enclosure >= 0.04 at the sides),
#   - a Metal3 strap 0.29 um wide from 0.3 um inside the pad edge
#     to 1.1 um outside it (into the core = the slot area), like the
#     1.1 um strip of label_right_analog,
#   - a label with port on the part of the strap outside the pad.
#
# At 0.54 um pitch the straps are 0.25 um apart (Metal3 min. 0.21).
# The via and the strap inside the pad touch nothing of the pad but
# its pin stub (pad Metal3 ends 2 um from the core edge).
#----------------------------------------------------------------

# Return the strap geometry {via m3 label} as three boxes {llx lly urx ury}
# for pin "pin_name" of pad instance "pad_name".  side is "right" (pad
# rotated 270, core edge = west edge) or "left" (pad rotated 90, core
# edge = east edge).
proc custom_io_rects {side pad_name pin_name} {
    set ibox [instance list abutment $pad_name]
    goto ${pad_name}/${pin_name}
    set lbox [box values]
    set yc [expr {([lindex $lbox 1] + [lindex $lbox 3]) / 2.0}]
    # Everything is placed on the 10 nm grid:  the padframe session runs
    # on a 10 nm internal grid and rounds finer coordinates, and the
    # chipalooza_frame copy (run_update_frame_custom_io.sh) must be
    # identical.  The 0.29 um strap and the 0.2 um via start at the 10 nm
    # position at or just below (pin center - half width):  at most 5 nm
    # off the pin (M2 enclosure of the via >= 0.04 along the edge, 0.05
    # at the pad edge).
    set yc [expr {round($yc * 200.0) / 200.0}]
    set y0 [expr {floor(($yc - 0.145) * 100.0 + 1e-6) / 100.0}]
    set y1 [expr {$y0 + 0.29}]
    set v0 [expr {floor(($yc - 0.1) * 100.0 + 1e-6) / 100.0}]
    set v1 [expr {$v0 + 0.2}]
    if {$side == "right"} {
	set xe [lindex $ibox 0]
	set via [list [expr {$xe + 0.05}] $v0 [expr {$xe + 0.25}] $v1]
	set m3  [list [expr {$xe - 1.1}] $y0 [expr {$xe + 0.3}] $y1]
	set lab [list [expr {$xe - 1.1}] $y0 [expr {$xe - 0.3}] $y1]
    } else {
	set xe [lindex $ibox 2]
	set via [list [expr {$xe - 0.25}] $v0 [expr {$xe - 0.05}] $v1]
	set m3  [list [expr {$xe - 0.3}] $y0 [expr {$xe + 1.1}] $y1]
	set lab [list [expr {$xe + 0.3}] $y0 [expr {$xe + 1.1}] $y1]
    }
    return [list $via $m3 $lab]
}

proc custom_io_paint {rects pin_text {with_via 1}} {
    lassign $rects via m3 lab
    if {$with_via} {
	box values {*}$via
	paint via2
    }
    box values {*}$m3
    paint m3
    box values {*}$lab
    label $pin_text FreeSans 0.3 0 0 0 c m3
    port make
}

# Label a custom pad core pin on the right / left side (padframe).
proc label_right_custom {pad_name pin_name pin_text} {
    custom_io_paint [custom_io_rects right $pad_name $pin_name] $pin_text 1
}

proc label_left_custom {pad_name pin_name pin_text} {
    custom_io_paint [custom_io_rects left $pad_name $pin_name] $pin_text 1
}
