#!/usr/bin/env python3
"""Check that the LVS harness itself works, before trusting its verdict.

A comparison that always passes is worse than no comparison, because it
reads like evidence.  This runs netgen against deliberately damaged
copies of the structural netlist:

    identity    the netlist against a copy of itself     -> must MATCH
    crossed     two bias nets swapped                    -> must FAIL
    addresses   two slots' hard-wired addresses swapped  -> must FAIL

Both injected errors are real.

The crossing is the bug found in digital_top on 2026-09-18:  biasgen
numbers its bandgap sinks 1 = 1 uA, 2 = 250 nA, while the bandgap
numbers its inputs 1 = 250 nA, 2 = 1 uA, so pairing them by ordinal
crossed the magnitudes.

The address case exists because THIS HARNESS ONCE FAILED IT.  proj_addr
was written as a literal, 5'h01 and so on, and netgen drops a constant
connection instead of comparing it --- no warning, the pin just does not
take part.  LVS reported "match uniquely" with two slots' addresses
swapped, which would have passed a chip where every project answered to
the wrong selector.  digital_top now ties those pins to DVDD/DVSS, and
this test is what stops the literals coming back.

    ./selftest.py          (or: make selftest)
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
NETLIST = os.path.join(HERE, "digital_top.struct.v")
SETUP = os.path.join(HERE, "setup.tcl")


def lvs(a, b, log):
    subprocess.run(
        ["netgen", "-batch", "lvs", f"{a} digital_top", f"{b} digital_top",
         SETUP, log],
        cwd=HERE, capture_output=True, text=True)
    with open(log) as f:
        return "Circuits match uniquely" in f.read()


def swap_slot_addresses(src):
    """Give two slots each other's hard-wired address.

    Matches on the tied form.  If proj_addr is ever written as a literal
    again this will not find it, which is itself the failure being
    guarded against --- hence the explicit error rather than a skip.
    """
    a = ".proj_addr({ DVSS, DVSS, DVSS, DVSS, DVDD })"
    b = ".proj_addr({ DVSS, DVSS, DVSS, DVDD, DVSS })"
    if a not in src or b not in src:
        sys.exit("selftest: proj_addr is not tied to DVDD/DVSS.  If it is "
                 "back to a literal, netgen is SILENTLY IGNORING the slot "
                 "addresses -- see the note at the top of this file.")
    i = src.index(a)
    out = src[:i] + b + src[i + len(a):]
    j = out.index(b, i + len(b))
    return out[:j] + a + out[j + len(b):]


def cross_bandgap_biases(src):
    """Swap the bandgap's two bias connections."""
    i = src.index("sg13cmos5l_ocd_ip__bandgap_v2 bandgap")
    j = src.index(");", i)
    blk = src[i:j]
    out = (blk.replace(".ibias1_250n(bandgap_sink2_ibias)", ".ibias1_250n(TMP)")
              .replace(".ibias2_1(bandgap_sink1_ibias)",
                       ".ibias2_1(bandgap_sink2_ibias)")
              .replace(".ibias1_250n(TMP)", ".ibias1_250n(bandgap_sink1_ibias)"))
    if out == blk:
        sys.exit("selftest: could not inject the crossing;  the bandgap "
                 "connections in digital_top.v have changed shape.  Update "
                 "cross_bandgap_biases() rather than deleting this test.")
    return src[:i] + out + src[j:]


def main():
    if not os.path.exists(NETLIST):
        sys.exit(f"selftest: {NETLIST} missing;  run 'make netlist' first.")
    src = open(NETLIST).read()
    tmp = tempfile.mkdtemp()
    ok = True
    try:
        same = os.path.join(tmp, "same.v")
        shutil.copy(NETLIST, same)
        if lvs(NETLIST, same, "selftest_identity.out"):
            print("  ok    identity compare matches")
        else:
            print("  FAIL  the netlist does not match a copy of ITSELF;  "
                  "see selftest_identity.out")
            ok = False

        for label, mangle, log in (
                ("crossed bias connection", cross_bandgap_biases,
                 "selftest_crossed.out"),
                ("swapped slot addresses", swap_slot_addresses,
                 "selftest_addresses.out")):
            bad = os.path.join(tmp, "bad.v")
            open(bad, "w").write(mangle(src))
            if lvs(NETLIST, bad, log):
                print(f"  FAIL  {label} was NOT detected;  the comparison "
                      f"is not covering those pins")
                ok = False
            else:
                print(f"  ok    {label} is detected")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print("PASS  the LVS harness has teeth" if ok else "FAIL  harness broken")
    return 0 if ok else 1


sys.exit(main())
