#!/usr/bin/env python3
"""netcheck_slot7_platform.py --- net-by-net check of the slot-7 test platform's left-edge nets by extraction.

Adapted 2026-11-06 from netcheck_slot7.py (same directory), which checks the 13 custom-pad pins at the right edge.
This one checks the harness side of the slot: the pins of slot_7 that the test platform uses (dig_in[3:0], enable,
dig_out[11:0], analog_bus0, analog_bus1 and the four gated supplies), plus the 13 pad pins as before.

Usage:
  netcheck_slot7_platform.py <gds> <topcell> <x0> <y0> <x1> <y1> [<slot_gds> <slot_x> <slot_y>]

Extracts metal connectivity (Metal1..Metal4, TopMetal1 with Via1..Via3, TopVia1; labels on the text and pin purposes
of Metal1..TopMetal1) of <topcell> clipped to the box (um), optionally with a slot GDS placed at (slot_x, slot_y).
Device layers are not used, so a net ends at every transistor: a short shows up as foreign labels on a net, and nothing
can merge through a device. For every checked pin it lists all labels on its net and requires:
  * the pin name is on exactly one net;
  * the platform's own labels for that net are on it (the cell pins inside slot_7, EXPECT below);
  * no other checked slot pin name is on it (a short), apart from the documented stand-in joins of the pad pins.
Labels of the harness side (wrapper, control blocks, power switches) are listed, not judged.
One documented exception: `vss_1v2` may be on a second net if that net carries the frame ground name `vss1v2`: the
frame's Metal2 strip at the slot's right edge (relabelled vss_1v2 by run_gen_user_wrappers.sh) is not joined to the
slot's own vss_1v2 inside the slot (as in every slot_7.gds so far); the two meet as the chip's 1.2 V ground elsewhere.
Labels are judged only if they lie inside slot 7 (SLOT_BOX, the placement of scripts/user_projects.tcl:
1379.95 2170.05, 537.15 x 273 um): the harness reuses the same names on its side of the slot pins (dig_in[k] before
its latches, `out` of its own switches), so a name alone does not say which side a label is on. Harness labels on a
net are listed with a leading `^`.
Use a clip of the slot's height (slot 8's vdd_1v2 starts 3.5 um above slot 7) reaching ~280 um left of the slot,
where the slot's vss_1v2 meets the control block's ground: 1100 2160 2100 2445 for the pre-fill top.
"""
import sys
import klayout.db as db

# slot pin -> labels inside slot_7 that must be on the same net (tp_en_ctrl M4 pins, core / xgate M1 / M2 pins)
EXPECT = {f'dig_in[{k}]': {f'en{k}_1v2'} for k in range(4)}
EXPECT.update({'enable': {'enable'}})
EXPECT.update({f'dig_out[{k}]': {f'rb{k}'} for k in range(4)})
EXPECT.update({f'dig_out[{k}]': {f'lo{k}'} for k in range(4, 12)})
EXPECT.update({'analog_bus0': {'out'}, 'analog_bus1': {'out'},
               'vdd_3v3': {'vdd', 'vdd_3v3'}, 'vss_3v3': {'vss', 'vss_3v3'},
               'vdd_1v2': {'vdd_1v2'}, 'vss_1v2': {'vss_1v2'}})
PADS = ['s7_an_0_vref', 's7_an_0_outp', 's7_an_0_outn', 's7_an_0_vcm', 's7_an_0_en_3v3', 's7_an_0_en_3v3_b',
        's7_an_0_iref', 's7_an_1_vinp', 's7_an_1_vinn', 's7_an_1_vref', 's7_an_1_iref', 's7_an_1_en_3v3_b',
        's7_an_1_en_3v3']
MERGED = [{'s7_an_0_outp', 's7_an_1_vinp'}, {'s7_an_0_outn', 's7_an_1_vinn'}]
UNUSED = ([f'dig_in[{k}]' for k in range(4, 24)] + ['clk', 'reset', 'ibias0', 'ibias1', 'vbias',
                                                    'analog_bus2', 'analog_bus3'])
PLATFORM_LABELS = set().union(*EXPECT.values()) | {'en_3v3', 'en_3v3_b', 'iout', 'in', 'ena', 'ena_b'} | \
    {f'en{k}{s}' for k in range(4) for s in ('', '_b')}

SLOT_BOX = db.DBox(1379.95, 2170.05, 1379.95 + 537.15, 2170.05 + 273.0)

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
          'V3': (49, 0), 'M4': (50, 0), 'TV1': (125, 0), 'TM1': (126, 0)}
texts = {'M1': [(8, 25), (8, 2)], 'M2': [(10, 25), (10, 2)], 'M3': [(30, 25), (30, 2)],
         'M4': [(50, 25), (50, 2)], 'TM1': [(126, 25), (126, 2)]}
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
            tl.setdefault(k, []).append(l2n.make_text_layer(li, f'{k}_t{D}'))
for a, v, b in (('M1', 'V1', 'M2'), ('M2', 'V2', 'M3'), ('M3', 'V3', 'M4'), ('M4', 'TV1', 'TM1')):
    l2n.connect(reg[a]); l2n.connect(reg[v]); l2n.connect(reg[b])
    l2n.connect(reg[a], reg[v]); l2n.connect(reg[v], reg[b])
for k, ts in tl.items():
    for t in ts:
        l2n.connect(reg[k], t)
l2n.extract_netlist()

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
            pt = db.DPoint(p.x * ly.dbu, p.y * ly.dbu)
            net = l2n.probe_net(reg[k], pt)
            if net is not None:
                inside = SLOT_BOX.contains(pt)
                labels.setdefault(net.cluster_id, (net, set()))[1].add(s.text_string if inside else '^' + s.text_string)

checked = list(EXPECT) + PADS
ok = True
print(f'{gds} {topname} clip ({x0},{y0})-({x1},{y1})' +
      (f' + {sys.argv[7]} at ({sys.argv[8]},{sys.argv[9]})' if len(sys.argv) > 7 else ''))
for name in checked + UNUSED:
    nets = [(cid, v) for cid, v in labels.items() if name in v[1]]
    if name == 'vss_1v2':
        frame = [n for n in nets if 'vss1v2' in n[1][1]]
        if len(nets) == 2 and len(frame) == 1:
            print(f'  {name:16s} note: frame strip net (right edge) separate: {sorted(frame[0][1][1])}')
            nets = [n for n in nets if n not in frame]
    if len(nets) != 1:
        print(f'  {name:16s} FAIL: on {len(nets)} nets'); ok = False; continue
    cid, (net, labs) = nets[0]
    group = next((g for g in MERGED if name in g), {name})
    others = (set(checked) | set(UNUSED)) - group
    shorts = labs & others
    if name in UNUSED:
        foreign = labs & PLATFORM_LABELS
        status = 'OK' if not shorts and not foreign else 'FAIL'
        extra = (f'  SHORT: {sorted(shorts)}' if shorts else '') + (f'  PLATFORM: {sorted(foreign)}' if foreign else '')
    else:
        missing = EXPECT.get(name, set()) - labs
        status = 'OK' if not shorts and not missing else 'FAIL'
        extra = (f'  SHORT: {sorted(shorts)}' if shorts else '') + (f'  MISSING: {sorted(missing)}' if missing else '')
    ok &= status == 'OK'
    print(f'  {name:16s} {status}  net labels: {sorted(labs)}{extra}')
print('RESULT', f'all {len(checked)} used pins and {len(UNUSED)} unused pins OK' if ok else 'FAILURES')
sys.exit(0 if ok else 1)
