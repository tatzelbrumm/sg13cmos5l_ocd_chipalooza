#!/usr/bin/env python3
"""Census the structural netlist, and reject anything not structural.

Two jobs.

Counting INSTANCES, not lines:  an instantiation carrying a parameter
override spans several lines, which is how 38 analog_pswitch_small
instances went missing from a naive count the first time this was
written --- a miscount that looks exactly like a synthesis bug.

Rejecting CONSTANTS:  a literal on an instance pin is behavioral
verilog, not structural.  netgen currently accepts one silently and
drops the pin from the comparison, which is how 18 proj_addr buses and
40 SRAM tie-off pins came to be unchecked;  the netgen bug is filed, and
the correct behaviour there is to stop with an error.  This does that
here and now, so a literal reintroduced into digital_top.v fails at
"make netlist" with a clear message rather than quietly shrinking what
LVS covers.

A pin is tied by naming the supply net for ITS domain.  Do not expect a
tool to infer one:  this chip has AVDD/AVSS at 3.3 V and DVDD/DVSS at
1.2 V, so a bare 1'b0 does not identify a net.
"""
import collections
import re
import sys

path = sys.argv[1]
src = open(path).read()

inst = re.compile(r'^  ([A-Za-z_][\w$]*)\s*(?:#\s*\(.*?\)\s*)?\\?[\w$\[\].]+\s*\(',
                  re.M | re.S)
c = collections.Counter(inst.findall(src))
for name, n in sorted(c.items(), key=lambda kv: (-kv[1], kv[0])):
    print(f"  {n:4d}  {name}")
print(f"  {sum(c.values()):4d}  TOTAL instances")

const = re.compile(r"\.([A-Za-z_]\w*)\(\s*(\d+'[hbdoHBDO][0-9a-fA-FxzXZ_]+)\s*\)")
bad = const.findall(src)
if bad:
    print(f"\n{path}: {len(bad)} constant connection(s) -- NOT STRUCTURAL:",
          file=sys.stderr)
    for (pin, value), n in sorted(collections.Counter(bad).items()):
        times = f"   x{n}" if n > 1 else ""
        print(f"    .{pin}({value}){times}", file=sys.stderr)
    print("\nTie each of these to the supply net for its domain instead.\n"
          "netgen does not compare a literal;  it drops the pin, silently,\n"
          "so these would be excluded from LVS rather than checked by it.",
          file=sys.stderr)
    sys.exit(1)
