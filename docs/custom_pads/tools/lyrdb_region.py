#!/usr/bin/env python3
# lyrdb_region.py <report.lyrdb> <x0> <y0> <x1> <y1>:  chip-wide count per rule, and the
# items whose marker touches the box (um), per rule with the first locations.
import sys, re
from collections import Counter
import klayout.rdb as rdb, klayout.db as db
r = rdb.ReportDatabase(); r.load(sys.argv[1])
box = db.DBox(*map(float, sys.argv[2:6]))
cats = {c.rdb_id(): (c.name(), c.description) for c in r.each_category()}
tot, inside, where = Counter(), Counter(), {}
for it in r.each_item():
    name = cats[it.category_id()][0]; tot[name] += 1
    for v in it.each_value():
        nums = list(map(float, re.findall(r'-?\d+\.?\d*', v.to_s())))
        if len(nums) < 2: continue
        b = db.DBox(min(nums[0::2]), min(nums[1::2]), max(nums[0::2]), max(nums[1::2]))
        if b.overlaps(box) or b.inside(box):
            inside[name] += 1; where.setdefault(name, []).append(str(b)); break
print(f'chip: {sum(tot.values())} items in {len(tot)} rules')
for k, v in tot.most_common(15): print(f'  {k:28s} {v:8d}  {dict((c[0], c[1]) for c in cats.values()).get(k, "")[:70]}')
print(f'in box {box}: {sum(inside.values())} items in {len(inside)} rules')
for k, v in inside.most_common(): print(f'  {k:28s} {v:6d}  e.g. {where[k][:3]}')
