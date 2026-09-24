#!/usr/bin/env python3
"""Measure the control polarity of every analog switch and power gate.

WHY THIS EXISTS.  The Verilog models of the switches are behavioural, so
nothing in the digital flow can catch a switch whose control is wired the
wrong way round.  The IP README records that this has already happened
once:  the first power stage, with the waffle pMOS, has an INVERTED
enable, and the mitigation was to rename the port from "enable" to
"nenable".  A name is a convention, not a check.  This measures the
device behaviour instead.

For each cell it runs a transient with the control low and then high, and
measures the resistance between the switched terminals at each level.
A switch is "active high" if it conducts with the control high.  The
measured sense is compared against the sense implied by the port name.

Requires ngspice with OSDI support and the IHP PDK.  NOTE that ngspice
reads .spiceinit from the CURRENT DIRECTORY or $HOME only, and the PDK's
copy -- which loads the psp103 OSDI objects the HV models need -- lives
in libs.tech/ngspice.  Without it every HV device is silently dropped
("Unknown model type psp103va") and the netlist fails to build.  This
script copies it into the working directory for that reason.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

# cell -> (control port, terminal A, terminal B, supply ports as name:volts,
#          port order in the .subckt line)
CELLS = {
    "analog_switch": dict(
        ctrl="enable", a="in", b="out", ctrl_v=1.2, sig_v=3.3,
        order="dvdd dvss avdd in avss enable out",
        supplies={"dvdd": 1.2, "dvss": 0.0, "avdd": 3.3, "avss": 0.0}),
    "analog_switch_med": dict(
        ctrl="enable", a="in", b="out", ctrl_v=1.2, sig_v=3.3,
        order="dvdd dvss avdd in avss enable out",
        supplies={"dvdd": 1.2, "dvss": 0.0, "avdd": 3.3, "avss": 0.0}),
    "analog_switch_small": dict(
        ctrl="enable", a="in", b="out", ctrl_v=1.2, sig_v=3.3,
        order="dvdd dvss avdd in avss enable out",
        supplies={"dvdd": 1.2, "dvss": 0.0, "avdd": 3.3, "avss": 0.0}),
    "analog_pswitch_small": dict(
        ctrl="enable", a="in", b="out", ctrl_v=1.2, sig_v=3.3,
        order="dvdd dvss avdd in avss enable out",
        supplies={"dvdd": 1.2, "dvss": 0.0, "avdd": 3.3, "avss": 0.0}),
    "power_stage": dict(
        ctrl="nenable", a="IOVDD_IN", b="IOVDD_OUT", ctrl_v=1.2, sig_v=3.3,
        order="nenable IOVDD_IN IOVSS DVSS DVDD IOVDD_OUT",
        supplies={"IOVSS": 0.0, "DVSS": 0.0, "DVDD": 1.2}),
    "power_stage2": dict(
        ctrl="enable", a="IOVDD_IN", b="IOVDD_OUT", ctrl_v=1.2, sig_v=3.3,
        order="enable IOVDD_IN IOVSS DVSS DVDD IOVDD_OUT",
        supplies={"IOVSS": 0.0, "DVSS": 0.0, "DVDD": 1.2}),
    "power_stage1v2": dict(
        ctrl="enable", a="DVDD_IN", b="DVDD_OUT", ctrl_v=1.2, sig_v=1.2,
        order="enable DVDD_IN DVSS DVDD_OUT",
        supplies={"DVSS": 0.0}),
}

# A switch must show at least this on/off resistance ratio for the
# measurement to be considered to have discriminated at all.
MIN_RATIO = 1e3

DECK = """* Polarity measurement for {cell}
.include {netlist}

{supplies}
Vsig {a} 0 {sig_v}
Vmeas nsw {b} 0
Rload {b} 0 1k
Vctrl {ctrl} 0 PWL (0 0 999n 0 1u {ctrl_v})
x1 {conns} {cell}

.option savecurrents
.control
save all
tran 1n 2u
let rsw = (v({a})-v({b}))/i(vmeas)
meas tran r_ctrl_low  FIND rsw AT=900n
meas tran r_ctrl_high FIND rsw AT=1.9u
.endc

.lib $PDK_ROOT/$PDK/libs.tech/ngspice/models/cornerMOShv.lib mos_tt
.lib $PDK_ROOT/$PDK/libs.tech/ngspice/models/cornerMOSlv.lib mos_tt
.lib $PDK_ROOT/$PDK/libs.tech/ngspice/models/cornerDIO.lib dio_tt
.lib $PDK_ROOT/$PDK/libs.tech/ngspice/models/cornerRES.lib res_typ
.include $PDK_ROOT/$PDK/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice
.end
"""


def build_deck(cell, spec, netlist):
    conns = []
    for port in spec["order"].split():
        if port == spec["a"]:
            conns.append(spec["a"])
        elif port == spec["b"]:
            conns.append("nsw")       # through the ammeter
        else:
            conns.append(port)
    supplies = "\n".join(
        f"V{n} {n} 0 {v}" for n, v in spec["supplies"].items())
    fmt = {k: v for k, v in spec.items()
           if k not in ("supplies", "order")}
    return DECK.format(cell=cell, netlist=netlist, supplies=supplies,
                       conns=" ".join(conns), **fmt)


def run(cell, spec, ip_dir, pdk_root, pdk, keep=False):
    netlist = os.path.join(ip_dir, "netlist", "schematic", f"{cell}.spice")
    if not os.path.exists(netlist):
        return None, f"no netlist at {netlist}"

    work = tempfile.mkdtemp(prefix=f"pol_{cell}_")
    # ngspice reads .spiceinit from the cwd;  the PDK's copy loads the
    # OSDI objects without which every HV device is dropped.
    shutil.copy(os.path.join(pdk_root, pdk, "libs.tech", "ngspice", ".spiceinit"),
                work)
    deck = os.path.join(work, "deck.spice")
    with open(deck, "w") as f:
        f.write(build_deck(cell, spec, netlist))

    env = dict(os.environ, PDK_ROOT=pdk_root, PDK=pdk)
    try:
        out = subprocess.run(["ngspice", "-b", "deck.spice"], cwd=work,
                             env=env, capture_output=True, text=True,
                             timeout=600).stdout
    except subprocess.TimeoutExpired:
        return None, "ngspice timed out"
    finally:
        if not keep:
            shutil.rmtree(work, ignore_errors=True)

    vals = {}
    for key in ("r_ctrl_low", "r_ctrl_high"):
        m = re.search(rf"^{key}\s*=\s*(\S+)", out, re.M)
        if m:
            try:
                vals[key] = float(m.group(1))
            except ValueError:
                pass
    if len(vals) != 2:
        if "psp103va" in out:
            return None, "HV models not loaded (OSDI missing) -- check .spiceinit"
        return None, "no measurement produced"
    return vals, None


def main():
    ap = argparse.ArgumentParser()
    here = os.path.dirname(os.path.abspath(__file__))
    ap.add_argument("--ip-dir", default=os.path.join(
        here, "..", "..", "dependencies", "sg13cmos5l_ocd_ip__analog_switches"))
    ap.add_argument("--pdk-root",
                    default=os.environ.get("PDK_ROOT",
                                           os.path.expanduser("~/gits/IHP-Open-PDK")))
    ap.add_argument("--pdk", default=os.environ.get("PDK", "ihp-sg13cmos5l"))
    ap.add_argument("--cell", action="append",
                    help="check only these cells (repeatable)")
    args = ap.parse_args()

    cells = args.cell or sorted(CELLS)
    print(f"{'cell':22s} {'R(ctrl=0)':>12s} {'R(ctrl=1)':>12s}  "
          f"{'measured':10s} {'from name':10s} verdict")
    print("-" * 82)

    failures = 0
    for cell in cells:
        spec = CELLS[cell]
        vals, err = run(cell, spec, os.path.abspath(args.ip_dir),
                        args.pdk_root, args.pdk)
        if err:
            print(f"{cell:22s} {'-':>12s} {'-':>12s}  {err}")
            failures += 1
            continue

        lo, hi = vals["r_ctrl_low"], vals["r_ctrl_high"]

        # A measurement that does not discriminate proves nothing.  Without
        # this guard a degenerate result still yields a polarity verdict,
        # which may agree with the port name by luck and report "ok" --
        # exactly what power_stage did on the first run of this script.
        ratio = max(lo, hi) / min(lo, hi) if min(lo, hi) > 0 else float("inf")
        if ratio < MIN_RATIO:
            print(f"{cell:22s} {lo:12.3e} {hi:12.3e}  "
                  f"INCONCLUSIVE -- on/off ratio only {ratio:.1f}, needs "
                  f"> {MIN_RATIO:g}")
            failures += 1
            continue

        measured = "active high" if hi < lo else "active low"
        # A port named n* is active low by the IP's own convention.
        by_name = "active low" if spec["ctrl"].startswith("n") else "active high"
        ok = measured == by_name
        failures += not ok
        print(f"{cell:22s} {lo:12.3e} {hi:12.3e}  {measured:10s} {by_name:10s} "
              f"{'ok' if ok else 'MISMATCH'}")

    print()
    if failures:
        print(f"{failures} problem(s).  MISMATCH means the port name and the "
              f"silicon disagree about polarity;  INCONCLUSIVE means this "
              f"deck did not manage to switch the cell, so the setup for it "
              f"needs work before its polarity can be trusted.")
    else:
        print("All switch controls behave as their port names claim.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
