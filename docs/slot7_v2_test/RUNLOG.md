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
- 17 (cwd harness): KLayout clip of the pre-fill GDS x 1375..2100, y 2165..2475 um (slot 7 + both pads + 5 um margin) to the scratchpad, then the PDK run_drc.py with --antenna (density on, the default).

### 17 drc_s7_antenna_density
- start 2026-11-08T19:01:06Z, end 2026-11-08T19:03:11Z
- cwd: `/home/user/v2test`
- command: `python3 /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/run_drc.py --path=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v2drc/s7_clip.gds --topcell=s7_clip --run_dir=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v2drc/run --antenna --mp=4`
- exit status: 1
- logs: `logs/17_drc_s7_antenna_density.out`, `logs/17_drc_s7_antenna_density.err`
- 17/18: DRC of the slot-7 area (clip x 1375..2100, y 2165..2475 um of the pre-fill GDS, PDK run_drc.py --antenna, density on, --mp=4, 113 s): 2912 items in all; antenna: 0 (all Ant.* rules ran); density: AFil.g, GFil.g, M1.j, M2.j, M3.j, M4.j, TM1.c one marker each over the whole clip -- expected before fill (make fill not run; the slot repo's own DRC used --no_density); entirely >= 2 um inside the clip: 69 items, all recommended Pad.* rules at the bond pads (Pad.fR_M2 45, Pad.fR_M3 7, Pad.fR_M4 7, Pad.d1R 7, Pad.fR_TM1 3); everything else lies on the clip edge (cut shapes). Summary: logs/18_drc_summary.out.
- (manual) top-level LVS preparation: (a) SRAM views for this PDK checkout (sparse checkout lacks them): scratch overlay PDK_ROOT with libs.ref/sg13cmos5l_sram/{gds,lef,cdl,verilog} taken read-only by `git -C /foss/pdks/IHP-Open-PDK show HEAD:ihp-sg13g2/libs.ref/sg13g2_sram/...` (the cmos5l directory is a symlink to it upstream), everything else symlinked to /foss/pdks/ihp-sg13cmos5l; (b) chip-core Verilog: the edits printed by scripts/custom_io_verilog.py applied (TIM_STEPS step 5; done here by script on the test branch, a human does them by hand).

### 19 make_setup_with_sram
- start 2026-11-08T19:04:16Z, end 2026-11-08T19:04:44Z
- cwd: `/home/user/v2test`
- command: `make setup`
- exit status: 0
- logs: `logs/19_make_setup_with_sram.out`, `logs/19_make_setup_with_sram.err`

### 23 lvs_slot7
- start 2026-11-08T19:05:34Z, end 2026-11-08T19:05:36Z
- cwd: `/home/user/v2test`
- command: `docs/slot7_v2_test/lvs_slot7.sh`
- exit status: 0
- logs: `logs/23_lvs_slot7.out`, `logs/23_lvs_slot7.err`
- 23: first try of docs/slot7_v2_test/lvs_slot7.sh: magic extraction ok (port shorts reported = the slot's intended ties: analog_bus2=s7_an_0_vcm=s7_an_1_vref, analog_bus3=s7_an_0_vref, both en_3v3 and both en_3v3_b); netgen stopped ('wrong # args ... readnet', my Tcl handle use). Script changed to netgen -batch lvs with file names; re-run as 24.

### 24 lvs_slot7
- start 2026-11-08T19:06:11Z, end 2026-11-08T19:06:13Z
- cwd: `/home/user/v2test`
- command: `docs/slot7_v2_test/lvs_slot7.sh`
- exit status: 0
- logs: `logs/24_lvs_slot7.out`, `logs/24_lvs_slot7.err`
- 19: `make setup` with PDK_ROOT = the SRAM overlay: SRAM imported (magic/sg13cmos5l_sram/RM_IHPSG13_1P_1024x8_c2_bm_bist.mag).
- 20: scripts/custom_io_verilog.py output (logs/20_verilog_edits.txt) applied to verilog/rtl/chipalooza_frame.v, verilog/gl/sg13cmos5l_ocd_chipalooza.v, verilog/rtl/digital_tb.v, verilog/rtl/slot7_wrapper.v (every FIND block replaced the expected number of times).
- make lvs-top NOT run: validate/run_lvs_ocd_chipalooza.sh reads the xschem top netlist netlist/schematic/sg13cmos5l_ocd_chipalooza.spice last, and the xschem sheets still carry the old slot-7 pins (not script-generated; hand edits in xschem needed first), so slot 7 would mismatch by construction; it is also the heaviest run (full-chip extraction).
- validate/run_lvs_padframe.sh, validate/run_lvs_ocd_chipalooza.sh: + readnet of dependencies/slot_*/pads/*/*.spice (Tim's LVS scripts do not read custom pad netlists yet). Padframe extraction + LVS (21, 22) running.
- 24: LVS of slot 7 with magic + netgen (docs/slot7_v2_test/lvs_slot7.sh): extraction ok; netgen: "Fatal: Class "pnpMPA" is instanced inside of itself!" -- slot_7.gds has a layout cell named pnpMPA, the same name as the PNP device, so magic writes .subckt pnpMPA containing device pnpMPA. A problem in the slot for Tim's magic/netgen flow (the slot's own KLayout LVS passes). Also: slot_7.gds contains KLayout's $$$CONTEXT_INFO$$$ cell (extra top cell; magic: "Unknown layer/datatype in boundary, layer=0 type=0"). Stopped here and asked the user (brief: ask before working around a failure in the slot).

### 21 make_extract-padframe
- start 2026-11-08T19:05:19Z, end 2026-11-08T19:10:19Z
- cwd: `/home/user/v2test`
- command: `make extract-padframe`
- exit status: 0
- logs: `logs/21_make_extract-padframe.out`, `logs/21_make_extract-padframe.err`

### 22 make_lvs-padframe
- start 2026-11-08T19:10:19Z, end 2026-11-08T19:10:20Z
- cwd: `/home/user/v2test`
- command: `make lvs-padframe`
- exit status: 0
- logs: `logs/22_make_lvs-padframe.out`, `logs/22_make_lvs-padframe.err`
- 21/22: padframe extraction + LVS with Tim's flatten-view pads (setup_custom.sh) and the pads' netlists from the submodule: both custom pads match (S2D 76 devices / 37 nets, D2S 76 / 36, 'Netlists match with 7 symmetries with property errors', mm_ok only); all 15 slot-7 top pins match (s7_an[0..1] + 13 core nets); top 'Final result: Top level cell failed pin matching' with devices 500/499, nets 308/305: the same pre-existing mismatches outside slot 7 as on main (Split200 cells, supply-pad clamp nets).
- .gitignore: + magic/custom_io/ (generated by Tim's setup_custom.sh, absolute paths; not listed in Tim's .gitignore). lvs_slot7.sh now extracts into magic/extfiles (already ignored) instead of magic/extfiles_slot7.
