#!/usr/bin/env python3
#---------------------------------------------------------------
# setup_custom_io.py --- import the custom pad cells named in
# config.txt from their slot repositories into magic/custom_io/.
#
# Companion of scripts/setup.sh (which imports the foundry libraries).
# Run from the repository top level, after "make projects" and before
# "make config":
#
#	make custom-io		(= ./scripts/setup_custom_io.py)
#
# For every non-foundry pad type in config.txt (see
# custom_io_manifest.py for where the slot repository keeps it):
#   1. dependencies/slot_<N>/pads/<cell>/<cell>.gds is copied to
#      magic/custom_io/gds/<cell>.gds, and its sub-cells are renamed
#      with a per-pad prefix (custom_io_uniquify.py) into
#      magic/custom_io/gds/<cell>.uniq.gds:  pads of different slots
#      may share sub-cell names with different content, and magic reads
#      the GDS "readonly", i.e. it copies each cell's bytes on output;
#   2. magic reads the .uniq.gds like setup.sh reads the foundry
#      library (gds readonly, gds rescale false), writes the .mag views
#      to magic/custom_io/, and sets FIXED_BBOX 0 0 80 180 um, the pad
#      pitch of the ring (the foundry pads get it from their LEF);
#   3. netlist/schematic/custom_io.spice is written from the slots'
#      pads/<cell>/<cell>.spice, each subcircuit once (an identical
#      second copy is dropped;  different content under one name is an
#      error).
# magic/custom_io/ and netlist/schematic/custom_io.spice are generated
# (see .gitignore), like magic/sg13cmos5l_io/.  Without custom pads in
# config.txt this script does nothing.
#---------------------------------------------------------------

import os
import re
import shutil
import subprocess
import sys

script_path = os.path.dirname(os.path.realpath(__file__))
project_path = os.path.dirname(script_path)
sys.path.insert(0, script_path)
from custom_io_manifest import custom_pads

PDK_ROOT = os.environ.get('PDK_ROOT', '/home/tim/gits')
PDK = os.environ.get('PDK', 'ihp-sg13cmos5l')

pads = custom_pads(project_path)
if not pads:
    print('No custom pad types in config.txt;  nothing to do.')
    sys.exit(0)

magdir = os.path.join(project_path, 'magic', 'custom_io')
gdsdir = os.path.join(magdir, 'gds')
shutil.rmtree(magdir, ignore_errors=True)
os.makedirs(gdsdir)

magicrc = os.path.join(PDK_ROOT, PDK, 'libs.tech', 'magic', PDK + '.magicrc')

def run_magic(script):
    r = subprocess.run(['magic', '-dnull', '-noconsole', '-rcfile', magicrc],
                       input=script, text=True, cwd=os.path.join(project_path, 'magic'))
    if r.returncode != 0:
        sys.exit(f'magic failed (exit {r.returncode})')

prov = ['# Custom pad cells imported by scripts/setup_custom_io.py (generated; do not edit)',
        '# cell\tslot\tsource\tsub-cell prefix']
for cell, info in pads.items():
    prefix = f"cio_s{info['slot']}_{info['index']}_"
    src = os.path.join(info['dir'], cell + '.gds')
    shutil.copyfile(src, os.path.join(gdsdir, cell + '.gds'))
    subprocess.run([sys.executable, os.path.join(script_path, 'custom_io_uniquify.py'),
                    os.path.join(gdsdir, cell + '.gds'), os.path.join(gdsdir, cell + '.uniq.gds'),
                    prefix], check=True)
    # Read from magic/ so that GDS_FILE is "custom_io/gds/...", valid from
    # magic/, where every harness script runs magic.
    run_magic(f'''drc off
crashbackups stop
locking disable
gds readonly true
gds rescale false
gds read custom_io/gds/{cell}.uniq.gds
load {cell}
cellname delete {{(UNNAMED)}}
foreach c [cellname list allcells] {{
    if {{[string match {prefix}* $c] || $c == "{cell}"}} {{
        cellname filepath $c custom_io
    }}
}}
writeall force
quit -noprompt
''')
    # Second session on the written .mag (no GDS rescaling in effect):
    # the property command takes lambda (2 internal units at magscale
    # 1 2), so 8000 x 18000 lambda is FIXED_BBOX 0 0 16000 36000.
    run_magic(f'''drc off
crashbackups stop
locking disable
addpath custom_io
load {cell}
property FIXED_BBOX {{0 0 8000 18000}}
property LEFclass {{PAD INOUT}}
save custom_io/{cell}
quit -noprompt
''')
    prov.append(f"{cell}\t{info['slot']}\t{os.path.relpath(src, project_path)}\t{prefix}")

with open(os.path.join(magdir, 'PROVENANCE.tsv'), 'w') as f:
    f.write('\n'.join(prov) + '\n')

# The LVS netlist:  every subcircuit once
subckts, order, out = {}, [], []
rex = re.compile(r'^\.subckt\s+(\S+)', re.I)
for cell, info in pads.items():
    text = open(os.path.join(info['dir'], cell + '.spice')).read().splitlines()
    block, name = [], None
    for line in text:
        m = rex.match(line)
        if m:
            name, block = m.group(1), [line]
        elif name is not None:
            block.append(line)
            if line.lower().startswith('.ends'):
                body = '\n'.join(block)
                if name in subckts and subckts[name] != body:
                    sys.exit(f'Error:  .subckt {name} differs between the custom pad netlists')
                if name not in subckts:
                    subckts[name] = body
                    order.append(name)
                name, block = None, []
out = ['* custom_io.spice --- LVS netlist of the custom pad cells (generated by',
       '* scripts/setup_custom_io.py from the slot repositories;  do not edit).']
for cell, info in pads.items():
    out.append(f"*   {cell}:  {os.path.relpath(os.path.join(info['dir'], cell + '.spice'), project_path)}")
out.append('')
out += [subckts[n] + '\n' for n in order]
with open(os.path.join(project_path, 'netlist', 'schematic', 'custom_io.spice'), 'w') as f:
    f.write('\n'.join(out) + '\n')

print(f'Imported {len(pads)} custom pad cell(s):  ' + ', '.join(pads))
