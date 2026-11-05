#!/usr/bin/env python3
# lyrdb_interior.py <report> <x0> <y0> <x1> <y1>:  DRC items whose marker lies entirely inside the box
# (um), i.e. away from clip-edge artifacts; per rule: count, description, first locations.
import sys, re
from collections import Counter
import klayout.rdb as rdb, klayout.db as db
r = rdb.ReportDatabase(); r.load(sys.argv[1])
box = db.DBox(*map(float, sys.argv[2:6]))
cats = {c.rdb_id(): (c.name(), c.description) for c in r.each_category()}
cnt, where, desc = Counter(), {}, {}
for it in r.each_item():
    n, d = cats[it.category_id()]
    for v in it.each_value():
        nums = list(map(float, re.findall(r'-?\d+\.?\d*', v.to_s())))
        if len(nums) < 2: continue
        b = db.DBox(min(nums[0::2]), min(nums[1::2]), max(nums[0::2]), max(nums[1::2]))
        if b.inside(box):
            cnt[n] += 1; desc[n] = d; where.setdefault(n, []).append(b); break
print(f'items entirely inside {box}: {sum(cnt.values())} in {len(cnt)} rules')
for k, v in cnt.most_common():
    print(f'  {k:12s} {v:6d}  {desc[k][:75]}')
    for b in where[k][:4]: print(f'      at {b}')
