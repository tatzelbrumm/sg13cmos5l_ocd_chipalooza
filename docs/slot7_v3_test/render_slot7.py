#!/usr/bin/env python3
# render_slot7.py <gds> <topcell> <x0> <y0> <x1> <y1> <out_basename> [png_width]
# Slot 7 + its custom pads as PNG (KLayout renderer, PDK layer colours) and SVG (merged polygons per layer,
# same colours, semi-transparent).  Region in um.
import sys, xml.etree.ElementTree as ET
import klayout.db as db, klayout.lay as lay
gds, top = sys.argv[1], sys.argv[2]; x0, y0, x1, y1 = map(float, sys.argv[3:7]); out = sys.argv[7]
W = int(sys.argv[8]) if len(sys.argv) > 8 else 3000
LYP = '/foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/sg13cmos5l.lyp'
# drawn layers, bottom to top (layer, datatype, name)
LAYERS = [(31, 0, 'NWell'), (1, 0, 'Activ'), (5, 0, 'GatPoly'), (8, 0, 'Metal1'), (10, 0, 'Metal2'), (30, 0, 'Metal3'),
          (50, 0, 'Metal4'), (67, 0, 'Metal5'), (126, 0, 'TopMetal1'), (134, 0, 'TopMetal2')]
col = {}
for p in ET.parse(LYP).getroot().iter('properties'):
    s, f = p.findtext('source') or '', p.findtext('fill-color')
    if f and '@' not in s.split('/')[0]:
        try: L, D = s.split('@')[0].split('/'); col.setdefault((int(L), int(D)), f)
        except ValueError: pass
ly = db.Layout(); ly.read(gds); t = ly.cell(top); box = db.DBox(x0, y0, x1, y1); ibox = box.to_itype(ly.dbu)
# PNG
view = lay.LayoutView(); view.set_config('background-color', '#ffffff'); view.set_config('grid-visible', 'false')
view.set_config('text-visible', 'false')
i = view.show_layout(ly, False); view.cellview(i).cell = t; view.clear_layers()
for L, D, n in LAYERS:
    if ly.find_layer(L, D) is None: continue
    p = lay.LayerProperties(); p.source = f'{L}/{D}@{i + 1}'; c = int(col.get((L, D), '#808080')[1:], 16)
    p.fill_color = c; p.frame_color = c; p.dither_pattern = 1 if n in ('NWell',) else 0; p.transparent = True; p.name = n
    view.insert_layer(view.end_layers(), p)
view.max_hier(); view.zoom_box(box); H = int(W * (y1 - y0) / (x1 - x0)); view.save_image(out + '.png', W, H)
# SVG
sc = 2.0  # px per um
Wp, Hp = (x1 - x0) * sc, (y1 - y0) * sc
o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{Wp:.0f}" height="{Hp:.0f}" viewBox="0 0 {Wp:.1f} {Hp:.1f}">',
     f'<rect width="100%" height="100%" fill="#ffffff"/>']
def pt(p): return f'{(p.x * ly.dbu - x0) * sc:.2f},{(y1 - p.y * ly.dbu) * sc:.2f}'
for L, D, n in LAYERS:
    li = ly.find_layer(L, D)
    if li is None: continue
    r = (db.Region(t.begin_shapes_rec_touching(li, ibox)) & db.Region(ibox)).merged()
    if r.is_empty(): continue
    d = []
    for poly in r.each():
        for h in range(poly.holes() + 1):
            pts = list(poly.each_point_hull() if h == 0 else poly.each_point_hole(h - 1))
            d.append('M' + ' L'.join(pt(p) for p in pts) + 'Z')
    o.append(f'<path id="{n}" fill="{col.get((L, D), "#808080")}" fill-opacity="{0.25 if n == "NWell" else 0.45}" '
             f'fill-rule="evenodd" stroke="none" d="{" ".join(d)}"/>')
o.append('</svg>')
open(out + '.svg', 'w').write('\n'.join(o))
print('wrote', out + '.png', W, H, 'and', out + '.svg')
