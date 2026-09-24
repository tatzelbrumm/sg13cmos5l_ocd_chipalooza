# netgen setup for the digital_top structural comparison.
#
# The analog switches are physically symmetric devices:  their two
# terminals are a pMOS (or transmission gate) source and drain, and
# which one is called "in" is a modelling convention, not a fact about
# the layout.  So a swap between them is NOT an error and must be
# permuted, or LVS would report a mismatch for a circuit that is
# correct.  Note the cost of this, which is real:  a genuinely reversed
# switch connection will also pass.  That is the right trade only
# BECAUSE the device is symmetric --- do not extend it to a cell where
# the two pins differ.
foreach cell {analog_switch_med analog_switch_small analog_pswitch_small} {
    permute "-circuit1 $cell" in out
    permute "-circuit2 $cell" in out
}

# The power stages are not symmetric:  IOVDD_IN comes from the pad ring
# and IOVDD_OUT feeds one project.  Reversing them would be a genuine
# error, so they are deliberately left unpermuted.
