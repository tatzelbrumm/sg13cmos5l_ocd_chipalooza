#!/usr/bin/env python3
# Summarize KLayout DRC report(s):  count per rule, and optionally the difference to a baseline.
# Usage: lyrdb_summary.py now.lyrdb [base.lyrdb]
import sys
from collections import Counter
import klayout.rdb as rdb
def load(p):
    r = rdb.ReportDatabase(); r.load(p)
    cats = {c.rdb_id(): c.name() for c in r.each_category()}
    cnt = Counter(); boxes = {}
    for it in r.each_item():
        n = cats[it.category_id()]; cnt[n] += 1
        for v in it.each_value():
            try: boxes.setdefault(n, []).append(str(v.box() if v.is_box() else v.polygon().bbox() if v.is_polygon() else v.edge_pair().bbox() if v.is_edge_pair() else v))
            except Exception: pass
    return cnt, boxes
now, nb = load(sys.argv[1])
print(f'{sys.argv[1]}: {sum(now.values())} violations in {len(now)} rules')
for k, v in now.most_common(): print(f'  {k:40s} {v}')
if len(sys.argv) > 2:
    base, bb = load(sys.argv[2])
    print(f'{sys.argv[2]}: {sum(base.values())} violations in {len(base)} rules')
    print('difference now - base per rule:')
    for k in sorted(set(now) | set(base)):
        if now[k] != base[k]:
            print(f'  {k:40s} {now[k] - base[k]:+d}   new locations (first 5): {[b for b in nb.get(k, []) if b not in bb.get(k, [])][:5]}')
