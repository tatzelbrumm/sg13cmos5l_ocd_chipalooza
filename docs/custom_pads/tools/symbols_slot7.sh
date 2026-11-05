#!/bin/bash
# Regenerate only the slot 7 wrapper symbol and _lvs.v (scripts/gen_xschem_sym.py slot7_wrapper).
# Workaround for a defect in main, not in slot 7:  the regenerated magic/slot6_wrapper.mag has
# port 119 under two names (s6_an_0_esd, s6_an_0;  stale hand copies in chipalooza_frame.mag),
# and gen_xschem_sym.py reads all 18 wrappers before writing one, so it stops.  For this one run
# the committed slot6_wrapper.mag from main is put in place, then the regenerated one is restored.
# Run from the repository top level.
set -e
cp magic/slot6_wrapper.mag /tmp/slot6_wrapper.mag.regen
git show origin/main:magic/slot6_wrapper.mag > magic/slot6_wrapper.mag
python3 scripts/gen_xschem_sym.py slot7_wrapper || rc=$?
cp /tmp/slot6_wrapper.mag.regen magic/slot6_wrapper.mag
exit ${rc:-0}
