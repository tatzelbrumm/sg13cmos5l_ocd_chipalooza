# RUNLOG: slot 7 v2 through Tim's harness flow (fork tatzelbrumm/sg13cmos5l_ocd_chipalooza)

Branch `claude/slot7-v2-harness-test` from fork `main` b3d2e50 (= Tim's main ff68060, tree identical).
Requested via cloud session C4 (brief: tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single, branch claude/c4-replica-bias,
docs/slot7_hookup/HARNESS_TEST_BRIEF.md), confirmed by the user in this session. Fresh clone `/home/user/v2test`
(`git clone --recurse-submodules`). Environment: PDK_ROOT=/foss/pdks PDK=ihp-sg13cmos5l, magic 8.3.685 with the PATH
shim `docs/slot7_v2_test/shim/magic` (locking bug), PDK sparse checkout without the SRAM.

## Journal

- (manual) config.txt: `s7_version: main 454da6a251dbee7d2b2110ce3aac2ef2de998a65` (was `- -`). The other s7 lines (source, pad types) are Tim's already.

### 01 make_setup
- start 2026-11-08T18:53:59Z, end 2026-11-08T18:54:29Z
- cwd: `/home/user/v2test`
- command: `make setup`
- exit status: 0
- logs: `logs/01_make_setup.out`, `logs/01_make_setup.err`

### 02 make_projects_7
- start 2026-11-08T18:54:29Z, end 2026-11-08T18:54:31Z
- cwd: `/home/user/v2test`
- command: `make projects SLOTS=7`
- exit status: 0
- logs: `logs/02_make_projects_7.out`, `logs/02_make_projects_7.err`

### 03 make_setup-custom
- start 2026-11-08T18:54:31Z, end 2026-11-08T18:54:33Z
- cwd: `/home/user/v2test`
- command: `make setup-custom`
- exit status: 0
- logs: `logs/03_make_setup-custom.out`, `logs/03_make_setup-custom.err`
- changed (01-03): magic/sg13cmos5l_io, _stdcell (gitignored); dependencies/slot_7 at 454da6a (.gitmodules, gitlink); magic/custom_io/ with two FLATTENED pad views (Tim's setup_custom.sh: GDS_START 0, GDS_FILE = absolute path into the submodule), FIXED_BBOX 0 0 16000 36000, ports D2S: en_3v3 en_3v3_b iovdd iovss iref pad vdd vinn vinp vref; S2D: en_3v3 en_3v3_b iovdd iovss iref outn outp pad vcm vdd vref. 'Couldn't find label vss' while annotating from the .spice: the known vss issue (vss is the substrate, no vss label).

### 04 make_clean-config
- start 2026-11-08T18:54:49Z, end 2026-11-08T18:54:49Z
- cwd: `/home/user/v2test`
- command: `make clean-config`
- exit status: 0
- logs: `logs/04_make_clean-config.out`, `logs/04_make_clean-config.err`

### 05 make_config
- start 2026-11-08T18:54:49Z, end 2026-11-08T18:54:49Z
- cwd: `/home/user/v2test`
- command: `make config`
- exit status: 0
- logs: `logs/05_make_config.out`, `logs/05_make_config.err`
- changed (04, 05): Tim's unmodified parse_config.py exits 0 but prints "Bad pad type" 8 times for the two custom pads (1 in the wrapper, 3+3 in the padframe Verilog, ... see log 05). Result: verilog/gl/chipalooza_frame_wrapper.v has no s7 core ports; verilog/gl/sg13cmos5l_padframe.v keeps the unsubstituted placeholders `PAD_7_0_SIGNALS` / `PAD_7_1_SIGNALS` (lines 573, 584); scripts/gen_padframe.tcl places the custom pads but has no label lines for them and instead repeats slot 6's last line `label_right_signal pad_s6_an_1  c2p    s6_an_1` twice (lines 632-633: the Tcl branch of parse_config.py has no else, so the previous line is appended again). This is the gap Tim's commit 4da07b6 names ("parse_config.py does not yet handle new pads"). Harness-side fix on this branch only, next entry.
- (manual, harness-side fix on this branch only) from fork branch claude/c6-submodule-pads: scripts/parse_config.py CUSTOM_PADS block (pins from dependencies/slot_<N>/pads/pads.txt, checked against the ports of magic/custom_io/<cell>.mag; 4 places), scripts/custom_io_manifest.py, scripts/custom_io.tcl (label_right_custom / label_left_custom), scripts/run_update_frame_custom_io.sh + Makefile target frame-custom-io, scripts/custom_io_verilog.py; gen_padframe_template.tcl: + `source ../scripts/custom_io.tcl`. NOT taken: setup_custom_io.py / custom_io_uniquify.py (Tim's setup_custom.sh does the import, with flattened views instead of renamed sub-cells). Messages say "make setup-custom". Tim's .gitignore does not list magic/custom_io/ (its .mag hold an absolute GDS_FILE path into the submodule); not committed.

### 06 make_clean-config
- start 2026-11-08T18:55:50Z, end 2026-11-08T18:55:50Z
- cwd: `/home/user/v2test`
- command: `make clean-config`
- exit status: 0
- logs: `logs/06_make_clean-config.out`, `logs/06_make_clean-config.err`

### 07 make_config
- start 2026-11-08T18:55:50Z, end 2026-11-08T18:55:50Z
- cwd: `/home/user/v2test`
- command: `make config`
- exit status: 0
- logs: `logs/07_make_config.out`, `logs/07_make_config.err`

### 08 make_padframe
- start 2026-11-08T18:55:50Z, end 2026-11-08T18:55:58Z
- cwd: `/home/user/v2test`
- command: `make padframe`
- exit status: 0
- logs: `logs/08_make_padframe.out`, `logs/08_make_padframe.err`

### 09 make_frame-custom-io
- start 2026-11-08T18:55:58Z, end 2026-11-08T18:55:59Z
- cwd: `/home/user/v2test`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/09_make_frame-custom-io.out`, `logs/09_make_frame-custom-io.err`

### 10 make_wrappers
- start 2026-11-08T18:55:59Z, end 2026-11-08T18:56:01Z
- cwd: `/home/user/v2test`
- command: `make wrappers`
- exit status: 0
- logs: `logs/10_make_wrappers.out`, `logs/10_make_wrappers.err`

### 11 make_gds-slots
- start 2026-11-08T18:56:01Z, end 2026-11-08T18:56:01Z
- cwd: `/home/user/v2test`
- command: `make gds-slots`
- exit status: 0
- logs: `logs/11_make_gds-slots.out`, `logs/11_make_gds-slots.err`

### 12 make_user-id
- start 2026-11-08T18:56:01Z, end 2026-11-08T18:56:02Z
- cwd: `/home/user/v2test`
- command: `make user-id`
- exit status: 0
- logs: `logs/12_make_user-id.out`, `logs/12_make_user-id.err`

### 13 make_projects-gds_SLOTS=7
- start 2026-11-08T18:56:02Z, end 2026-11-08T18:56:11Z
- cwd: `/home/user/v2test`
- command: `make projects-gds SLOTS=7`
- exit status: 0
- logs: `logs/13_make_projects-gds_SLOTS=7.out`, `logs/13_make_projects-gds_SLOTS=7.err`

### 14 make_gds-prefill
- start 2026-11-08T18:56:11Z, end 2026-11-08T18:59:41Z
- cwd: `/home/user/v2test`
- command: `make gds-prefill`
- exit status: 0
- logs: `logs/14_make_gds-prefill.out`, `logs/14_make_gds-prefill.err`
- changed (06-14): all exit 0; 0 "Bad pad type". Regenerated: scripts/gen_padframe.tcl (13 label_right_custom lines for slot 7), verilog/gl/{sg13cmos5l_padframe,chipalooza_frame_wrapper}.v, magic/{sg13cmos5l_padframe,chipalooza_frame_wrapper,padframe_pins}.mag, magic/chipalooza_frame.mag (stale s7 analog copies erased), magic/slot*_wrapper.mag, gds/slot*_wrapper.gds, user-id files, scripts/user_projects.tcl, gds/sg13cmos5l_ocd_chipalooza.gds.gz (gitignored).
- 15: netcheck with the stand-in expectations (outp->vinp tie): "RESULT FAILURES" -- expected, slot 7 v2 is a real circuit with other ties.
- 16: `python3 docs/slot7_v2_test/netcheck_slot7.py gds/sg13cmos5l_ocd_chipalooza.gds.gz sg13cmos5l_ocd_chipalooza 1901.1 2271.1 2096.1 2471.1 --merged s7_an_0_vcm,s7_an_1_vref --merged s7_an_0_en_3v3,s7_an_1_en_3v3 --merged s7_an_0_en_3v3_b,s7_an_1_en_3v3_b` -> RESULT all 13 pins OK. Tie groups from the slot's own docs/FOR_TIM.md (one vcm for S2D vcm and D2S vref; one enable pair for both pads; S2D->D2S through switches, so outp/vinp are separate metal nets). netcheck_slot7.py got a --merged option for this (copy in docs/slot7_v2_test/).
