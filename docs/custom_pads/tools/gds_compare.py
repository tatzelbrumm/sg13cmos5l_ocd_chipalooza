#!/usr/bin/env python3
# Compare two GDS files by content (per-layer XOR of all shapes, flattened, and the set of texts),
# ignoring the time stamps and cell order that make byte comparison useless.
# Usage: gds_compare.py a.gds b.gds [topcell]   -> prints SAME or the differing layers
import sys, klayout.db as db
a, b = sys.argv[1], sys.argv[2]
la, lb = db.Layout(), db.Layout(); la.read(a); lb.read(b)
ta = la.cell(sys.argv[3]) if len(sys.argv) > 3 else la.top_cells()[0]
tb = lb.cell(sys.argv[3]) if len(sys.argv) > 3 else lb.top_cells()[0]
keys = set((la.get_info(i).layer, la.get_info(i).datatype) for i in la.layer_indexes()) | \
       set((lb.get_info(i).layer, lb.get_info(i).datatype) for i in lb.layer_indexes())
diff = []
for (L, D) in sorted(keys):
    ia, ib = la.find_layer(L, D), lb.find_layer(L, D)
    ra = db.Region(ta.begin_shapes_rec(ia)) if ia is not None else db.Region()
    rb = db.Region(tb.begin_shapes_rec(ib)) if ib is not None else db.Region()
    x = ra ^ rb
    if not x.is_empty():
        diff.append(f'{L}/{D} xor area {x.area() * la.dbu * la.dbu:.4f} um2 bbox {x.bbox().to_dtype(la.dbu)}')
    tx = lambda l, t, i: set() if i is None else set((s.text_string, s.text.x, s.text.y) for s in t.begin_shapes_rec(i).each() if False) 
    def texts(l, t, i):
        out = set()
        if i is None: return out
        it = t.begin_shapes_rec(i)
        while not it.at_end():
            s = it.shape()
            if s.is_text():
                p = it.trans() * s.text.trans.disp
                out.add((s.text_string, p.x, p.y))
            it.next()
        return out
    if texts(la, ta, ia) != texts(lb, tb, ib):
        diff.append(f'{L}/{D} texts differ: {sorted(texts(la, ta, ia) ^ texts(lb, tb, ib))[:6]}')
print('SAME' if not diff else 'DIFFERENT\n  ' + '\n  '.join(diff))
