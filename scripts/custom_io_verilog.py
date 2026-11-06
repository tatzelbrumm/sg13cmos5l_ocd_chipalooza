#!/usr/bin/env python3
#---------------------------------------------------------------
# custom_io_verilog.py --- print the hand edits of the chip-core
# Verilog for slots that use custom pad cells.
#
# The chip-core views verilog/rtl/chipalooza_frame.v,
# verilog/gl/sg13cmos5l_ocd_chipalooza.v, verilog/rtl/digital_tb.v and
# verilog/rtl/slot<N>_wrapper.v are written by hand (parse_config.py
# does not generate them).  For a slot whose pads in config.txt are all
# custom pads, this script prints, file by file, the exact lines to
# find and the lines to put in their place, derived from config.txt and
# the slot's pads/pads.txt.  It changes nothing.
#
# Usage (repository top level):  ./scripts/custom_io_verilog.py
#---------------------------------------------------------------

import os
import sys
from collections import defaultdict

script_path = os.path.dirname(os.path.realpath(__file__))
project_path = os.path.dirname(script_path)
sys.path.insert(0, script_path)
from custom_io_manifest import read_config, custom_pads, FOUNDRY_PADS

padlist = read_config(project_path)
pads = custom_pads(project_path, padlist)
byslot = defaultdict(dict)
for (slot, pin), (ptype, sig) in padlist.items():
    byslot[slot][int(pin)] = (ptype, sig)

def block(title, find, replace):
    print(f'  {title}')
    print('    FIND these lines:')
    for l in find:
        print('      |' + l)
    print('    REPLACE them with:' if replace else '    DELETE them.')
    for l in replace:
        print('      |' + l)
    print()

any_slot = False
for slot in sorted(byslot, key=int):
    entries = byslot[slot]
    kinds = {ptype in pads for ptype, _ in entries.values()}
    if kinds == {False}:
        continue
    if kinds != {True}:
        print(f'slot {slot}: mixes foundry and custom pads;  edit its Verilog by hand.\n')
        continue
    any_slot = True
    n = len(entries)
    nets = []
    for pin in sorted(entries):
        ptype, sig = entries[pin]
        nets += [f'{sig}_{p}' for p in pads[ptype]['pins']]
    esd = [f's{slot}_an_{i}_esd' for i in range(n)]
    vec = f'[{n - 1}:0]'
    print(f'=== slot {slot}: {n} custom pad(s), {len(nets)} core nets: {" ".join(nets)}\n')

    print('File verilog/rtl/chipalooza_frame.v')
    block('(a) module port list',
          [f'    inout  {vec} s{slot}_an,  ' + ', '.join(f'inout {e}' for e in esd) + ','],
          [f'    inout  {x},' for x in nets])
    block(f'(b) instance slot{slot}_wrapper slot{slot} (...): connections (the _esd lines present there)',
          [f'\t.s{slot}_an(s{slot}_an),', f'\t.s{slot}_an_0_esd(s{slot}_an_0_esd),'],
          [f'\t.{x}({x}),' for x in nets])

    print('File verilog/gl/sg13cmos5l_ocd_chipalooza.v   (the chip pins s%s_an stay)' % slot)
    block('(a) wire declarations', [f'    wire {e};' for e in esd], [f'    wire {x};' for x in nets])
    block('(b) BOTH instances, padframe (...) and harness_core (...): the _esd connections',
          [f'\t.{e}({e}),' for e in esd], [f'\t.{x}({x}),' for x in nets])
    block('(c) instance harness_core (...): the pad connections',
          [f'\t.s{slot}_an_{i}(s{slot}_an[{i}]),' for i in range(n)], [])

    print('File verilog/rtl/digital_tb.v')
    block('instance chipalooza_frame harness_core (...)', [f'\t    .s{slot}_an(),'], [f'\t    .{x}(),' for x in nets])

    print(f'File verilog/rtl/slot{slot}_wrapper.v')
    block('module port list (keep the comment lines around it)',
          [f'    inout wire {vec} s{slot}_an,\t// dedicated analog pad(s)',
           f'    inout wire s{slot}_an_0_esd,\t// secondary ESD-protected pin'],
          [f'    inout wire {x},' for x in nets])

if not any_slot:
    print('No slot uses only custom pads;  nothing to edit.')
