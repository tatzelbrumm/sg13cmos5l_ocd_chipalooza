#!/bin/bash
#
# run_clean.sh --- Clean all of the generated files in preparation for a new
# run of "parse_config.py".
#
# Warning:  This script deletes stuff!
#
rm -f scripts/gen_padframe.tcl
rm -f verilog/gl/sg13cmos5l_padframe.v
rm -f verilog/gl/chipalooza_frame_wrapper.v

rm -f magic/sg13cmos5l_padframe.mag
rm -f magic/chipalooza_frame_wrapper.mag

echo "Done!"
