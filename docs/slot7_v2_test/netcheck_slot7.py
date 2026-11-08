#!/usr/bin/env python3
"""netcheck_slot7.py --- net-by-net check of the slot 7 custom pad connections by extraction.

Usage:
  netcheck_slot7.py <gds> <topcell> <x0> <y0> <x1> <y1> [<slot_gds> <slot_x> <slot_y>] [--merged a,b ...]

Extracts metal connectivity (Metal1..Metal4 with Via1..Via3; labels on the
drawing/text purposes of Metal2..Metal4) of <topcell> clipped to the box (um),
optionally with a slot GDS placed at (slot_x, slot_y), and reports, for every
net that carries one of the 13 expected slot 7 pin names, all label texts on that
net.  Device layers are not used, so a short shows up as foreign labels on a
net and nothing can be merged through a transistor.

Expected:  each pad core pin (pad-cell label vinp, outp, ...) is on one net with
its strap label in the padframe and its pin label in the slot (s7_an_1_vinp, ...),
nothing else;  the stand-in wiring merges outp/vinp and outn/vinn pairwise.
"""
import sys
import klayout.db as db

EXPECT = {
    's7_an_0_vref': ('vref',), 's7_an_0_outp': ('outp',), 's7_an_0_outn': ('outn',),
    's7_an_0_vcm': ('vcm',), 's7_an_0_en_3v3': ('en_3v3',), 's7_an_0_en_3v3_b': ('en_3v3_b',),
    's7_an_0_iref': ('iref',), 's7_an_1_vinp': ('vinp',), 's7_an_1_vinn': ('vinn',),
    's7_an_1_vref': ('vref',), 's7_an_1_iref': ('iref',), 's7_an_1_en_3v3_b': ('en_3v3_b',),
    's7_an_1_en_3v3': ('en_3v3',)}
# Pins that the slot ties together on purpose.  Default: the stand-in slot (outp -> vinp, outn -> vinn).
# Override with one or more  --merged a,b[,c]  (e.g. for slot 7 v2:  --merged s7_an_0_vcm,s7_an_1_vref
# --merged s7_an_0_en_3v3,s7_an_1_en_3v3 --merged s7_an_0_en_3v3_b,s7_an_1_en_3v3_b).
MERGED = [{'s7_an_0_outp', 's7_an_1_vinp'}, {'s7_an_0_outn', 's7_an_1_vinn'}]
_args, _merged = [], []
_it = iter(sys.argv[1:])
for _a in _it:
    if _a == '--merged':
        _merged.append(set(next(_it).split(',')))
    else:
        _args.append(_a)
if _merged:
    MERGED = _merged
sys.argv = [sys.argv[0]] + _args
# Labels inside the pad cells that name the same node (documented, not shorts):
# S2D closes its feedback loop inside the cell, vfbp/vfbn tied to outp/outn on its
# top sheet, and its sub-cells call the outputs voutp/voutn.
IN_CELL_ALIASES = {'outp': {'vfbp', 'voutp'}, 'outn': {'vfbn', 'voutn'}}

gds, topname = sys.argv[1], sys.argv[2]
x0, y0, x1, y1 = map(float, sys.argv[3:7])
ly = db.Layout()
ly.read(gds)
top = ly.cell(topname)
if len(sys.argv) > 7:
    sl = db.Layout(); sl.read(sys.argv[7])
    st = sl.top_cells()[0]
    tgt = ly.create_cell('slot_7_placed')
    tgt.copy_tree(st)
    top.insert(db.DCellInstArray(tgt.cell_index(), db.DTrans(float(sys.argv[8]), float(sys.argv[9]))))
clip = ly.clip(top.cell_index(), db.DBox(x0, y0, x1, y1))
flat = ly.cell(clip)
flat.flatten(True)

layers = {'M1': (8, 0), 'V1': (19, 0), 'M2': (10, 0), 'V2': (29, 0), 'M3': (30, 0),
          'V3': (49, 0), 'M4': (50, 0)}
texts = {'M1': [(8, 25), (8, 2)], 'M2': [(10, 25), (10, 2)], 'M3': [(30, 25), (30, 2)],
         'M4': [(50, 25), (50, 2)]}
l2n = db.LayoutToNetlist(db.RecursiveShapeIterator(ly, flat, []))
reg = {}
for k, (L, D) in layers.items():
    li = ly.find_layer(L, D)
    reg[k] = l2n.make_layer(li if li is not None else ly.layer(L, D), k)
tl = {}
for k, lst in texts.items():
    for (L, D) in lst:
        li = ly.find_layer(L, D)
        if li is not None:
            t = l2n.make_text_layer(li, f'{k}_t{D}')
            tl.setdefault(k, []).append(t)
for a, v, b in (('M1', 'V1', 'M2'), ('M2', 'V2', 'M3'), ('M3', 'V3', 'M4')):
    l2n.connect(reg[a]); l2n.connect(reg[v]); l2n.connect(reg[b])
    l2n.connect(reg[a], reg[v]); l2n.connect(reg[v], reg[b])
for k, ts in tl.items():
    for t in ts:
        l2n.connect(reg[k], t)
l2n.extract_netlist()
nl = l2n.netlist()
circ = nl.circuit_by_name(flat.name) or list(nl.each_circuit_top_down())[0]

# labels per net:  probe each text position on its metal layer
labels = {}
for k, ts in texts.items():
    for (L, D) in ts:
        li = ly.find_layer(L, D)
        if li is None:
            continue
        for s in flat.shapes(li).each():
            if not s.is_text():
                continue
            p = s.text.trans.disp
            net = l2n.probe_net(reg[k], db.DPoint(p.x * ly.dbu, p.y * ly.dbu))
            if net is not None:
                labels.setdefault(net.cluster_id, (net, set()))[1].add(s.text_string)

ok = True
print(f'{gds} {topname} clip ({x0},{y0})-({x1},{y1})' + (f' + {sys.argv[7]} at ({sys.argv[8]},{sys.argv[9]})' if len(sys.argv) > 7 else ''))
seen = set()
for name in EXPECT:
    nets = [(cid, v) for cid, v in labels.items() if name in v[1]]
    if len(nets) != 1:
        print(f'  {name:18s} FAIL: on {len(nets)} nets'); ok = False; continue
    cid, (net, labs) = nets[0]
    group = next((g for g in MERGED if name in g), {name})
    allowed = set(group) | {p for n in group for p in EXPECT[n]}
    allowed |= {x for n in group for p in EXPECT[n] for x in IN_CELL_ALIASES.get(p, ())}
    foreign = labs - allowed
    missing = allowed - labs
    status = 'OK' if not foreign and not missing else 'FAIL'
    ok &= status == 'OK'
    print(f'  {name:18s} {status}  net labels: {sorted(labs)}' + (f'  FOREIGN: {sorted(foreign)}' if foreign else '') + (f'  MISSING: {sorted(missing)}' if missing else ''))
print('RESULT', 'all 13 pins OK' if ok else 'FAILURES')
sys.exit(0 if ok else 1)
