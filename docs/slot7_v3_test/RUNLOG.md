# Slot 7 v3 harness test (2026-11-08/09)

Request: the slot7 hand-over session (session_01XU3KH77upRZxPAr9FvWL5j), confirmed by the user: "yes, go ahead with 1-2 and the
slot-7 DRC", then make the new main available to Tim if it does not break his flow, then full-chip fill and top LVS.
Fork `tatzelbrumm/sg13cmos5l_ocd_chipalooza`, branch `claude/slot7-v3-harness-test`, from `claude/slot7-v2-harness-test`
04065d7 (Tim ff68060 + patches 0001-0004 + regenerated views + Verilog edits). Clone `/home/user/v2test`.
Only change in the harness input: `config.txt` `s7_version: main 158afc5afab0056bd6d216a4db3833e34a364949`
(sg13cmos5l_cm_slot7 main = slot 7 v3 + tughra art). Note: Tim's own `config.txt` has `s7_version: - -`, i.e. his
`make projects` takes whatever slot7 `main` is: v3 is live for Tim since 158afc5 was pushed.
Logged with `docs/slot7_v3_test/run.sh` (stdout/stderr teed to `logs/NN_name.{out,err}`).

## Journal
- 01 (first try) `make projects-update` without SLOTS started cloning every slot of config.txt (slots 1-14 cloned, 1.2 GB, slot 9 alone 828 MB) before I stopped it (not asked for: the user asked only about the cost of an all-slots test). Clones removed (dependencies/slot_N, .git/modules, .gitmodules restored); slot 7 was already on 158afc5. Rerun as `make projects-update SLOTS=7`.

### 01 make_projects-update_SLOTS=7
- start 2026-11-08T23:55:52Z, end 2026-11-08T23:55:53Z
- cwd: `/home/user/v2test`
- command: `make projects-update SLOTS=7`
- exit status: 0
- logs: `logs/01_make_projects-update_SLOTS=7.out`, `logs/01_make_projects-update_SLOTS=7.err`

### 02 make_setup-custom
- start 2026-11-08T23:55:53Z, end 2026-11-08T23:55:56Z
- cwd: `/home/user/v2test`
- command: `make setup-custom`
- exit status: 0
- logs: `logs/02_make_setup-custom.out`, `logs/02_make_setup-custom.err`

### 03 make_clean-config
- start 2026-11-08T23:55:56Z, end 2026-11-08T23:55:56Z
- cwd: `/home/user/v2test`
- command: `make clean-config`
- exit status: 0
- logs: `logs/03_make_clean-config.out`, `logs/03_make_clean-config.err`

### 04 make_config
- start 2026-11-08T23:55:56Z, end 2026-11-08T23:55:56Z
- cwd: `/home/user/v2test`
- command: `make config`
- exit status: 0
- logs: `logs/04_make_config.out`, `logs/04_make_config.err`

### 05 make_padframe
- start 2026-11-08T23:55:56Z, end 2026-11-08T23:56:05Z
- cwd: `/home/user/v2test`
- command: `make padframe`
- exit status: 0
- logs: `logs/05_make_padframe.out`, `logs/05_make_padframe.err`

### 06 make_frame-custom-io
- start 2026-11-08T23:56:05Z, end 2026-11-08T23:56:06Z
- cwd: `/home/user/v2test`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/06_make_frame-custom-io.out`, `logs/06_make_frame-custom-io.err`

### 07 make_wrappers
- start 2026-11-08T23:56:06Z, end 2026-11-08T23:56:09Z
- cwd: `/home/user/v2test`
- command: `make wrappers`
- exit status: 0
- logs: `logs/07_make_wrappers.out`, `logs/07_make_wrappers.err`

### 08 make_gds-slots
- start 2026-11-08T23:56:09Z, end 2026-11-08T23:56:09Z
- cwd: `/home/user/v2test`
- command: `make gds-slots`
- exit status: 0
- logs: `logs/08_make_gds-slots.out`, `logs/08_make_gds-slots.err`

### 09 make_user-id
- start 2026-11-08T23:56:09Z, end 2026-11-08T23:56:10Z
- cwd: `/home/user/v2test`
- command: `make user-id`
- exit status: 0
- logs: `logs/09_make_user-id.out`, `logs/09_make_user-id.err`

### 10 make_projects-gds_SLOTS=7
- start 2026-11-08T23:56:10Z, end 2026-11-08T23:56:19Z
- cwd: `/home/user/v2test`
- command: `make projects-gds SLOTS=7`
- exit status: 0
- logs: `logs/10_make_projects-gds_SLOTS=7.out`, `logs/10_make_projects-gds_SLOTS=7.err`

### 11 make_gds-prefill
- start 2026-11-08T23:56:19Z, end 2026-11-08T23:56:43Z
- cwd: `/home/user/v2test`
- command: `make gds-prefill`
- exit status: 0
- logs: `logs/11_make_gds-prefill.out`, `logs/11_make_gds-prefill.err`

### 12 netcheck
- start 2026-11-08T23:56:43Z, end 2026-11-08T23:56:43Z
- cwd: `/home/user/v2test`
- command: `python3 docs/slot7_v2_test/netcheck_slot7.py gds/sg13cmos5l_ocd_chipalooza.gds.gz sg13cmos5l_ocd_chipalooza 1901.1 2271.1 2096.1 2471.1 --merged s7_an_0_vcm,s7_an_1_vref --merged s7_an_0_en_3v3,s7_an_1_en_3v3 --merged s7_an_0_en_3v3_b,s7_an_1_en_3v3_b`
- exit status: 1
- logs: `logs/12_netcheck.out`, `logs/12_netcheck.err`

### 11b make_gds-prefill_sram_overlay
- start 2026-11-08T23:58:20Z, end 2026-11-09T00:02:05Z
- cwd: `/home/user/v2test`
- command: `make gds-prefill`
- exit status: 0
- logs: `logs/11b_make_gds-prefill_sram_overlay.out`, `logs/11b_make_gds-prefill_sram_overlay.err`

### 12b netcheck
- start 2026-11-09T00:02:21Z, end 2026-11-09T00:02:22Z
- cwd: `/home/user/v2test`
- command: `python3 docs/slot7_v2_test/netcheck_slot7.py gds/sg13cmos5l_ocd_chipalooza.gds.gz sg13cmos5l_ocd_chipalooza 1901.1 2271.1 2096.1 2471.1 --merged s7_an_0_vcm,s7_an_1_vref --merged s7_an_0_en_3v3,s7_an_1_en_3v3 --merged s7_an_0_en_3v3_b,s7_an_1_en_3v3_b`
- exit status: 0
- logs: `logs/12b_netcheck.out`, `logs/12b_netcheck.err`

### 13 lvs_slot7
- start 2026-11-09T00:02:22Z, end 2026-11-09T00:02:24Z
- cwd: `/home/user/v2test`
- command: `bash docs/slot7_v3_test/lvs_slot7.sh`
- exit status: 0
- logs: `logs/13_lvs_slot7.out`, `logs/13_lvs_slot7.err`
- 01-10: exit 0; `make config` without "Bad pad type"; pads, pins, padframe and wrappers unchanged from v2 (the slot repo diff 454da6a..158afc5 touches only final/gds/slot_7.gds, art/, netlist/ additions and docs).
- 11 (`make gds-prefill` with PDK_ROOT=/foss/pdks): exit 0 but a BROKEN GDS (9.6 MB, 336 cells, no top cell sg13cmos5l_ocd_chipalooza, many top cells). Cause (rerun with magic's exit status and stderr captured): `Calma output error: Can't find GDS file "$PDKPATH/libs.ref/sg13cmos5l_sram/gds/RM_IHPSG13_1P_1024x8_c2_bm_bist.gds"` then `I/O error in writing compressed file ... may be incompletely written`; magic exits 0 and run_gen_prefill_gds.sh ends with `exit 0` regardless. This container's PDK lacks the SRAM GDS (the v2 run used the SRAM overlay PDK_ROOT, entry 19 of the v2 RUNLOG). Not a slot-7 problem. Finding for Tim: run_gen_prefill_gds.sh reports "Done!" on a truncated GDS.
- 11b: `make gds-prefill` with PDK_ROOT = the SRAM overlay: 14.5 MB, 695 cells, top sg13cmos5l_ocd_chipalooza (plus two prefixed `$$$CONTEXT_INFO$$$` top cells, which come from the two custom pad GDS files, unchanged since v2; slot_7.gds v3 has none).
- 12b: netcheck: RESULT all 13 pins OK (same --merged groups as v2).
- 13: slot LVS (docs/slot7_v3_test/lvs_slot7.sh: magic extraction, netgen against the slot's netlist/slot_7_netgen.spice, no rename needed): bg_core_pd, pad_ref_rb, s7_ctrl, s7_doutpd, bias_dist_pd "Netlists match uniquely"; slot_7 "match uniquely with port errors", naming only (comma-joined ports `analog_bus3,s7_an_0_vref` and `s7_an_0_en_3v3,s7_an_1_en_3v3` vs one layout label). Final result "Top level cell failed pin matching" for that reason. No "instanced inside of itself".
- Images for sharing (user request): docs/slot7_v3_test/images/slot7_v3_pads.{png,svg} from docs/slot7_v3_test/render_slot7.py (region x 1375..2100, y 2165..2475 um of the pre-fill GDS, PDK layer colours; the first PNG showed every layer of the file because show_layout adds them, fixed with clear_layers).
