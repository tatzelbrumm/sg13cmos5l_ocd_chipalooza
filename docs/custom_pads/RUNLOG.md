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
