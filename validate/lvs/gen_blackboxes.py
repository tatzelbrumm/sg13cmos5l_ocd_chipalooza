#!/usr/bin/env python3
"""Generate blackboxes.v from the real module headers.

The structural view of digital_top needs a port-only stub for every leaf
it instantiates.  Writing those by hand would be a second copy of each
port list to keep in step, and a stub whose pins have quietly drifted
from the module it stands for is worse than no stub at all:  yosys would
elaborate it without complaint and LVS would compare the wrong thing.
So they are generated from the sources, here, and regenerated whenever a
leaf changes.

    ./gen_blackboxes.py > blackboxes.v

Two transformations are applied:

  real -> wire   A real port becomes a plain wire.  yosys rejects "real"
                 outright, and structurally the distinction does not
                 exist:  it is one net either way, and only what it
                 carries differs.

  direction      An analog port becomes "inout", whatever the
                 behavioural model calls it.  The models are
                 unidirectional because a real cannot have two drivers;
                 the devices are not.
"""

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RTL = os.path.join(ROOT, "verilog", "rtl")
DEPS = os.path.join(ROOT, "dependencies")
PDK = os.path.join(os.environ.get("PDK_ROOT", os.path.expanduser("~/gits")),
                   os.environ.get("PDK", "ihp-sg13cmos5l"))

# Leaves of the structural view, in the order they are emitted.  The
# digital macros are here because they are separately placed, routed and
# LVS'd:  at this level they are correctly opaque.
SOURCES = [
    ("housekeeping_top",        os.path.join(RTL, "housekeeping_top.v")),
    ("user_project_control",    os.path.join(RTL, "user_project_control.v")),
    ("RM_IHPSG13_1P_1024x8_c2_bm_bist",
     os.path.join(PDK, "libs.ref/sg13cmos5l_sram/verilog/"
                       "RM_IHPSG13_1P_1024x8_c2_bm_bist.v")),
]
SOURCES += [(f"analog_{n}", os.path.join(
                DEPS, "sg13cmos5l_ocd_ip__analog_switches/verilog",
                f"analog_{n}.v"))
            for n in ("switch_med", "switch_small", "pswitch_small")]
SOURCES += [(f"power_{n}", os.path.join(
                DEPS, "sg13cmos5l_ocd_ip__analog_switches/verilog",
                f"power_{n}.v"))
            for n in ("stage1v2", "stage2")]
SOURCES += [(f"sg13cmos5l_ocd_ip__{n}", os.path.join(
                DEPS, "sg13cmos5l_ocd_ip__biasgen/verilog",
                f"sg13cmos5l_ocd_ip__{n}.v"))
            for n in ("bandgap_v2", "biasgen2", "voltgen_v2")]
SOURCES += [(f"slot{i}_wrapper", os.path.join(RTL, f"slot{i}_wrapper.v"))
            for i in range(1, 19)]

PORT_RE = re.compile(
    r"^\s*(input|output|inout)\s+"
    r"(?:(wire|reg|real)\s+)?"
    r"(?:(real)\s+)?"
    r"(\[[^\]]*\]\s*)?"
    r"(\w+)", re.M)


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def header(path, module):
    """The text between 'module NAME (' and the matching ');'."""
    src = strip_comments(open(path).read())
    m = re.search(r"\bmodule\s+" + re.escape(module) + r"\s*(?:#\s*\([^)]*\)\s*)?\(", src)
    if not m:
        sys.exit(f"{path}: no module {module}")
    depth, i = 1, m.end()
    while depth:
        if src[i] == "(":
            depth += 1
        elif src[i] == ")":
            depth -= 1
        i += 1
    return src[m.end():i - 1]


def body(path, module):
    """Everything between the module header and its endmodule."""
    src = strip_comments(open(path).read())
    m = re.search(r"\bmodule\s+" + re.escape(module) + r"\s*(?:#\s*\([^)]*\)\s*)?\(", src)
    depth, i = 1, m.end()
    while depth:
        if src[i] == "(":
            depth += 1
        elif src[i] == ")":
            depth -= 1
        i += 1
    end = src.find("endmodule", i)
    return src[i:end]


def ports(path, module):
    """(direction, range, name) for every port, power pins included.

    Handles both port list styles.  ANSI puts the direction in the
    header;  the SRAM model uses the older form, which lists bare names
    in the header and declares the directions in the body.  Getting the
    ORDER right matters for neither (the stub is matched by pin name),
    but getting every pin matters for both.

    USE_POWER_PINS is deliberately NOT honoured as a conditional: the
    structural view always has the supply pins, because the analog cells
    have them in the schematic.  So the `ifdef lines are simply dropped
    and everything they guard is kept.
    """
    drop = lambda t: re.sub(r"^\s*`(ifdef|ifndef|else|endif|elsif).*$", "",
                            t, flags=re.M)
    text = drop(header(path, module))

    out = []
    for direction, _kind1, _kind2, rng, name in PORT_RE.findall(text):
        if (_kind1 == "real") or (_kind2 == "real"):
            direction = "inout"
        out.append((direction, (rng or "").strip(), name))

    if not out:
        # Non-ANSI: names in the header, directions in the body.
        names = [n for n in re.findall(r"\w+", text)]
        decls = {}
        for direction, _k1, _k2, rng, name in PORT_RE.findall(
                drop(body(path, module))):
            if (_k1 == "real") or (_k2 == "real"):
                direction = "inout"
            decls[name] = (direction, (rng or "").strip())
        missing = [n for n in names if n not in decls]
        if missing:
            sys.exit(f"{path}: {module} ports with no direction: {missing}")
        out = [(decls[n][0], decls[n][1], n) for n in names]

    if not out:
        sys.exit(f"{path}: parsed no ports from {module}")
    return out


def emit(module, path):
    pp = ports(path, module)
    print(f"/* {module} --- {len(pp)} pins, from "
          f"{os.path.relpath(path, ROOT)} */")
    print("(* blackbox *)")
    print(f"module {module} (")
    for n, (direction, rng, name) in enumerate(pp):
        comma = "," if n + 1 < len(pp) else ""
        rng = (rng + " ") if rng else ""
        print(f"    {direction} wire {rng}{name}{comma}")
    print(");")
    print("endmodule")
    print()


print("/* GENERATED by validate/lvs/gen_blackboxes.py --- do not edit. */")
print("/* Port-only stubs for every leaf of digital_top's structural"
      " view. */")
print()
for module, path in SOURCES:
    emit(module, path)
