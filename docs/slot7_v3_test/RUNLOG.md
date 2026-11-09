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

### 14 drc_slot7_area
- start 2026-11-09T00:02:55Z, end 2026-11-09T00:04:39Z
- cwd: `/home/user/v2test`
- command: `python3 /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/run_drc.py --path=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v3drc/s7_clip.gds --topcell=s7_clip --run_dir=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v3drc/run --antenna --mp=4`
- exit status: 1
- logs: `logs/14_drc_slot7_area.out`, `logs/14_drc_slot7_area.err`
- 14: DRC of the slot-7 area (same clip and run_drc.py options as v2 entry 17; exit 1 = violations present, as in v2): identical to v2: 2912 items in all, antenna 0, entirely >= 2 um inside the clip the same 69 recommended Pad.* items (Pad.fR_M2 45, Pad.fR_M3 7, Pad.fR_M4 7, Pad.d1R 7, Pad.fR_TM1 3); density: the same pre-fill markers (AFil.g, GFil.g, M1-M4.j, TM1.c). The tughra art adds no DRC item.

### 15 make_fill
- start 2026-11-09T00:05:15Z, end 2026-11-09T00:07:48Z
- cwd: `/home/user/v2test`
- command: `make fill`
- exit status: 0
- logs: `logs/15_make_fill.out`, `logs/15_make_fill.err`

### 16 make_gds-final
- start 2026-11-09T00:07:48Z, end 2026-11-09T00:09:59Z
- cwd: `/home/user/v2test`
- command: `make gds-final`
- exit status: 0
- logs: `logs/16_make_gds-final.out`, `logs/16_make_gds-final.err`

### 17 make_extract-top
- start 2026-11-09T00:09:59Z, end 2026-11-09T00:18:27Z
- cwd: `/home/user/v2test`
- command: `make extract-top`
- exit status: 0
- logs: `logs/17_make_extract-top.out`, `logs/17_make_extract-top.err`

### 18 make_lvs-top
- start 2026-11-09T00:18:27Z, end 2026-11-09T00:18:53Z
- cwd: `/home/user/v2test`
- command: `make lvs-top`
- exit status: 0
- logs: `logs/18_make_lvs-top.out`, `logs/18_make_lvs-top.err`

### 19 drc_density_slot7_final
- start 2026-11-09T00:19:30Z, end 2026-11-09T00:19:36Z
- cwd: `/home/user/v2test`
- command: `python3 /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/run_drc.py --path=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v3dens/s7_final.gds --topcell=s7_final_clip --run_dir=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v3dens/run --density_only --mp=4`
- exit status: 1
- logs: `logs/19_drc_density_slot7_final.out`, `logs/19_drc_density_slot7_final.err`

### 20 drc_density_chip_final
- start 2026-11-09T00:19:58Z, end 2026-11-09T00:21:28Z
- cwd: `/home/user/v2test`
- command: `python3 /foss/pdks/ihp-sg13cmos5l/libs.tech/klayout/tech/drc/run_drc.py --path=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v3dens/final.gds --topcell=sg13cmos5l_ocd_chipalooza_final --run_dir=/tmp/claude-0/-home-user/51975cfd-7f52-5f9c-9274-64e0aeb00894/scratchpad/v3dens/runchip --density_only --mp=4`
- exit status: 1
- logs: `logs/20_drc_density_chip_final.out`, `logs/20_drc_density_chip_final.err`
- 15-18 (PDK_ROOT = SRAM overlay): `make fill` (2.5 min), `make gds-final` (2 min), `make extract-top` (8.5 min, magic: "2175 errors" during extraction), `make lvs-top` (0.5 min): all exit 0. Whole run 14 min, 4 CPUs.
- Fill vs the tughra art: in the final GDS (slot_7 at 1379.95, 2170.05) the art box x 1465.45..1623.55, y 2311.05..2401.05 um holds 0 filler shapes on ActivFiller, GatPolyFiller, M1-M4 Filler, TM1 Filler (layers n/22), while the rest of slot 7 has 575..6712 per layer: the no-fill markers on datatype 23 work in Tim's magic fill.
- 19: density-only DRC of the filled slot-7 window (clip x 1379.95..1917.1, y 2170.05..2443.05): only AFil.g (Activ 31.9 % < 35 %, short by 4536 um2; the art box is ~14200 um2 without fill); GatPoly 22.8 %, M1 44.0 %, M2 44.8 %, M3 45.3 %, M4 45.7 %, TM1 41.2 %: pass. AFil.g is a chip-global rule; the slot window is only indicative.
- 20: density-only DRC of the whole filled chip: the deck takes the area of EdgeSeal.boundary (39/4) as the chip area (558205 um2, the ring itself), so its global percentages are invalid (Activ "578 %"); its six markers (AFil.g1, M1-M4.k, TM1.d, max-density) come from that. Recomputed with the chip extent 2257.8 x 3357.8 um (7.58 mm2) and the deck's own layer areas (M3, M4 checked merged): Activ 42.6 % [35-55], GatPoly 19.0 % [>=15], M1 52.6 %, M2 46.9 %, M3 57.2 % [35-60], M4 60.2 % [35-60] OVER by 0.2 %, TM1 59.0 % [25-70]. M4 is a chip-level fill finding for Tim; slot 7's own M4 density (45.7 %) is below the chip's.
- 18 lvs-top: "Final result: Netlists do not match". slot7_wrapper matches (pins), both custom pads match ("7 symmetries with property errors", as in lvs-padframe). Mismatching cells are not slot 7's: foundry pads and clamps (IOPadAnalog, IOPadIn, IOPadInOut16mA, IOPadOut16mA, IOPadTriOut16mA, IOPadVss, IOPadIOVss, Clamp_*), harness IPs (bandgap_v3, classab_buffer, por, bg_res, se_folded_cascode_np_ab), sg13cmos5l_padframe, chipalooza_frame, top. In the frame/top sections the schematic side still has the old slot-7 pins (slot7_wrapper/s7_an[1], s7_an_0_esd, ...): the harness xschem sheets are not updated for the custom pads (expected, see v2 RUNLOG).
- Findings for Tim (none in slot 7): (a) scripts/run_gen_prefill_gds.sh ends with "Done!" / exit 0 even when magic writes a truncated GDS (missing SRAM GDS, entry 11); (b) the KLayout density deck uses the seal-ring boundary's own area as the chip area; (c) chip M4 density 60.2 % after fill; (d) the xschem sheets for slot 7's custom pads.
- Report sent to the slot7 hand-over session (session_01XU3KH77upRZxPAr9FvWL5j) at the user's request: items 1-8 and the harness findings above. Delivered.

## Rerun on Tim's main 0748622 (2026-11-09, user: "now update and rerun the test branches")

The runs above used Tim's main ff68060; Tim has since pushed 97ef521 (frame corrections for DRC with IHP's KLayout script, dependency updates biasgen/POR/analog switches, `make drc-precheck`) and 0748622 (slot 3 = htfab/hsxo-cpz2). (Found late: the `tim` remote's fetch here fails, `git ls-remote` over https works; the RUNLOG entries above compared against a stale ff68060.) Merged Tim's 0748622 into this branch (2834f03; conflict only in magic/chipalooza_frame.mag, Tim's version taken, the slot-7 labels come back with `make frame-custom-io`); patches 0001-0004 regenerated on 0748622 (apply cleanly); the three harness IP submodules updated to Tim's commits. Same clone and branch; PDK_ROOT = SRAM overlay for every step; logs logs/rNN_*.

### r01 make_setup
- start 2026-11-09T01:14:32Z, end 2026-11-09T01:14:58Z
- cwd: `/home/user/v2test`
- command: `make setup`
- exit status: 0
- logs: `logs/r01_make_setup.out`, `logs/r01_make_setup.err`

### r02 make_projects-update_SLOTS=7
- start 2026-11-09T01:14:58Z, end 2026-11-09T01:14:58Z
- cwd: `/home/user/v2test`
- command: `make projects-update SLOTS=7`
- exit status: 0
- logs: `logs/r02_make_projects-update_SLOTS=7.out`, `logs/r02_make_projects-update_SLOTS=7.err`

### r03 make_setup-custom
- start 2026-11-09T01:14:58Z, end 2026-11-09T01:15:00Z
- cwd: `/home/user/v2test`
- command: `make setup-custom`
- exit status: 0
- logs: `logs/r03_make_setup-custom.out`, `logs/r03_make_setup-custom.err`

### r04 make_clean-config
- start 2026-11-09T01:15:00Z, end 2026-11-09T01:15:00Z
- cwd: `/home/user/v2test`
- command: `make clean-config`
- exit status: 0
- logs: `logs/r04_make_clean-config.out`, `logs/r04_make_clean-config.err`

### r05 make_config
- start 2026-11-09T01:15:00Z, end 2026-11-09T01:15:00Z
- cwd: `/home/user/v2test`
- command: `make config`
- exit status: 0
- logs: `logs/r05_make_config.out`, `logs/r05_make_config.err`

### r06 make_padframe
- start 2026-11-09T01:15:00Z, end 2026-11-09T01:15:08Z
- cwd: `/home/user/v2test`
- command: `make padframe`
- exit status: 0
- logs: `logs/r06_make_padframe.out`, `logs/r06_make_padframe.err`

### r07 make_frame-custom-io
- start 2026-11-09T01:15:08Z, end 2026-11-09T01:15:09Z
- cwd: `/home/user/v2test`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/r07_make_frame-custom-io.out`, `logs/r07_make_frame-custom-io.err`

### r08 make_wrappers
- start 2026-11-09T01:15:09Z, end 2026-11-09T01:15:11Z
- cwd: `/home/user/v2test`
- command: `make wrappers`
- exit status: 0
- logs: `logs/r08_make_wrappers.out`, `logs/r08_make_wrappers.err`

### r09 make_gds-slots
- start 2026-11-09T01:15:11Z, end 2026-11-09T01:15:11Z
- cwd: `/home/user/v2test`
- command: `make gds-slots`
- exit status: 0
- logs: `logs/r09_make_gds-slots.out`, `logs/r09_make_gds-slots.err`

### r10 make_user-id
- start 2026-11-09T01:15:11Z, end 2026-11-09T01:15:12Z
- cwd: `/home/user/v2test`
- command: `make user-id`
- exit status: 0
- logs: `logs/r10_make_user-id.out`, `logs/r10_make_user-id.err`

### r11 make_projects-gds_SLOTS=7
- start 2026-11-09T01:15:12Z, end 2026-11-09T01:15:21Z
- cwd: `/home/user/v2test`
- command: `make projects-gds SLOTS=7`
- exit status: 0
- logs: `logs/r11_make_projects-gds_SLOTS=7.out`, `logs/r11_make_projects-gds_SLOTS=7.err`

### r12 make_gds-prefill
- start 2026-11-09T01:15:21Z, end 2026-11-09T01:19:06Z
- cwd: `/home/user/v2test`
- command: `make gds-prefill`
- exit status: 0
- logs: `logs/r12_make_gds-prefill.out`, `logs/r12_make_gds-prefill.err`

### r13 netcheck
- start 2026-11-09T01:19:06Z, end 2026-11-09T01:19:07Z
- cwd: `/home/user/v2test`
- command: `python3 docs/slot7_v2_test/netcheck_slot7.py gds/sg13cmos5l_ocd_chipalooza.gds.gz sg13cmos5l_ocd_chipalooza 1901.1 2271.1 2096.1 2471.1 --merged s7_an_0_vcm,s7_an_1_vref --merged s7_an_0_en_3v3,s7_an_1_en_3v3 --merged s7_an_0_en_3v3_b,s7_an_1_en_3v3_b`
- exit status: 0
- logs: `logs/r13_netcheck.out`, `logs/r13_netcheck.err`

### r14 make_fill
- start 2026-11-09T01:19:07Z, end 2026-11-09T01:21:36Z
- cwd: `/home/user/v2test`
- command: `make fill`
- exit status: 0
- logs: `logs/r14_make_fill.out`, `logs/r14_make_fill.err`

### r15 make_gds-final
- start 2026-11-09T01:21:36Z, end 2026-11-09T01:23:47Z
- cwd: `/home/user/v2test`
- command: `make gds-final`
- exit status: 0
- logs: `logs/r15_make_gds-final.out`, `logs/r15_make_gds-final.err`

### r16 make_drc-precheck
- start 2026-11-09T01:23:47Z, end 2026-11-09T01:30:28Z
- cwd: `/home/user/v2test`
- command: `make drc-precheck`
- exit status: 0
- logs: `logs/r16_make_drc-precheck.out`, `logs/r16_make_drc-precheck.err`

### r17 make_extract-top
- start 2026-11-09T01:30:28Z, end 2026-11-09T01:39:02Z
- cwd: `/home/user/v2test`
- command: `make extract-top`
- exit status: 0
- logs: `logs/r17_make_extract-top.out`, `logs/r17_make_extract-top.err`

### r18 make_lvs-top
- start 2026-11-09T01:39:02Z, end 2026-11-09T01:39:27Z
- cwd: `/home/user/v2test`
- command: `make lvs-top`
- exit status: 0
- logs: `logs/r18_make_lvs-top.out`, `logs/r18_make_lvs-top.err`
- Rerun result (r01-r18, all exit 0, 01:14-01:39Z, 25 min): `make config` without "Bad pad type"; pre-fill GDS complete (top sg13cmos5l_ocd_chipalooza, 695 cells; the two prefixed `$$$CONTEXT_INFO$$$` top cells from the pad GDS as before); netcheck all 13 OK; fill: 0 filler shapes in the art box; chip density after fill (merged, chip extent 2257.8 x 3357.8 um): Activ 42.6 %, GatPoly 19.0 %, M1 52.6 %, M2 46.9 %, M3 57.2 %, M4 60.2 % (max 60), TM1 58.9 % -- unchanged by Tim's frame update; lvs-top: same mismatching cells as on ff68060 (foundry pads/clamps, harness IPs, padframe, frame, top), both custom pads match, slot-7 top pins from the stale xschem sheets.
- r16 `make drc-precheck` (Tim's new target, IHP pre-check deck on the final GDS, 7 min): 16840622 items in 8 rules: Seal.l 16840614 ("No structures outside sealring boundary allowed"), TGO.f 2 (not in slot 7), and the six chip-wide max-density markers (AFil.g1, M1-M4.k, TM1.d). Cause of Seal.l and the density markers: the seal ring's EdgeSeal.boundary (39/4) is drawn as 16 rectangles along the ring (558205 um2), not as one filled chip outline, so the deck treats everything inside the ring as outside the boundary and the ring area as the chip area. A harness seal-ring issue, independent of slot 7 (329k of the Seal.l items lie in slot 7 + pads simply because every shape there is "outside"). Slot-7 area DRC (step 14) and slot LVS (step 13) were not rerun: slot 7, its pads and wrapper are unchanged; Tim's update changed only the frame and shared IPs outside it.
- Findings for Tim, updated: (a) run_gen_prefill_gds.sh "Done!"/exit 0 on a truncated GDS; (b) EdgeSeal.boundary 39/4 as ring strips: breaks the IHP pre-check (Seal.l everywhere) and the density deck's chip area; (c) chip M4 density 60.2 % after fill; (d) xschem sheets for slot 7's custom pads; (e) TGO.f 2 items (location in validate/drc_run_2026_11_09_01_23_47, not in slot 7).
