#!/usr/bin/env python3
# render_png.py <gds> <topcell> <x0> <y0> <x1> <y1> <out.png> [width_px] [slot_gds slot_x slot_y]
# Layout-to-image with KLayout (klayout.lay), metal layers and text, region in um.
import sys
import klayout.db as db
import klayout.lay as lay
gds, top, x0, y0, x1, y1, out = sys.argv[1], sys.argv[2], *map(float, sys.argv[3:7]), sys.argv[7]
w = int(sys.argv[8]) if len(sys.argv) > 8 else 1600
ly = db.Layout(); ly.read(gds)
t = ly.cell(top)
if len(sys.argv) > 9:
    sl = db.Layout(); sl.read(sys.argv[9]); c = ly.create_cell('slot_7_placed'); c.copy_tree(sl.top_cells()[0])
    t.insert(db.DCellInstArray(c.cell_index(), db.DTrans(float(sys.argv[10]), float(sys.argv[11]))))
view = lay.LayoutView()
view.set_config('background-color', '#ffffff')
view.set_config('grid-visible', 'false')
view.set_config('text-visible', 'true')
view.set_config('default-text-size', '0.3')
idx = view.show_layout(ly, False)
view.cellview(idx).cell = t
style = {(1, 0): ('#30a030', 0), (5, 0): ('#d02020', 0), (8, 0): ('#2040ff', 0), (10, 0): ('#e08000', 0),
         (30, 0): ('#a000c0', 0), (50, 0): ('#00a0a0', 0), (67, 0): ('#806040', 0), (126, 0): ('#909090', 0),
         (19, 0): ('#000000', 0), (29, 0): ('#000000', 0), (49, 0): ('#000000', 0), (189, 4): ('#ff0000', 0),
         (30, 25): ('#a000c0', 0), (10, 25): ('#e08000', 0), (50, 25): ('#00a0a0', 0)}
for (L, D), (col, _) in style.items():
    if ly.find_layer(L, D) is None:
        continue
    p = lay.LayerProperties()
    p.source = f"{L}/{D}@{idx + 1}"
    p.fill_color = int(col[1:], 16); p.frame_color = int(col[1:], 16)
    p.dither_pattern = 1 if (L, D) == (189, 4) else (5 if L in (1, 5, 126, 67) else 0)
    p.width = 1
    p.transparent = True
    view.insert_layer(view.end_layers(), p)
view.max_hier()
view.zoom_box(db.DBox(x0, y0, x1, y1))
h = int(w * (y1 - y0) / (x1 - x0))
view.save_image(out, w, h)
print('wrote', out, w, h)
