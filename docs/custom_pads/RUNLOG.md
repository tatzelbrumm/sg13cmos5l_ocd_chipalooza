# RUNLOG: custom-pad integration test on the harness fork

Command journal, one entry per step, in order. Entries are appended by
`docs/custom_pads/tools/run.sh NN name -- cmd` (UTC times, full command, cwd, exit
status, log files), with a hand-written "changed:" line after each step. Failed steps
and retries stay in.

## Tool versions (recorded once, 2026-11-05T18:41:10Z)

| tool | version |
|---|---|
| magic | 8.3.685 |
| klayout | KLayout 0.30.12 |
| netgen | Netgen 1.5.324 |
| xschem | XSCHEM V3.4.8RC |
| python3 | Python 3.13.18 |
| PDK | /foss/pdks/ihp-sg13cmos5l -> /foss/pdks/IHP-Open-PDK/ihp-sg13cmos5l, IHP-Open-PDK commit df4c5054ee8ca481c3eb873687274f28cdb50b1e |
| harness | tatzelbrumm/sg13cmos5l_ocd_chipalooza main e0445b61c035b5415f6d193d145511589f3758b0 (branch custom-pad-test created from it) |
| slot repo | tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single toplevel 91a7da8b67ac56a26c605501146667a1fde28c32 |
| submodule dependencies/sg13cmos5l_ocd_ip__analog_switches | d210467cf74b58de74cd48b3f676cd10194e8d33 |
| submodule dependencies/sg13cmos5l_ocd_ip__biasgen | 0dbfff6c06732c5a0d9802bbdfa274ff7bc6fcfc |
| submodule dependencies/sg13cmos5l_ocd_ip__por | c56195e14e5f56f5b9e335a9a800906bf3fb47a6 |

Environment for every step: `export PDK_ROOT=/foss/pdks PDK=ihp-sg13cmos5l`.

## Journal

### 00 setup (manual, before the runner existed)
- 2026-11-05T18:29Z, cwd `/home/user`: `git clone --depth 1 https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single /home/user/sg13cmos5l_cm_ip__single2diff2single` (exit 0); the harness fork was already cloned by the session at `/home/user/sg13cmos5l_ocd_chipalooza`.
- cwd slot repo: `git fetch origin toplevel` (exit 0, but in the shallow single-branch clone it only set FETCH_HEAD, so `git show origin/toplevel:...` failed: "invalid object name"); retry `git fetch origin toplevel:refs/remotes/origin/toplevel` (exit 0); `git checkout -b toplevel origin/toplevel`.
- cwd harness: `git fetch origin main`; `git checkout -b custom-pad-test origin/main`; `git submodule update --init --recursive` (exit 0). The clone was not made with `--recurse-submodules` (the session cloned it); the submodule update is equivalent.
- `docs/custom_pads/TASK.md` = `git show origin/toplevel:docs/launch/custom_pad_harness_test_TASK.md` (unchanged copy).
- A first attempt to write this header hung on `netgen -batch quit` reading stdin (no `</dev/null`) and was stopped after 600 s; rerun with `</dev/null`.

### 01 make_setup
- start 2026-11-05T18:42:21Z, end 2026-11-05T18:43:03Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make setup`
- exit status: 0
- logs: `logs/01_make_setup.out`, `logs/01_make_setup.err`
- changed: magic/sg13cmos5l_io/, magic/sg13cmos5l_stdcell/ created (gitignored). SRAM import failed: /foss/pdks/ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram/ has no RM_IHPSG13_1P_1024x8_c2_bm_bist gds/lef/cdl in this PDK checkout; magic/sg13cmos5l_sram/ holds only an empty cell.

### 02 make_check
- start 2026-11-05T18:45:49Z, end 2026-11-05T18:45:50Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make check`
- exit status: 0
- logs: `logs/02_make_check.out`, `logs/02_make_check.err`
- changed: nothing (read-only check).

### 03 make_clean-config
- start 2026-11-05T18:45:56Z, end 2026-11-05T18:45:56Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/03_make_clean-config.out`, `logs/03_make_clean-config.err`

### 04 make_config
- start 2026-11-05T18:45:56Z, end 2026-11-05T18:45:57Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/04_make_config.out`, `logs/04_make_config.err`
- changed (03): the five generated files moved to archive/ (archive/ is tracked, so it shows as modified).
- changed (04): scripts/gen_padframe.tcl, verilog/gl/sg13cmos5l_padframe.v, verilog/gl/chipalooza_frame_wrapper.v regenerated. They DIFFER from the committed copies: config.txt on main sets s6_an[0]/s13_an[0] = IOPadIn, s6_an[1]/s13_an[1]/s17_an[0..1] = IOPadOut16mA, but the committed generated files still have IOPadAnalog there. `make check` (02) did not report this as stale.

### 05 make_padframe
- start 2026-11-05T18:46:09Z, end 2026-11-05T18:46:18Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/05_make_padframe.out`, `logs/05_make_padframe.err`
- changed: magic/sg13cmos5l_padframe.mag, magic/chipalooza_frame_wrapper.mag, magic/padframe_pins.mag rewritten (differ from committed: pad types of s6/s13/s17 and timestamps). Log ends with 'File chipalooza_frame_wrapper.mag is read_only and cannot be written' from a second write attempt; the first writeall had already written it (file mtime updated).

### 06 make_wrappers
- start 2026-11-05T18:46:35Z, end 2026-11-05T18:46:38Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make wrappers`
- exit status: 0
- logs: `logs/06_make_wrappers.out`, `logs/06_make_wrappers.err`
- changed (06): ALL 18 magic/slot<N>_wrapper.mag rewritten EMPTY (only header and FIXED_BBOX), originals moved to archive/, and a stray file magic/can appeared. Cause, found by test: magic 8.3.685 opens every cell read from disk as read-only after `locking disable` (test: `load central_column` prints "read-only" with `locking disable`, "writeable" without). So `select cell slotN_wrapper_0; delete` fails ("The current cell is not editable"), `cellname delete` fails ("non-top-level dependency in use"), and `select save slotN_wrapper` fails ("Can't rename cell '__SELECT__' ..."). The same bug hit 05: after `select save chipalooza_frame_wrapper` the cell is re-loaded read-only, so the via erase and obstruction steps at the end of gen_padframe.tcl were skipped ("The cell is not editable" x5) and the written chipalooza_frame_wrapper.mag is not the intended one.

### 07 restore and workaround (manual)
- cwd harness: `git checkout -- archive magic scripts/gen_padframe.tcl verilog/gl && rm -f magic/can` (tree back to main state).
- Added the PATH shim `docs/custom_pads/tools/shim/magic` (new file; not a harness change): it redefines the Tcl command `locking` so that `locking disable` is a no-op, then pipes stdin to /usr/local/bin/magic. All later steps run with `export PATH=/home/user/sg13cmos5l_ocd_chipalooza/docs/custom_pads/tools/shim:$PATH`. Test in a scratch directory: with the shim, `locking disable; load central_column` gives a writeable cell.
- A first version of the shim hung on `magic --version` (cat waiting on stdin); it now passes --version straight through.

### 08 make_clean-config
- start 2026-11-05T18:58:25Z, end 2026-11-05T18:58:25Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/08_make_clean-config.out`, `logs/08_make_clean-config.err`

### 09 make_config
- start 2026-11-05T18:58:25Z, end 2026-11-05T18:58:25Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/09_make_config.out`, `logs/09_make_config.err`

### 10 make_padframe
- start 2026-11-05T18:58:25Z, end 2026-11-05T18:58:34Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/10_make_padframe.out`, `logs/10_make_padframe.err`

### 11 make_wrappers
- start 2026-11-05T18:58:34Z, end 2026-11-05T18:58:38Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make wrappers`
- exit status: 0
- logs: `logs/11_make_wrappers.out`, `logs/11_make_wrappers.err`

### 12 make_gds-slots
- start 2026-11-05T18:58:53Z, end 2026-11-05T18:58:54Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make gds-slots`
- exit status: 0
- logs: `logs/12_make_gds-slots.out`, `logs/12_make_gds-slots.err`

### 13 make_check
- start 2026-11-05T18:58:54Z, end 2026-11-05T18:58:55Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make check`
- exit status: 2
- logs: `logs/13_make_check.out`, `logs/13_make_check.err`
- changed (08-12): regenerated the same files as 03-06 plus gds/slot<N>_wrapper.gds, now with the shim: no 'not editable' messages; slot7_wrapper.mag differs from the committed one only in timestamp and label order; gds/slot*_wrapper.gds same size. Baseline copies of all generated files kept outside the repo for later comparison (sha256 in FINDINGS).
- changed (13): nothing; exit 2 because check_staleness.py compares mtimes and every regenerated .mag is newer than its .sym/_lvs.v.

### 14 make_symbols
- start 2026-11-05T18:59:06Z, end 2026-11-05T18:59:07Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make symbols`
- exit status: 2
- logs: `logs/14_make_symbols.out`, `logs/14_make_symbols.err`

### 15 chat log export (stopped)
- 2026-11-05 ~19:05Z: the planned export of the visible conversation from the session's raw transcript (.jsonl) by a small Python filter was denied by the session's permission classifier. Recorded as a stop in the chat log header with a gap marker; not retried, not worked around. The filter script was removed again (not committed).

### 14 make symbols (baseline)
- Fails on main's own state: `gen_xschem_sym.py` exits with "magic/slot6_wrapper.mag: port 119 has two names: s6_an_0_esd, s6_an_0". Cause: chipalooza_frame.mag holds FLAT copies of the pad-edge strips and labels, which run_gen_user_wrappers.sh carves into the slot wrappers. For slot 6 the new digital-pad strips (s6_an_0, s6_an_1) were added to chipalooza_frame.mag but the old analog strips/labels (s6_an[0], s6_an_0_esd, ...) were not removed, so the two labels merge into one port. The regenerated chipalooza_frame_wrapper.mag (from `make padframe`) does NOT feed the slot wrappers at all.

### note: SRAM macro (after a user question)
- /foss/pdks/IHP-Open-PDK (github.com/IHP-GmbH/IHP-Open-PDK, commit df4c5054) tracks `ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram` as a symlink (git mode 120000) into `ihp-sg13g2/libs.ref/sg13g2_sram`, and the files RM_IHPSG13_1P_1024x8_c2_bm_bist.{gds,lef,cdl} are in that repo. The environment's sparse checkout includes only `/ihp-sg13cmos5l/` and parts of `ihp-sg13g2/libs.tech`, so the link target is absent. Fix outside this test: add `/ihp-sg13g2/libs.ref/sg13g2_sram/` to the sparse checkout, then re-run `make setup`. Not on the slot-7 critical path (SRAM is in chipalooza_frame's housekeeping area); left as is.

## Phase 1: import of the pad GDS

### 16 setup_custom_io
- start 2026-11-05T19:04:13Z, end 2026-11-05T19:04:16Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `./scripts/setup_custom_io.sh`
- exit status: 0
- logs: `logs/16_setup_custom_io.out`, `logs/16_setup_custom_io.err`
- changed (16): magic/custom_io/: cm_d2s_*.mag, cm_s2d_*.mag, the two pad .mag, gds/*.uniq.gds. FIXED_BBOX came out as 0 0 32000 72000 (twice the intended 16000 36000) because magic rescaled the grid on GDS input ('units rescaled by factor of 5 / 1') and does not convert the property; script changed to set FIXED_BBOX in a second session on the written .mag.

### 17 setup_custom_io
- start 2026-11-05T19:04:54Z, end 2026-11-05T19:04:57Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `./scripts/setup_custom_io.sh`
- exit status: 0
- logs: `logs/17_setup_custom_io.out`, `logs/17_setup_custom_io.err`
- changed (17): FIXED_BBOX still 0 0 32000 72000: the property command takes lambda, so 16000 36000 lambda = 32000 72000 internal. Also a stray magic/$$$CONTEXT_INFO$$$.mag appeared: KLayout had written its context-info cell into the .uniq.gds. Fixed both (uniquify writes without context info; FIXED_BBOX given as 0 0 8000 18000 lambda); stray file deleted.

### 18 setup_custom_io
- start 2026-11-05T19:05:26Z, end 2026-11-05T19:05:29Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `./scripts/setup_custom_io.sh`
- exit status: 0
- logs: `logs/18_setup_custom_io.out`, `logs/18_setup_custom_io.err`
- changed (18): FIXED_BBOX now 0 0 16000 36000 in both pad .mag; .uniq.gds have exactly one top cell (60 resp. 44 cells). Ports: D2S pad vinp vinn vref iref en_3v3_b en_3v3 iovdd iovss vdd; S2D vref outp outn vcm en_3v3 en_3v3_b iref pad vdd iovss iovdd. No vss port (vss is the substrate only), no vfb/vfbp/vfbn/vcmfb port. scripts/layout_setup.tcl: added 'addpath custom_io'.
- 19 (first attempt) stopped by hand after 300 s: the Tcl file was given as an argument (magic reads arguments as layout names), not on stdin; the runner wrote no journal entry because it was killed. Re-run as 20.
- 20: cells coexist (112 loaded, 59 cm_d2s_*, 43 cm_s2d_*, no name conflicts), then the test hung in its own port-listing loop (my 'port first/next' loop never ended) and was cut by timeout 300 (exit 124). Port lists are taken from the .mag files instead (see 18). Loop removed; re-run as 21.

### 21 coexist_test
- start 2026-11-05T19:16:48Z, end 2026-11-05T19:16:49Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza/magic`
- command: `bash -c magic -dnull -noconsole -rcfile /foss/pdks/ihp-sg13cmos5l/libs.tech/magic/ihp-sg13cmos5l.magicrc < ../docs/custom_pads/tools/coexist_test.tcl`
- exit status: 0
- logs: `logs/21_coexist_test.out`, `logs/21_coexist_test.err`
- changed (21): nothing (test only). Result: both custom pads and the foundry pads load in one magic session; FIXED_BBOX 0 0 80 180 um for all three. Trap c: `git check-ignore` confirms magic/custom_io/ is NOT ignored (only magic/sg13cmos5l_io/ etc. are).

Phase 1 result: trap a, the geometry outside x 0..80 um (layers 31/0 and 14/0) is identical to sg13cmos5l_IOPadAnalog, as are the metal rails within 1 um of either edge (no XOR difference on 30/0, 50/0, 126/0); trap b, 13 of the 21 shared sub-cell names differ in content (Clamp_N_M1, Clamp_P_M1, DCNDiode, DCPDiode, edge_stubs, nmosHV, nmosHV$1..$7, rppd), 8 are identical; none collides with a foundry cell; solved by prefixing all sub-cells (cm_d2s_, cm_s2d_) in derived .uniq.gds files.
- note: logs/20_coexist_test.err was 830 MB (endless loop output); truncated by hand to its first 50 and last 20 lines plus the distinct lines, so that it can be pushed (GitHub limit 100 MB).

## Phase 2: make the pads digestible
- (manual edits, see FINDINGS file table) scripts/custom_io.tcl (new), scripts/parse_config.py (CUSTOM_PADS), scripts/gen_padframe_template.tcl (+addpath custom_io, +source custom_io.tcl), config.txt (s7_an[0] = sg13cmos5l_IOPadSingle2Diff, s7_an[1] = sg13cmos5l_IOPadDiff2Single, + comment).

### 22 make_clean-config
- start 2026-11-05T19:20:18Z, end 2026-11-05T19:20:18Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/22_make_clean-config.out`, `logs/22_make_clean-config.err`

### 23 make_config
- start 2026-11-05T19:20:18Z, end 2026-11-05T19:20:19Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/23_make_config.out`, `logs/23_make_config.err`
- changed (22, 23): generated files regenerated; diff against the Phase 0 baseline is limited to slot 7 (pad types, 13 label_right_custom lines, 13 ports) plus the two template lines (addpath custom_io, source custom_io.tcl).

### 24 make_padframe
- start 2026-11-05T19:20:29Z, end 2026-11-05T19:20:38Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/24_make_padframe.out`, `logs/24_make_padframe.err`
- changed (24): padframe built, 13 straps present, but on the 10 nm lambda grid (via2 0.19 um tall, too small for a cut; strap end 1900.30 instead of 1900.295) because gen_padframe.tcl runs without 'snap internal'. scripts/custom_io.tcl now sets 'snap internal' inside custom_io_paint and restores the old mode.

### 25 make_clean-config
- start 2026-11-05T19:21:07Z, end 2026-11-05T19:21:07Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/25_make_clean-config.out`, `logs/25_make_clean-config.err`

### 26 make_config
- start 2026-11-05T19:21:07Z, end 2026-11-05T19:21:07Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/26_make_config.out`, `logs/26_make_config.err`

### 27 make_padframe
- start 2026-11-05T19:21:07Z, end 2026-11-05T19:21:16Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/27_make_padframe.out`, `logs/27_make_padframe.err`
- changed (25-27): same result; 'snap internal' did not help. Found by test: the padframe session runs on a 10 nm internal grid (the 5 nm magscale appears only in the file), so 5 nm coordinates are rounded. scripts/custom_io.tcl: custom_io_fine_grid runs 'scalegrid 1 2' once if the internal grid is coarser than 5 nm.

### 28 make_clean-config
- start 2026-11-05T19:22:44Z, end 2026-11-05T19:22:44Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/28_make_clean-config.out`, `logs/28_make_clean-config.err`

### 29 make_config
- start 2026-11-05T19:22:44Z, end 2026-11-05T19:22:44Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/29_make_config.out`, `logs/29_make_config.err`

### 30 make_padframe
- start 2026-11-05T19:22:44Z, end 2026-11-05T19:22:54Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/30_make_padframe.out`, `logs/30_make_padframe.err`
- changed (28-30): same rounding; the scalegrid check did not fire. Not pursued further: scripts/custom_io.tcl now places the strap on the 10 nm grid by construction (via 0.2 x 0.2 at the 10 nm position just below the pin center, strap end 0.30 um inside the pad); the snap/scalegrid code was removed again. A debug session to find the cause failed (custom_io_rects errored on a hand-placed pad) and is not in the logs.

### 31 make_clean-config
- start 2026-11-05T19:23:38Z, end 2026-11-05T19:23:39Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/31_make_clean-config.out`, `logs/31_make_clean-config.err`

### 32 make_config
- start 2026-11-05T19:23:39Z, end 2026-11-05T19:23:39Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/32_make_config.out`, `logs/32_make_config.err`

### 33 make_padframe
- start 2026-11-05T19:23:39Z, end 2026-11-05T19:23:47Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/33_make_padframe.out`, `logs/33_make_padframe.err`
- changed (31-33): strap now on the 10 nm grid (via2 1900.05..1900.25 x 2266.10..2266.30, M3 1898.9..1900.30 x 2266.06..2266.35 for s7_an_0_vref). Padframe/frame-wrapper .mag differ from the Phase 0 baseline only in the slot-7 zone (x 1898..1901.2 and the two pad cells; the old outer analog strips at x 2075.9..2077 are gone), in port index renumbering, and one label moved in file order (s8_an_0_esd, same geometry).

### 34 lef_experiment
- start 2026-11-05T19:24:33Z, end 2026-11-05T19:25:00Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `docs/custom_pads/tools/lef_experiment.sh`
- exit status: 0
- logs: `logs/34_lef_experiment.out`, `logs/34_lef_experiment.err`
- changed (34): docs/custom_pads/lef_experiment/: padframe .mag of variants A (FIXED_BBOX, no LEF), B (magic "lef write" + "lef read" annotation), C (no FIXED_BBOX), and the two LEF files. A vs B: 0 differing lines (timestamps ignored). A vs C: 342 lines; without FIXED_BBOX every pad from pad_s7_an_0 on moves by 0.62 um (124 units) per custom pad. Final rebuild with the committed .mag; magic/custom_io/ restored from git; LEF files moved out of magic/custom_io/lef/ (not needed there).
- (manual) netlist/schematic/custom_io.spice (new; concatenation of the two *_magic.spice from the slot repo, second unit_r2 dropped, identical); validate/run_lvs_padframe.sh and validate/run_lvs_ocd_chipalooza.sh: +1 readnet line each; scripts/run_update_frame_custom_io.sh (new); Makefile: + target frame-custom-io.

### 35 make_frame-custom-io
- start 2026-11-05T19:26:18Z, end 2026-11-05T19:26:26Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/35_make_frame-custom-io.out`, `logs/35_make_frame-custom-io.err`
- changed (35): chipalooza_frame.mag: in the two s7 pad bands the old analog strips/labels (s7_an[0], s7_an_0_esd, s7_an[1], s7_an_1_esd) erased, 13 M3 straps + port labels painted. Found: s7_an_0_en_3v3 strap 2296.455..2296.745 here but 2296.45..2296.74 in the padframe (the S2D pin is off the 10 nm grid and the padframe session rounds). custom_io.tcl changed to put the strap edges on 10 nm too; chipalooza_frame.mag restored from git and the sequence re-run (36-39).

### 36 make_clean-config
- start 2026-11-05T19:26:52Z, end 2026-11-05T19:26:52Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/36_make_clean-config.out`, `logs/36_make_clean-config.err`

### 37 make_config
- start 2026-11-05T19:26:52Z, end 2026-11-05T19:26:53Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/37_make_config.out`, `logs/37_make_config.err`

### 38 make_padframe
- start 2026-11-05T19:26:53Z, end 2026-11-05T19:27:01Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/38_make_padframe.out`, `logs/38_make_padframe.err`

### 39 make_frame-custom-io
- start 2026-11-05T19:27:01Z, end 2026-11-05T19:27:09Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/39_make_frame-custom-io.out`, `logs/39_make_frame-custom-io.err`

### 40 make_wrappers
- start 2026-11-05T19:27:19Z, end 2026-11-05T19:27:21Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make wrappers`
- exit status: 0
- logs: `logs/40_make_wrappers.out`, `logs/40_make_wrappers.err`
- changed (36-39): straps identical in padframe and chipalooza_frame (13 y-intervals compared).
- changed (40): slot wrappers regenerated. Slot 7 got every new port TWICE, 1 internal unit (5 nm) apart: run_gen_user_wrappers.sh also copies the paint/labels of the expanded subcell chipalooza_frame_wrapper_0, which sits in chipalooza_frame at "transform 1 0 0 0 1 1" (+5 nm in y); the hand-made flat copies in main are at that same +5 nm, which is why they never doubled. Other slots: only "port N" index lines differ from the baseline (renumbered), no geometry or label line.
- scripts/run_update_frame_custom_io.sh changed to ERASE only (stale flat copies in the custom pads' bands), no painting; the new pins come from chipalooza_frame_wrapper_0 alone. chipalooza_frame.mag restored from git, re-run as 41-42.

### 41 make_frame-custom-io
- start 2026-11-05T19:28:13Z, end 2026-11-05T19:28:19Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/41_make_frame-custom-io.out`, `logs/41_make_frame-custom-io.err`

### 42 make_wrappers
- start 2026-11-05T19:28:20Z, end 2026-11-05T19:28:22Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make wrappers`
- exit status: 0
- logs: `logs/42_make_wrappers.out`, `logs/42_make_wrappers.err`
- changed (41, 42): only pad_s7_an_0's band was cleaned; error 'can't use empty string as operand of "-"' at the first pin of pad_s7_an_1 ('instance list abutment <name>' returned nothing). Script changed to 'select cell <pad>; instance list abutment' as gen_padframe.tcl does. chipalooza_frame.mag restored from git; re-run as 43-44.

### 43 make_frame-custom-io
- start 2026-11-05T19:28:42Z, end 2026-11-05T19:28:43Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/43_make_frame-custom-io.out`, `logs/43_make_frame-custom-io.err`

### 44 make_wrappers
- start 2026-11-05T19:28:43Z, end 2026-11-05T19:28:45Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make wrappers`
- exit status: 0
- logs: `logs/44_make_wrappers.out`, `logs/44_make_wrappers.err`
- changed (43, 44): chipalooza_frame.mag: in the two s7 bands the flat strips and labels s7_an[0], s7_an_0_esd, s7_an[1], s7_an_1_esd erased, nothing else there (the band listing before/after is in the log). slot7_wrapper.mag: exactly the 13 new ports (M3, x 535.05..536.45 slot-local) and none of the old s7 pad pins.
- `python3 scripts/gen_xschem_sym.py slot7_wrapper` (cwd harness, manual, exit 1): "magic/slot6_wrapper.mag: port 119 has two names: s6_an_0_esd, s6_an_0" (main's defect, see 14). Workaround in docs/custom_pads/tools/symbols_slot7.sh (new): main's committed slot6_wrapper.mag in place for that one run.

### 45 symbols_slot7
- start 2026-11-05T19:29:37Z, end 2026-11-05T19:29:38Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `docs/custom_pads/tools/symbols_slot7.sh`
- exit status: 0
- logs: `logs/45_symbols_slot7.out`, `logs/45_symbols_slot7.err`
- changed (45): xschem/slot7_wrapper.sym and verilog/gl/slot7_wrapper_lvs.v regenerated (29 pins; slot template now 200 x 700, 34 left rows, because the row template is the union over all 18 wrappers: a full `make symbols` would re-lay-out all 18 symbols). Only slot 7's files written.
- (manual) verilog/rtl/slot7_wrapper.v: `s7_an[1:0]` and `s7_an_0_esd` replaced by the 13 scalar `inout wire` ports, with comments.
- NOT changed (STOP condition "chip core", written down in FINDINGS): verilog/rtl/chipalooza_frame.v (ports s7_an[1:0], s7_an_0_esd, s7_an_1_esd and the slot7_wrapper instance), verilog/gl/sg13cmos5l_ocd_chipalooza.v (wires s7_an_0_esd/s7_an_1_esd, padframe and frame instance connections), xschem/chipalooza_frame.sch, verilog/gl/chipalooza_tb.v, verilog/rtl/digital_tb.v. No script generates these.

## Phase 3: the padframe sequence (README steps 5-7), from a clean config

### 46 make_clean-config
- start 2026-11-05T19:30:38Z, end 2026-11-05T19:30:38Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make clean-config`
- exit status: 0
- logs: `logs/46_make_clean-config.out`, `logs/46_make_clean-config.err`

### 47 make_config
- start 2026-11-05T19:30:38Z, end 2026-11-05T19:30:38Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make config`
- exit status: 0
- logs: `logs/47_make_config.out`, `logs/47_make_config.err`

### 48 make_padframe
- start 2026-11-05T19:30:38Z, end 2026-11-05T19:30:47Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make padframe`
- exit status: 0
- logs: `logs/48_make_padframe.out`, `logs/48_make_padframe.err`

### 49 make_frame-custom-io
- start 2026-11-05T19:30:47Z, end 2026-11-05T19:30:48Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/49_make_frame-custom-io.out`, `logs/49_make_frame-custom-io.err`

### 50 make_wrappers
- start 2026-11-05T19:30:48Z, end 2026-11-05T19:30:50Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make wrappers`
- exit status: 0
- logs: `logs/50_make_wrappers.out`, `logs/50_make_wrappers.err`

### 51 make_gds-slots
- start 2026-11-05T19:30:50Z, end 2026-11-05T19:30:51Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make gds-slots`
- exit status: 0
- logs: `logs/51_make_gds-slots.out`, `logs/51_make_gds-slots.err`

### 52 make_check
- start 2026-11-05T19:30:51Z, end 2026-11-05T19:30:52Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make check`
- exit status: 2
- logs: `logs/52_make_check.out`, `logs/52_make_check.err`
- changed (46-52): all exit 0 except make check (exit 2, mtime-based staleness of 38 views; 1 not built). Step 7 of the README: `make wrappers` (run_gen_user_wrappers.sh, regenerates slot<N>_wrapper.mag from chipalooza_frame) must run BEFORE `make gds-slots` (run_gen_wrapper_gds.sh only writes GDS of the existing .mag); the README names only gds-slots. With custom pads, `make frame-custom-io` goes between padframe and wrappers.
- 53: `python3 docs/custom_pads/tools/gds_compare.py <baseline>/slotN_wrapper.gds gds/slotN_wrapper.gds` for N = 1..18 (cwd harness): all SAME (shapes per layer and texts) except slot 7. Byte comparison is useless (GDS time stamps).
- 54 (first attempt, padframe_drc.sh writing the whole padframe GDS): stopped by hand after ~14 min, magic still in 'Generating output for cell sg13cmos5l_padframe'; no journal entry (killed). Script changed to save and write only the region around the slot-7 pads.

### 55 padframe_drc
- start 2026-11-05T19:44:47Z, end 2026-11-05T19:48:12Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `docs/custom_pads/tools/padframe_drc.sh /tmp/claude-0/-home-user-sg13cmos5l-ocd-chipalooza/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/baseline/main/sg13cmos5l_padframe.mag`
- exit status: 0
- logs: `logs/55_padframe_drc.out`, `logs/55_padframe_drc.err`
- changed (55): nothing in the tree (outputs in the scratchpad: clip GDS of x 1860..2180, y 2180..2540 um of the current and the baseline padframe, KLayout DRC reports). 3 min 25 s.
- 56: `python3 docs/custom_pads/tools/lyrdb_summary.py clip_now.lyrdb clip_base.lyrdb`: now 116 violations (Pad.fR_M2 64, Pad.fR_M3 16, Pad.fR_M4 16, Pad.fR_TM1 16, Pad.fR_M1 4), baseline 101; all are the RECOMMENDED rule "Min. recommended Mx exit length is 7.0 um" at the bond pad edge (x 2075.1..2077.0) of every pad, foundry pads included; the +15 on Pad.fR_M2 come from the custom pads' finer M2 finger pattern there. No violation of a mandatory rule and none at the new straps (x 1898.9..1900.3).

## Phase 4: slot 7 through the ordinary flow
- (manual, slot repo) branch harness-test created from toplevel 91a7da8b67ac56a26c605501146667a1fde28c32; `macros/slot/harness_test/build_views.sh /home/user/sg13cmos5l_ocd_chipalooza/magic/slot7_wrapper.mag` (cwd slot repo, exit 0) wrote final/gds/slot_7.gds, final/{lef,lib,vh}/slot_7.*, macros/slot/harness_test/slot7_pins.md; KLayout DRC of slot_7.gds (feol, beol, deep): 0 violations. Committed and pushed as 4611357166b7368be4fbf8e176b1e82b8a9a85d0.
- (manual) config.txt: `s7_version:	harness-test	4611357166b7368be4fbf8e176b1e82b8a9a85d0` (format: branch, then commit, tab-separated, as get_projects.sh --help describes).

### 59 make_projects_7
- start 2026-11-05T19:50:14Z, end 2026-11-05T19:50:26Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make projects SLOTS=7`
- exit status: 0
- logs: `logs/59_make_projects_7.out`, `logs/59_make_projects_7.err`
- changed (59): dependencies/slot_7 added as submodule (gitlink 4611357), .gitmodules (branch = harness-test).

### 60 make_projects-gds_7
- start 2026-11-05T19:50:36Z, end 2026-11-05T19:50:47Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make projects-gds SLOTS=7`
- exit status: 0
- logs: `logs/60_make_projects-gds_7.out`, `logs/60_make_projects-gds_7.err`
- changed (60): scripts/user_projects.tcl (generated; 1 project placed, slot_7 at 1379.95 2170.05 um = slot7_wrapper position + frame offset 16.1 16.1).

### 61 make_user-id
- start 2026-11-05T19:50:56Z, end 2026-11-05T19:50:57Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make user-id`
- exit status: 0
- logs: `logs/61_make_user-id.out`, `logs/61_make_user-id.err`
- changed (61): magic/user_id_textblock.mag, magic/user_id_vias.mag, verilog/gl/user_id_programming.v (project_id 20260908 from config.txt; 6 verilog lines changed).
- 63 (manual, cwd harness): `python3 docs/custom_pads/tools/netcheck_slot7.py <scratch>/clip_now.gds clip_now 1885 2255 2080 2455 /home/user/sg13cmos5l_cm_ip__single2diff2single/final/gds/slot_7.gds 1363.85 2153.95` (padframe region + slot_7 at its padframe-relative position), exit 1: 9 pins OK, the outp/vinp and outn/vinn nets carry the S2D-internal labels vfbp, voutp resp. vfbn, voutn (documented in-cell ties, not shorts). Log logs/63_netcheck_clip_raw.out.
- 64: same after adding those four labels as documented in-cell aliases to the script: all 13 OK (logs/64_netcheck_clip.out).

### 57 make_extract-padframe
- start 2026-11-05T19:48:59Z, end 2026-11-05T19:56:06Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make extract-padframe`
- exit status: 0
- logs: `logs/57_make_extract-padframe.out`, `logs/57_make_extract-padframe.err`

### 58 make_lvs-padframe
- start 2026-11-05T19:56:06Z, end 2026-11-05T19:56:07Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make lvs-padframe`
- exit status: 0
- logs: `logs/58_make_lvs-padframe.out`, `logs/58_make_lvs-padframe.err`

### 62 make_gds-prefill
- start 2026-11-05T19:51:12Z, end 2026-11-05T19:56:20Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make gds-prefill`
- exit status: 0
- logs: `logs/62_make_gds-prefill.out`, `logs/62_make_gds-prefill.err`
- changed (57): netlist/layout/sg13cmos5l_padframe.spice (7 min 7 s). (58): validate/comp_sg13cmos5l_padframe.out. Result "Top level cell failed pin matching" (as in main's committed comp file); devices 500/499, nets 313/310; the mismatches are 2 x sg13cmos5l_ocd_Split200 present only in the verilog and the RC clamp nets of the supply pads (not slot 7). All 15 slot-7 pins (s7_an[0], s7_an[1] and the 13 core pins) match. Both custom pads: devices and nets match (S2D 37 nets; D2S 76 devices, 36 nets), "Netlists match with 7 symmetries with property errors"; property errors are only "mm_ok" (xschem parameter, 234 times); pin mismatch only iovss/vss (layout "sub" vs schematic iovss + separate vss): the known, accepted vss issue.
- changed (62): gds/sg13cmos5l_ocd_chipalooza.gds.gz (14.2 MB, gitignored), 5 min 9 s.

### 65 make_drc
- start 2026-11-05T19:56:38Z, end 2026-11-05T20:12:17Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `make drc`
- exit status: 0
- logs: `logs/65_make_drc.out`, `logs/65_make_drc.err`
- 65 `make drc` (full chip, pre-fill, deck flags of validate/run_klayout_drc.sh: deep, thr=16, conn_drc, wedge): rules finished after 813.66 s ("completed in 813.66 seconds"), then klayout was KILLED for lack of memory while the 1.42 GB report was written (the memory peak also coincided with my first attempt to parse the report). The script still printed "Done!" and the make target exited 0. The truncated report was deleted (unreadable XML). Not repeated: per the user, the full-chip check gives little insight for the slot-7 task; instead the same deck runs on a clip of the pre-fill GDS around slot 7 and its pads (68).
- 67: parsing the truncated report failed ("XML parser error: no element found"); log kept.

### 68 drc_s7_prefill_clip
- start 2026-11-05T20:13:33Z, end 2026-11-05T20:14:17Z
- cwd: `/home/user/sg13cmos5l_ocd_chipalooza`
- command: `klayout -b -zz -r /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/ihp-sg13cmos5l.drc -rd input=/tmp/claude-0/-home-user-sg13cmos5l-ocd-chipalooza/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/drc_s7/s7_prefill_clip.gds -rd report=/tmp/claude-0/-home-user-sg13cmos5l-ocd-chipalooza/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/drc_s7/s7_prefill_clip.lyrdb -rd feol=True -rd beol=True -rd run_mode=deep -rd thr=4 -rd topcell=s7_prefill_clip`
- exit status: 0
- logs: `logs/68_drc_s7_prefill_clip.out`, `logs/68_drc_s7_prefill_clip.err`
- 68 (cwd harness): KLayout clip of the pre-fill GDS x 1374.95..2196.1, y 2165.05..2483.05 um (python, scratchpad), then `klayout -b -zz -r /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/ihp-sg13cmos5l.drc -rd input=<clip> -rd report=<clip>.lyrdb -rd feol=True -rd beol=True -rd run_mode=deep -rd thr=4 -rd topcell=s7_prefill_clip`, 38.8 s, exit 0. 69: 228793 items, almost all clip artifacts (Seal.l 226520 from the cut seal ring, via/contact width at the cut edge). 70: `lyrdb_interior.py` with the box 1377..2170 x 2167..2481: 134 items entirely inside, all Seal.l on padframe top-level paint (artifact, see FINDINGS) or recommended Pad.fR_* at the bond pads; none inside slot 7.
- `make fill`, `make gds-final` not run (user: the full-chip steps give little insight for the slot-7 integration test).
- Phase 4 images: docs/custom_pads/pad_ring_s7.png, slot7_area.png, zoom_s7_an_1_pins.png (`python3 docs/custom_pads/tools/render_png.py gds/sg13cmos5l_ocd_chipalooza.gds.gz sg13cmos5l_ocd_chipalooza <box> <png> <width>`).
- Patch series: worktree from origin/main, `git cherry-pick 5e7d52f b03b3ba`, slot-7 inputs (config.txt, slot7_wrapper.v) as a third commit, `git format-patch origin/main -o docs/custom_pads/patches` (applies cleanly to main e0445b6); worktree removed.
- chat log sha256 (file as committed): `e3196128aba1b4f586ce810b75f956c321d61b0278fcb571fcc0560e214b15d9`  docs/custom_pads/chatlog/2026-11-05_claude_custom_pad_harness_test.md
- slot repo harness-test: docs/harness_test.md now points to harness commit 5b016e0 (slot repo commit c420259, pushed; the frozen slot GDS stays 4611357).

## Follow-up (user request): chip-core Verilog for slot 7 (lvs-top skipped by request)
- (manual edits) verilog/rtl/chipalooza_frame.v: ports `s7_an[1:0]`, `s7_an_0_esd`, `s7_an_1_esd` replaced by the 13 nets s7_an_0_{vref,outp,outn,vcm,en_3v3,en_3v3_b,iref}, s7_an_1_{vinp,vinn,vref,iref,en_3v3_b,en_3v3}; slot7_wrapper instance connects them by name. verilog/gl/sg13cmos5l_ocd_chipalooza.v: wires s7_an_*_esd -> the 13 nets; padframe and harness_core instances connect the 13 nets; `.s7_an_0(s7_an[0])`, `.s7_an_1(s7_an[1])` removed from harness_core (the pads no longer reach the core); chip pins `s7_an[1:0]` stay (padframe .s7_an). verilog/rtl/digital_tb.v: `.s7_an()` -> 13 unconnected ports. verilog/gl/chipalooza_tb.v unchanged (it only uses the chip pins s7_an).
- `apt-get install -y iverilog` (Icarus Verilog 12.0; was not installed). SRAM models (missing in the sparse PDK checkout) taken read-only with `git -C /foss/pdks/IHP-Open-PDK show HEAD:ihp-sg13g2/libs.ref/sg13g2_sram/verilog/<file>` into a scratch include dir.
- cwd verilog/dv: `iverilog -g2012 -gno-specify -I../rtl -I/foss/pdks/ihp-sg13cmos5l -I<scratch sram include> -s chipalooza_frame -o <scratch>/now.vvp dut.v`: exit 0; same with main's chipalooza_frame.v and slot7_wrapper.v: exit 0; the warning lists (206 lines, stdcell timing checks) are identical.
- cwd validate/lvs: `PDK_ROOT=<scratch overlay with the SRAM model> ./gen_blackboxes.py > <scratch>/bb.v` (exit 0) -> validate/lvs/blackboxes.v (slot7_wrapper stub now 29 pins; the SRAM source comment kept as in main). validate/lvs/chipalooza_frame.struct.v NOT regenerated: needs yosys (`make -C validate/lvs netlist`), not installed; it still has the old slot 7 ports.
- NOT changed (graphical, need xschem by hand): xschem/chipalooza_frame.sch, xschem/sg13cmos5l_ocd_chipalooza.sch, xschem/chipalooza_frame.sym, xschem/sg13cmos5l_padframe.sym (still s7_an_*_esd / s7_an[0:1]).
- patch series regenerated: 0001-0003 applied with git am on a worktree of origin/main, the Verilog commit cherry-picked as 0004, `git format-patch origin/main -o docs/custom_pads/patches`; worktree removed.
- chat log sha256 (unchanged since Phase 4): `e3196128aba1b4f586ce810b75f956c321d61b0278fcb571fcc0560e214b15d9`
- 2026-11-05T22:18Z: chat log export done on the user's explicit request (single retry of the step stopped in Phase 0; not blocked this time): visible conversation appended to the chat log (20 user messages, 59 assistant messages, 250 one-line tool entries). Export filter kept outside the repo (scratchpad). chat log sha256: `bd561a0ab673e544239ecf1ba75c528951bf50a710b856faf49896c7f1bd81b0`
- 2026-11-05T23:07Z: docs/custom_pads/tools/shim/magic fixed after a user report from their local container (magic not in /usr/local/bin there: 'line 21: /usr/local/bin/magic: No such file or directory'): the shim now takes the next magic on PATH after its own directory, and passes interactive sessions (stdin is a terminal) and --version straight through. Tested here: batch run with 'locking disable' gives a writeable cell; magic found via another PATH directory; clear error with exit 127 when no other magic is on PATH.

## After the run (user's local check, 2026-11-05/06)
- The user cloned `custom-pad-test` locally (IIC-OSIC-TOOLS container, magic 8.3.685), ran `make setup` (their PDK has the SRAM files, so the SRAM was imported there; the .err log shows only the known foundry annotation messages), viewed the padframe and slot7_wrapper in magic (`-d X11`; `-d XR` failed with an X BadAlloc on CreatePixmap) and the pre-fill GDS from `make gds-prefill` in KLayout.
- Shim bug found there and fixed (see the entry above, commit 23e7b6c).
- Tim's answer (via the user): the pad layouts must come from the slot repository's default branch, which the harness gets as submodule dependencies/slot_7; a fork of the harness is of no use to him. Plan proposed (not yet started): pad deliverables in the slot repo under final/pads/ on main, and setup_custom_io.sh reading them from dependencies/slot_<N>/ with magic/custom_io/ and netlist/schematic/custom_io.spice generated and gitignored. Excerpt for Tim: docs/custom_pads/chatlog/2026-11-06_verbaTim_pad_delivery_via_slot_repo.md.
- 2026-11-06T01:32Z: chat log continued (append) from the same transcript; sha256 `9f0fbcc322b87a640cb43842d50a0bdd0ecd10c972edb1fe8651af762cc55260`; verbaTim excerpt sha256 `e860049039e017616f14956ccd8cae951afa4e7b36edc3b755eb66f61de81726`.

## Survey: what Tim's harness needs from a slot repository (2026-11-06T01:47Z, read-only)
- Harness side (this fork, scripts as on main): scripts/get_project_gds.sh looks for exactly one slot_<N>.gds or slot_<N>.gds.gz with top cell slot_<N>, in <repo>/final/gds/, then <repo>/gds/, then anywhere in the repo (with a note). magic/run_extract_chipalooza_top.sh and the placement Tcl set "property LEFview true" on every slot wrapper and slot_<N>: the slot is a black box at chip level; top LVS compares only its pins (verilog/gl/slot<N>_wrapper_lvs.v). The slot's netlist, schematics and submission.yaml are not read by any harness script.
- The custom pads are different: they are part of the padframe and are extracted at transistor level, so their GDS and an LVS netlist are real inputs. The harness has no convention for receiving pads from a slot repository yet.
- scripts/get_projects.sh clones each slot with a plain `git submodule add` (full clone, all branches and history): dependencies/slot_7 here took 160 MB (.git/modules/dependencies/slot_7). A slimmed main branch in the same repository would not reduce that; a separate delivery repository would.
- Reference slot repos (anonymous read through the session's git proxy, `git clone --depth 1 --filter=blob:none --no-checkout`, tree listing only): Belal-Elshinnawey/sg13cmos5l_slot2_backup (default branch main, c5e430a 2026-11-05; the slot Tim reassigned "to get a valid layout in place"): the Chipalooza template with Makefile TOP = slot_2, final/gds/slot_2.gds, final/lef/slot_2.lef, submission.yaml left at the template defaults. htfab/hsxo-cpz2 (main, cd49e44 2026-08-31): xschem schematics only so far. The other slot repositories were not reachable through this session's API scope and were not checked.
- Recommendation given to the user: a separate delivery repository with only a main branch (slot_7.gds + pad deliverables); alternatively shallow submodules in get_projects.sh (Tim's decision, affects all slots).
- chat log continued; sha256 `2111cc395a74affea0d589ee01260723c7a53f1d4de8b098946de51df7f8ea05`.
- 2026-11-06T01:48Z: task file for the delivery-repository session written: slot repo, branch harness-test, docs/launch/slot7_delivery_repo_TASK.md (commit cf88683); the delivery repository name is a placeholder (DELIVERY_REPO) for the user to fill in.
