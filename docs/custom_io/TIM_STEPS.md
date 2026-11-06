# Manual steps of the harness owner (Tim's role), slot 7 with custom pads

Who does what: the **slot designer** delivers pads and slot in the slot repository
`tatzelbrumm/sg13cmos5l_cm_slot7` (default branch `main`). The **harness owner** does the steps below in the harness.
Nothing is copied from the slot designer by hand: everything comes through `git submodule`.

Places used below:
- HOST = your computer's shell. CONT = the IIC-OSIC-TOOLS container's shell.
- `C6` = the clone of this branch: HOST `~/EDA/c6_tim`, CONT `/foss/designs/c6_tim`.
- Log one-liner for a make target `T` (CONT): `make T > >(tee T.out) 2> >(tee T.err >&2)`

## 0. Slot designer (once): pads on `main`

HOST, in a clone of `sg13cmos5l_cm_slot7`: merge `claude/c6-pads-layout` into `main` and push. Note the commit hash:

```
git switch main
git merge --ff-only origin/claude/c6-pads-layout
git push origin main
git log -1 --format=%H
```

## 1. Clone the harness branch (HOST)

```
cd ~/EDA
git clone --recurse-submodules -b claude/c6-submodule-pads git@github.com:tatzelbrumm/sg13cmos5l_ocd_chipalooza.git c6_tim
cd c6_tim
git config fetch.recurseSubmodules false
```

## 2. Edit `config.txt` (HOST, editor, 4 lines)

| line | before | after |
|---|---|---|
| `s7_source:` | `https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single` | `https://github.com/tatzelbrumm/sg13cmos5l_cm_slot7` |
| `s7_version:` | `-` `-` | `main` `<hash from step 0>` |
| `s7_an[0]:` | `sg13cmos5l_IOPadAnalog` `s7_an_0` | `sg13cmos5l_IOPadSingle2Diff` `s7_an_0` |
| `s7_an[1]:` | `sg13cmos5l_IOPadAnalog` `s7_an_1` | `sg13cmos5l_IOPadDiff2Single` `s7_an_1` |

Separate the fields with tabs, as in the other lines.

## 3. Fetch slot 7 (CONT, `C6`)

```
cd /foss/designs/c6_tim
export PDK_ROOT=/foss/pdks PDK=ihp-sg13cmos5l
export PATH=$PWD/docs/custom_io/tools/shim:$PATH      # only if magic --version is 8.3.685
make projects SLOTS=7
```

Check: `ls dependencies/slot_7/pads` shows `pads.txt` and two pad directories.

Commit (HOST, `C6`): `git add config.txt .gitmodules dependencies/slot_7` then `git commit -m "slot 7: custom pads from sg13cmos5l_cm_slot7"`.

## 4. Libraries and pads (CONT, `C6`)

```
make setup
make custom-io
```

Check: the last line says `Imported 2 custom pad cell(s)`.

## 5. Chip-core Verilog by hand (HOST, `C6`, editor)

```
./scripts/custom_io_verilog.py > verilog_edits.txt
```

Open `verilog_edits.txt`. For each block: open the named file, find the lines after `FIND` (they are there exactly
once, or twice where it says BOTH instances), replace them with the lines after `REPLACE` (or delete them). The
`|` at the start of each line is not part of the text. Files: `verilog/rtl/chipalooza_frame.v`,
`verilog/gl/sg13cmos5l_ocd_chipalooza.v`, `verilog/rtl/digital_tb.v`, `verilog/rtl/slot7_wrapper.v`.

Commit: `git commit -am "slot 7: chip-core Verilog for the custom pad nets"`.

## 6. Build (CONT, `C6`), in this order, with the log one-liner

```
make clean-config
make config
make padframe
make frame-custom-io
make wrappers
make gds-slots
make projects-gds SLOTS=7
make gds-prefill
```

## 7. Check

CONT, `C6`:
```
python3 docs/custom_io/tools/netcheck_slot7.py gds/sg13cmos5l_ocd_chipalooza.gds.gz sg13cmos5l_ocd_chipalooza 1901.1 2271.1 2096.1 2471.1
```
must end with `RESULT all 13 pins OK`. (This check script is not Tim's; Tim's own check is `make extract-top` and
`make lvs-top`.)

View: `klayout gds/sg13cmos5l_ocd_chipalooza.gds.gz`, slot 7 at x 1380-1917, y 2170-2443 um, pads to its right.

## 8. Keep the result (HOST, `C6`)

```
git add -A magic gds verilog scripts/gen_padframe.tcl scripts/user_projects.tcl xschem
git commit -m "slot 7 custom pads: regenerated views"
git push origin claude/c6-submodule-pads
```
