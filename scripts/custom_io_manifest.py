#!/usr/bin/env python3
#---------------------------------------------------------------
# custom_io_manifest.py ---
#
# Find the custom (non-foundry) pad cells named in config.txt and
# their descriptions in the slot repositories.
#
# A slot whose config.txt entries name a pad type that is not one of
# the foundry pad types must deliver that pad in its own repository
# (the submodule dependencies/slot_<N>), on its default branch:
#
#	pads/pads.txt			manifest, one line per pad cell:
#					  <cell>  <config.txt pad>  <core-side pins...>
#					(core-side pins in order along the
#					pad's core edge;  '#' starts a comment)
#	pads/<cell>/<cell>.gds		layout, top cell <cell>
#	pads/<cell>/<cell>.spice	LVS netlist, .subckt <cell>
#
# Nothing of the pad is stored in the harness.  Used by
# scripts/setup_custom_io.py and scripts/parse_config.py.
#---------------------------------------------------------------

import os
import re
import sys

FOUNDRY_PADS = {
    'sg13cmos5l_IOPadIn',
    'sg13cmos5l_IOPadOut4mA', 'sg13cmos5l_IOPadOut16mA', 'sg13cmos5l_IOPadOut30mA',
    'sg13cmos5l_IOPadTriOut4mA', 'sg13cmos5l_IOPadTriOut16mA', 'sg13cmos5l_IOPadTriOut30mA',
    'sg13cmos5l_IOPadInOut4mA', 'sg13cmos5l_IOPadInOut16mA', 'sg13cmos5l_IOPadInOut30mA',
    'sg13cmos5l_IOPadAnalog',
}

# Ring-side pins of a custom pad:  connected like an analog pad's, not
# core signals.
RING_PINS = {'pad', 'iovdd', 'iovss', 'vdd', 'vss'}

IDXREX = re.compile(r'^s([0-9]+)_an\[([0-9]+)\]:[ \t]+([^ \t]+)[ \t]+([^ \t]+)$')


def read_config(project_path):
    """{(slot, pin): (pad_type, signal_name)} from config.txt, as parse_config.py reads it."""
    padlist = {}
    with open(os.path.join(project_path, 'config.txt')) as ifile:
        for line in ifile.read().splitlines():
            m = IDXREX.match(line)
            if m:
                padlist[m.group(1), m.group(2)] = [m.group(3), m.group(4)]
    return padlist


def custom_pads(project_path, padlist=None):
    """{cell: {'slot': N, 'pins': [...], 'dir': <path of pads/<cell>>, 'index': k}}
    for every non-foundry pad type in config.txt.  Exits with an error
    message if a slot does not deliver a pad its config.txt entry names."""
    if padlist is None:
        padlist = read_config(project_path)
    found = {}
    for (slot, pin), (pad_type, signal) in sorted(padlist.items()):
        if pad_type in FOUNDRY_PADS or pad_type in found:
            continue
        padsdir = os.path.join(project_path, 'dependencies', 'slot_' + slot, 'pads')
        manifest = os.path.join(padsdir, 'pads.txt')
        if not os.path.isfile(manifest):
            sys.exit(f'Error:  s{slot}_an[{pin}] is "{pad_type}", which is not a foundry pad type, and\n'
                     f'        {os.path.relpath(manifest, project_path)} does not exist.\n'
                     f'        Run "make projects SLOTS={slot}" first, or check the pad type.')
        entries = []
        with open(manifest) as ifile:
            for line in ifile:
                line = line.split('#', 1)[0].split()
                if line:
                    entries.append(line)
        names = [e[0] for e in entries]
        if pad_type not in names:
            sys.exit(f'Error:  pad type "{pad_type}" (s{slot}_an[{pin}]) is not listed in\n'
                     f'        {os.path.relpath(manifest, project_path)}')
        k = names.index(pad_type)
        entry = entries[k]
        celldir = os.path.join(padsdir, pad_type)
        for ext in ('gds', 'spice'):
            f = os.path.join(celldir, pad_type + '.' + ext)
            if not os.path.isfile(f):
                sys.exit(f'Error:  {os.path.relpath(f, project_path)} is missing')
        found[pad_type] = {'slot': slot, 'pins': entry[2:], 'dir': celldir, 'index': k}
    return found


def mag_core_pins(project_path, cell):
    """Port names of magic/custom_io/<cell>.mag minus the ring-side pins."""
    magfile = os.path.join(project_path, 'magic', 'custom_io', cell + '.mag')
    if not os.path.isfile(magfile):
        sys.exit(f'Error:  magic/custom_io/{cell}.mag does not exist.  Run "make custom-io" first.')
    ports, last = set(), None
    with open(magfile) as ifile:
        for line in ifile.read().splitlines():
            if line.startswith('rlabel') or line.startswith('flabel'):
                last = line.split()[-1]
            elif line.startswith('port ') and last:
                ports.add(last)
    return ports - RING_PINS
