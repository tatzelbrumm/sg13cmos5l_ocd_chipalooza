#-----------------------------------------------
# Tcl script for setting up magic
#-----------------------------------------------
#
# This script adds the paths to the dependent repositories, which
# allows the circuits to find all of their subcells without changing
# the contents of the submodules.
#
# Source this from the top level layout directory (../magic/).

# Analog switches library (for the power gating switch)

addpath ../dependencies/sg13cmos5l_ocd_ip__analog_switches/magic
addpath ../dependencies/sg13cmos5l_ocd_ip__analog_switches/magic/paramcells

# Bias generator library (for the bandgap, current bias generator and
# iDAC and voltage bias generator)

addpath ../dependencies/sg13cmos5l_ocd_ip__biasgen/magic
addpath ../dependencies/sg13cmos5l_ocd_ip__biasgen/magic/paramcells

# The repositories contains references to IHP standard cells, which
# are actually located here.

addpath sg13cmos5l_stdcell

# All local references should already be resolved.
