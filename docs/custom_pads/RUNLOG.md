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
