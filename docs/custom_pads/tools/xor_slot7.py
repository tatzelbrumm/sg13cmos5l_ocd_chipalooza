#!/usr/bin/env python3
# Flattened XOR of cell slot_7 inside the pre-fill chip GDS against the delivered slot_7.gds.
# usage: python3 xor_slot7.py <chip.gds[.gz]> <slot_7.gds> [slot cell name in chip, default: the cell named slot_7]
# Prints the layers compared and the layers whose XOR area is > 0; exit 1 if any differ.
import sys
import klayout.db as db


def flat_region(layout, cell, li):
    return db.Region(cell.begin_shapes_rec(li)).merged()


def main():
    chip_path, slot_path = sys.argv[1], sys.argv[2]
    name = sys.argv[3] if len(sys.argv) > 3 else "slot_7"
    la, lb = db.Layout(), db.Layout()
    la.read(chip_path)
    lb.read(slot_path)
    ca, cb = la.cell(name), lb.cell("slot_7")
    if ca is None or cb is None:
        print(f"cell missing: chip {name} {ca is not None}, slot slot_7 {cb is not None}")
        return 2
    keys = {}
    for lay, li in [(la, None), (lb, None)]:
        for i in lay.layer_indexes():
            info = lay.get_info(i)
            keys[(info.layer, info.datatype)] = 1
    diff = []
    for (l, d) in sorted(keys):
        ia, ib = la.find_layer(l, d), lb.find_layer(l, d)
        ra = flat_region(la, ca, ia) if ia is not None else db.Region()
        rb = flat_region(lb, cb, ib) if ib is not None else db.Region()
        x = ra ^ rb
        if not x.is_empty():
            diff.append(f"{l}/{d} ({x.area() * la.dbu * la.dbu:.6f} um2)")
    print(f"layers compared: {len(keys)}")
    print("XOR area > 0 on layers: " + (", ".join(diff) if diff else "none"))
    return 1 if diff else 0


if __name__ == "__main__":
    sys.exit(main())
