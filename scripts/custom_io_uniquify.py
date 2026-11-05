#!/usr/bin/env python3
# custom_io_uniquify.py --- make the sub-cell names of a custom pad GDS unique.
#
# Usage:  custom_io_uniquify.py <in.gds> <out.gds> <prefix>
#
# Every cell except the top cell is renamed to <prefix><name>, with '$'
# replaced by '_'.  Geometry, texts and the top cell name are unchanged.
# Needed because the two custom pads share 21 sub-cell names of which 13
# differ in content, and magic reads them "gds readonly", i.e. it copies
# the GDS bytes of each cell verbatim on output:  a rename inside magic
# would not reach the written GDS.  Part of scripts/setup_custom_io.sh.
import sys
import klayout.db as db

src, dst, prefix = sys.argv[1:4]
ly = db.Layout()
ly.read(src)
tops = ly.top_cells()
if len(tops) != 1:
    sys.exit(f'{src}: expected one top cell, found {[c.name for c in tops]}')
top = tops[0]
for c in ly.each_cell():
    if c.cell_index() != top.cell_index():
        c.name = prefix + c.name.replace('$', '_')
names = [c.name for c in ly.each_cell()]
if len(set(names)) != len(names):
    sys.exit('rename produced duplicate names')
# No KLayout context cell ($$$CONTEXT_INFO$$$):  it would become a second top cell.
opt = db.SaveLayoutOptions()
opt.write_context_info = False
ly.write(dst, opt)
print(f'{dst}: top {top.name}, {len(names) - 1} sub-cells renamed with prefix {prefix}')
