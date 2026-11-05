# FINDINGS: two custom I/O pads + slot 7 through the Chipalooza harness flow (test platform)

Harness `tatzelbrumm/sg13cmos5l_ocd_chipalooza` branch `custom-pad-test` (from `main` e0445b6); slot repo
`tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single` branch `harness-test` (from `toplevel` 91a7da8,
slot GDS commit 4611357). Steps, times, exit codes: `RUNLOG.md`; logs: `logs/`. 2026-11-05.

## Answers

1. **Import (Q1):** works. `scripts/setup_custom_io.sh` renames all sub-cells per pad (`cm_d2s_`, `cm_s2d_`) in a
   derived `.uniq.gds` (13 of the 21 shared sub-cell names differ in content; magic copies readonly GDS verbatim, so
   the rename must be in the GDS), reads it like setup.sh, sets `FIXED_BBOX 0 0 80 180`. Ports come through exactly
   (D2S: pad vinp vinn vref iref en_3v3_b en_3v3 iovdd iovss vdd; S2D: pad vref outp outn vcm en_3v3 en_3v3_b iref
   iovdd iovss vdd); no `vss` port (substrate), no `vfb*`/`vcmfb` port. Both pads + foundry pads load in one session.
2. **Digestible (Q2):** generator support = CUSTOM_PADS table in `parse_config.py`, one label proc per side
   (`scripts/custom_io.tcl`: Via2 on the pad's own M2 stub + 0.29 um M3 strap + port), one netlist file, two readnet
   lines, and a frame clean-up step (below). Pad layout unchanged (option 1 + via in the padframe = option 3 for the via).
3. **Padframe sequence (Q3):** clean-config, config, padframe, frame-custom-io, wrappers, gds-slots: exit 0. Other
   slots and foundry pads: `make config` output identical outside slot 7; padframe/wrapper `.mag` identical except port
   index renumbering; 17 slot wrapper GDS identical in shapes and texts. DRC/LVS: see below.
4. **Slot 7 in the flow (Q4):** `make projects SLOTS=7`, `projects-gds`, `user-id` exit 0, slot_7 placed at
   1379.95/2170.05 = wrapper position; `make gds-prefill` exit 0 (5 min); full-chip `make drc` ran all rules (814 s) but
   klayout was killed for memory writing the 1.4 GB report (script still exit 0); not repeated (low value for this
   task). Same deck on a pre-fill clip of slot 7 + pads: nothing inside slot 7; see below.
   Pads in the ring and slot in the wrapper: `pad_ring_s7.png`, `slot7_area.png`, `zoom_s7_an_1_pins.png`.
   Net by net, all 13 pad core pins reach their slot net and nothing else (table below).

**LEF:** not needed. No script reads an I/O LEF except setup.sh (annotation); a magic-written LEF read back changes
0 lines of the padframe; what is needed is `FIXED_BBOX` (without it every pad from pad_s7_an_0 on moves 0.62 um per pad).

## Traps and findings

- a. Geometry outside x 0..80 um and the M3/M4/M5/TopMetal rails at both edges are identical to `IOPadAnalog`; overlap
  with neighbours = foundry behaviour. Padframe DRC (clip around the s7 pads, PDK deck feol+beol) 116 vs 101 baseline,
  all recommended `Pad.fR_*` "exit length 7 um" at the bond pad edge (every pad has them); +15 from the custom pads'
  M2 fingers. No mandatory-rule violation, none at the straps.
- b. Solved by prefixing (see Q1). c. `magic/custom_io/` is tracked (not ignored).
- magic 8.3.685 here: `locking disable` makes every cell read from disk read-only, so `make wrappers` writes 18 empty
  wrappers and `make padframe` skips the wrapper post-processing. Worked around by a PATH shim (`tools/shim/magic`).
- main's committed generated views are stale vs `config.txt` (s6/s13/s17); `make symbols` fails on main (slot 6 port
  with two names) because `chipalooza_frame.mag` holds hand-made FLAT copies of pad-edge strips that
  `run_gen_user_wrappers.sh` carves together with the regenerated `chipalooza_frame_wrapper` subcell (placed at +5 nm
  in y). Hence the new `make frame-custom-io` (erases the stale copies in custom pads' bands only).
- Generated padframe: `label_right_analog ... pad` paints the s<N>_an strip at the bond pad edge (x 2075.9), not the core
  edge; the core-side pins the slots see are the hand copies. Wrapper pins are 5 nm above the padframe straps (subcell
  offset); slot_7 follows the wrapper, overlap 0.285 of 0.29 um.
- Padframe session runs on a 10 nm grid: straps are placed on 10 nm (via at most 5 nm off the pin centre).
- SRAM macro absent from this PDK checkout (sparse checkout excludes `ihp-sg13g2/libs.ref/sg13g2_sram`, the symlink target).

## Files (harness, vs main)

| path | new/changed | why |
|---|---|---|
| magic/custom_io/ (gds/, .uniq.gds, *.mag, PROVENANCE.md) | new | pad views, provenance |
| scripts/setup_custom_io.sh, scripts/custom_io_uniquify.py | new | import (Q1) |
| scripts/custom_io.tcl | new | label procs |
| scripts/run_update_frame_custom_io.sh | new | erase stale frame copies |
| netlist/schematic/custom_io.spice | new | LVS netlist (from slot repo) |
| scripts/parse_config.py | changed | CUSTOM_PADS, 4 places (+ an error message in the Tcl branch) |
| scripts/gen_padframe_template.tcl | changed | +addpath custom_io, +source custom_io.tcl |
| scripts/layout_setup.tcl | changed | +addpath custom_io |
| validate/run_lvs_padframe.sh, validate/run_lvs_ocd_chipalooza.sh | changed | +readnet custom_io.spice |
| Makefile | changed | +target frame-custom-io |
| config.txt | changed | s7_an[0/1] custom types, s7_version, comment |
| verilog/rtl/slot7_wrapper.v | changed | 13 ports |
| verilog/rtl/chipalooza_frame.v, verilog/gl/sg13cmos5l_ocd_chipalooza.v, verilog/rtl/digital_tb.v, validate/lvs/blackboxes.v | changed | slot 7 core nets (follow-up) |
| magic/chipalooza_frame.mag | changed (by script) | stale s7 copies erased |
| generated: gen_padframe.tcl, verilog/gl/{sg13cmos5l_padframe,chipalooza_frame_wrapper,slot7_wrapper_lvs,user_id_programming}.v, magic/*padframe*, slot*_wrapper.{mag,gds}, xschem/slot7_wrapper.sym, user_id*.mag, scripts/user_projects.tcl, .gitmodules + dependencies/slot_7 | regenerated | flow outputs |
| docs/custom_pads/ | new | records, tools |

Slot repo `harness-test`: final/gds/slot_7.gds, final/{lef,lib,vh}/slot_7.*, macros/slot/harness_test/
(make_slot7.py, build_views.sh, slot7_pins.md, README.md), docs/harness_test.md, one README line.

## Reproduce from a fresh clone

```bash
git clone --recurse-submodules -b custom-pad-test https://github.com/tatzelbrumm/sg13cmos5l_ocd_chipalooza
cd sg13cmos5l_ocd_chipalooza
export PDK_ROOT=/foss/pdks PDK=ihp-sg13cmos5l
export PATH=$PWD/docs/custom_pads/tools/shim:$PATH      # only for magic 8.3.685 (locking bug)
make setup && ./scripts/setup_custom_io.sh               # foundry libs; custom pads (re-creates magic/custom_io)
make clean-config && make config && make padframe
make frame-custom-io && make wrappers && make gds-slots
docs/custom_pads/tools/symbols_slot7.sh                  # make symbols stops on main's slot 6 defect
make extract-padframe && make lvs-padframe
make projects SLOTS=7 && make projects-gds SLOTS=7 && make user-id && make gds-prefill && make drc
```
Slot repo (`harness-test`): `macros/slot/harness_test/build_views.sh <harness>/magic/slot7_wrapper.mag`, commit, then
put the commit into `s7_version` in `config.txt`.

## Pin table (single source: `slot7_wrapper.mag` -> slot repo `macros/slot/harness_test/slot7_pins.md`)

All Metal3, right edge, x 535.05..536.45 um slot-local (label 535.05..535.85); y in um:

| signal | pad | layer | edge | y0 | y1 |
|---|---|---|---|---|---|
| s7_an_0_vref | s7_an[0] | M3 | right | 112.115 | 112.405 |
| s7_an_0_outp | s7_an[0] | M3 | right | 123.725 | 124.015 |
| s7_an_0_outn | s7_an[0] | M3 | right | 129.825 | 130.115 |
| s7_an_0_vcm | s7_an[0] | M3 | right | 135.875 | 136.165 |
| s7_an_0_en_3v3 | s7_an[0] | M3 | right | 142.505 | 142.795 |
| s7_an_0_en_3v3_b | s7_an[0] | M3 | right | 153.695 | 153.985 |
| s7_an_0_iref | s7_an[0] | M3 | right | 159.365 | 159.655 |
| s7_an_1_vinp | s7_an[1] | M3 | right | 222.115 | 222.405 |
| s7_an_1_vinn | s7_an[1] | M3 | right | 222.655 | 222.945 |
| s7_an_1_vref | s7_an[1] | M3 | right | 223.195 | 223.485 |
| s7_an_1_iref | s7_an[1] | M3 | right | 260.455 | 260.745 |
| s7_an_1_en_3v3_b | s7_an[1] | M3 | right | 260.995 | 261.285 |
| s7_an_1_en_3v3 | s7_an[1] | M3 | right | 261.535 | 261.825 |

## Net by net (KLayout extraction M1..M4/V1..V3 of the PRE-FILL TOP, clip 1901.1..2096.1 x 2271.1..2471.1 um; `logs/66_netcheck_prefill.out`)

```
s7_an_0_vref       OK  net labels: ['s7_an_0_vref', 'vref']
s7_an_0_outp       OK  net labels: ['outp', 's7_an_0_outp', 's7_an_1_vinp', 'vfbp', 'vinp', 'voutp']
s7_an_0_outn       OK  net labels: ['outn', 's7_an_0_outn', 's7_an_1_vinn', 'vfbn', 'vinn', 'voutn']
s7_an_0_vcm        OK  net labels: ['s7_an_0_vcm', 'vcm']
s7_an_0_en_3v3     OK  net labels: ['en_3v3', 's7_an_0_en_3v3']
s7_an_0_en_3v3_b   OK  net labels: ['en_3v3_b', 's7_an_0_en_3v3_b']
s7_an_0_iref       OK  net labels: ['iref', 's7_an_0_iref']
s7_an_1_vinp       OK  net labels: ['outp', 's7_an_0_outp', 's7_an_1_vinp', 'vfbp', 'vinp', 'voutp']
s7_an_1_vinn       OK  net labels: ['outn', 's7_an_0_outn', 's7_an_1_vinn', 'vfbn', 'vinn', 'voutn']
s7_an_1_vref       OK  net labels: ['s7_an_1_vref', 'vref']
s7_an_1_iref       OK  net labels: ['iref', 's7_an_1_iref']
s7_an_1_en_3v3_b   OK  net labels: ['en_3v3_b', 's7_an_1_en_3v3_b']
s7_an_1_en_3v3     OK  net labels: ['en_3v3', 's7_an_1_en_3v3']
```
No net reported FAILED. Labels allowed besides the pin and strap: the documented S2D in-cell aliases vfbp/voutp (outp), vfbn/voutn (outn); the raw run without them is `logs/63_netcheck_clip_raw.out` (padframe + slot_7 composite, same result).

## First distinct DRC / LVS messages

DRC (PDK KLayout deck, feol+beol, deep):
1. `Pad.fR_M2/M3/M4/TM1/M1: Min. recommended Mx exit length is 7.0 um` (recommended rule; every pad's bond pad edge;
   padframe clip 116 vs 101 baseline, +15 from the custom pads' M2 fingers; pre-fill clip 41+3+2+2 interior items)
2. `Seal.l: No structures outside sealring boundary allowed` (86, pre-fill clip only: artifact of the cut seal ring;
   all on padframe top-level paint incl. main's vss1v2 strips; absent in the padframe clip)
3. clip-edge artifacts only (`CntB.h1`, `Cnt.c`, `V1.a/c`, `V3.a/c`, `V2.a/c`, `TV1.*`, `M1.a`, `M2.a`, `M4.a`, `TM1.a`,
   `pSD.c1`, `Gat.a`): none entirely inside the clip interior (`logs/70_drc_s7_prefill_interior.out`)
4. slot_7.gds alone: 0 violations (333 rules).

LVS (`make lvs-padframe`, magic + netgen; `validate/comp_sg13cmos5l_padframe.out`), first distinct messages (1-10 are all inside foundry I/O cells, same classes as on main):
1. `Cell sg13cmos5l_DCPDiode (0) disconnected node: guard`
2. `anode |anode_2 **Mismatch**`
3. `Cell sg13cmos5l_Clamp_P20N0D (0) disconnected node: iovss`
4. `sg13_hv_pmos (40->10) |sg13_hv_pmos (2->1) **Mismatch**`
5. `Number of devices: 11 **Mismatch** |Number of devices: 2 **Mismatch**`
6. `Number of nets: 12 **Mismatch** |Number of nets: 3 **Mismatch**`
7. `Net: pad_uq5 |(no matching net)`
8. `Instance: sg13_hv_pmos:1 |(no matching instance)`
9. `Netlists do not match.`
10. `Cell sg13cmos5l_DCNDiode (0) disconnected node: guard`

Custom pads: devices and nets match (S2D 37 nets; D2S 76 devices, 36 nets), `Netlists match with 7 symmetries with
property errors` (only `mm_ok`, 234x); pin mismatch only `sub`/`iovss` + `vss` (the known vss issue). Top level:
`Final result: Top level cell failed pin matching` as on main; all 15 slot 7 pins match; the remaining mismatches are
2 x `sg13cmos5l_ocd_Split200` (netlist only) and supply-pad RC clamp nets.

Cost of the heavy steps here (4 cores, 15 GB): padframe extraction 7 min, gds-prefill 5 min, padframe-clip DRC
3.5 min, full-chip DRC 14 min of rules then out of memory; everything else seconds.

## What blocks a real tape-out

- Chip-core views: Verilog done after the test (follow-up commit, patch 0004): `chipalooza_frame.v`,
  `sg13cmos5l_ocd_chipalooza.v`, `digital_tb.v`, `validate/lvs/blackboxes.v` carry the 13 nets; iverilog elaborates
  `chipalooza_frame` as before. Still old (`s7_an_*_esd`, `s7_an[0:1]`): `xschem/chipalooza_frame.sch`,
  `xschem/sg13cmos5l_ocd_chipalooza.sch`, their symbols, and `validate/lvs/chipalooza_frame.struct.v` (yosys). Top-level
  LVS (`make lvs-top`) not run (skipped by request).
- All 18 slot symbols share one row template; a full `make symbols` re-lays out every symbol (34 left rows now).
- The pads' own known LVS mismatch (vss = iovss substrate) carries into padframe/top LVS.
- Recommended-rule `Pad.fR_M2` exits (+15) at the bond pad edge of the custom pads.
- slot_7.gds is a stand-in (no circuit); 9 support nets end in labelled stubs.
- Not checked here: density/fill (`make fill`, `gds-final`), antenna, ESD rules across the ring, full-chip DRC/LVS.

## What Tim would have to accept (patch series in `patches/`)

`patches/` = `git format-patch` against `main` (e0445b6), applies cleanly there; nothing proposed upstream.
1. `0001` custom_io import: `magic/custom_io/` (GDS, uniquified GDS, .mag, PROVENANCE), `scripts/setup_custom_io.sh`,
   `scripts/custom_io_uniquify.py`, one line in `scripts/layout_setup.tcl`.
2. `0002` generator support: `CUSTOM_PADS` in `parse_config.py`, `scripts/custom_io.tcl`, 2 lines in
   `gen_padframe_template.tcl`, `scripts/run_update_frame_custom_io.sh` + Makefile target, `netlist/schematic/custom_io.spice`
   + 1 readnet line in each LVS script. Foundry pad types: identical `make config` output.
3. `0003` example inputs for slot 7 (`config.txt`, `slot7_wrapper.v`); outputs are regenerated, not patched.
4. `0004` chip-core Verilog for slot 7 (frame RTL, top gl netlist, digital_tb, LVS blackboxes); schematics still to do.
Not in the series, decisions for Tim: the 5 nm offset of `chipalooza_frame_wrapper_0` in `chipalooza_frame`; the
hand-made flat strip copies in `chipalooza_frame.mag` (slot 6 already broken by them); `label_*_analog ... pad` painting
at the bond pad edge; README step 7 should name `make wrappers` before `make gds-slots`; magic 8.3.685 `locking disable`.
