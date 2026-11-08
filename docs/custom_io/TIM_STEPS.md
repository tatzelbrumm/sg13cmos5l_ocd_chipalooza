# Steps of the harness owner (Tim's role), slot 7 with custom pads, v2 (2026-11-08)

Replaces the version on branch `claude/c6-submodule-pads`. What changed:
- Tim's `main` already has the slot-7 entries in `config.txt` (`s7_source` = `tatzelbrumm/sg13cmos5l_cm_slot7`, pad types)
  and imports custom pads itself (`scripts/setup_custom.sh`, `make setup-custom`). No merge of `claude/c6-pads-layout`:
  `sg13cmos5l_cm_slot7` `main` is the source (pads in `pads/<cell>/`, manifest `pads/pads.txt`, `final/gds/slot_7.gds`).
- Still missing in Tim's `main`, supplied as patches 0001-0004 in `docs/slot7_v2_test/patches/`: custom-pad support in
  `parse_config.py`, the label procedures, `make frame-custom-io`, the pad netlists in the LVS scripts, `.gitignore`.

Places: HOST = your computer's shell, CONT = the IIC-OSIC-TOOLS container's shell, `H` = the harness clone
(HOST `~/EDA/<clone>`, CONT `/foss/designs/<clone>`). Log one-liner (CONT): `make T > >(tee T.out) 2> >(tee T.err >&2)`.

## 1. Harness (HOST)

Tim's `main` (or this fork's `main`, identical) plus the four patches:
```
git clone --recurse-submodules git@github.com:RTimothyEdwards/sg13cmos5l_ocd_chipalooza.git H
cd H
git am <path>/0001-*.patch <path>/0002-*.patch <path>/0003-*.patch <path>/0004-*.patch
git config fetch.recurseSubmodules false
```
Optional freeze in `config.txt`: `s7_version:` `main` `<commit of sg13cmos5l_cm_slot7 main>` (the test used 454da6a).

## 2. Libraries, slot 7, custom pads (CONT, `H`)
```
export PDK_ROOT=/foss/pdks PDK=ihp-sg13cmos5l
make setup
make projects SLOTS=7
make setup-custom
```
Check: `make setup-custom` lists both pads with `GDS: dependencies/slot_7/pads/<cell>/<cell>.gds`.
(magic 8.3.685 only: put `docs/slot7_v2_test/shim` of the test branch on PATH first; its `locking disable` makes cells
read-only.)

## 3. Chip-core Verilog by hand (HOST, `H`)
```
./scripts/custom_io_verilog.py > verilog_edits.txt
```
For each block in `verilog_edits.txt`: in the named file, find the lines after `FIND` (once; twice where it says BOTH
instances) and put the lines after `REPLACE` in their place, or delete them. The leading `|` is not part of the text.
Files: `verilog/rtl/chipalooza_frame.v`, `verilog/gl/sg13cmos5l_ocd_chipalooza.v`, `verilog/rtl/digital_tb.v`,
`verilog/rtl/slot7_wrapper.v`. Not covered: the harness xschem sheets (`xschem/chipalooza_frame.sch`,
`xschem/sg13cmos5l_ocd_chipalooza.sch`); `make lvs-top` needs them updated for slot 7.

## 4. Build (CONT, `H`), in this order (or `make all`, which now includes frame-custom-io)
```
make clean-config
make config
make padframe
make frame-custom-io
make wrappers
make gds-slots
make user-id
make projects-gds SLOTS=7
make gds-prefill
```
Check: `make config` prints no `Bad pad type`.

## 5. Checks (CONT, `H`)
```
python3 docs/slot7_v2_test/netcheck_slot7.py gds/sg13cmos5l_ocd_chipalooza.gds.gz sg13cmos5l_ocd_chipalooza 1901.1 2271.1 2096.1 2471.1 --merged s7_an_0_vcm,s7_an_1_vref --merged s7_an_0_en_3v3,s7_an_1_en_3v3 --merged s7_an_0_en_3v3_b,s7_an_1_en_3v3_b
make extract-padframe
make lvs-padframe
```
Expected: `RESULT all 13 pins OK` (the `--merged` groups are slot 7 v2's own ties, see its `docs/FOR_TIM.md`); in
`validate/comp_sg13cmos5l_padframe.out` both custom pads "Netlists match", all slot-7 pins matched (the top's
"failed pin matching" is the known mismatch outside slot 7).
