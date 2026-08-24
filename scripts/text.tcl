#-----------------------------------------------------------------------------
# text.tcl:  Procedures to format a text string from a layout character set.
#
# Source this script in magic to define the procedures.
#
# Usage:
#	hex_format <string>	Create a hex number with "hexdigits"
#	text_format <string>	Create a text string with "alpha"
#
# Examples:
#	hex_format 129A35FB
#	text_format "\"Sailing the ICs\""
#
#-----------------------------------------------------------------------------

namespace path {::tcl::mathop ::tcl::mathfunc}

# Add a path to the search path but only if it's not there already
proc addnewpath {newpath} {
    set searchpaths [path search]
    foreach path $searchpaths {
	if {$path == $newpath} {return}
    }
    addpath $newpath
}

# Generate a layout string from the "hexdigits" library
proc hex_format {text} {
    units microns
    addnewpath hexdigits
    for {set i 0} {$i < [string length $text]} {incr i} {
	set char [string toupper [string index $text $i]]
	pushbox
        getcell alpha_$char child 0 0
	set charbbox [cellname property alpha_$char FIXED_BBOX]
	set charwidth [- [lindex $charbbox 2] [lindex $charbbox 0]]
	popbox
	box move e $charwidth
    }
}

# Generate a layout string from the "alpha" library
proc text_format {text} {
    units microns
    addnewpath alpha
    for {set i 0} {$i < [string length $text]} {incr i} {
	set char [string index $text $i]
        set ccode [scan $char %c]
        set hexcode [format %02X $ccode]
	pushbox
        getcell font_$hexcode child 0 0
	set charbbox [cellname property font_$hexcode FIXED_BBOX]
	set charwidth [- [lindex $charbbox 2] [lindex $charbbox 0]]
	# Keep the space of space characters but not the cell
	if {$ccode == 32} {delete}
	popbox
	box move e $charwidth
    }
}
