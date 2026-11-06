# Dry run of TIM_STEPS.md by the assistant (2026-11-06T14:15Z)

Fresh clone of branch `claude/c6-submodule-pads` (commit eda4ece) with `--recurse-submodules` into /home/user/c6test,
cloud environment (magic 8.3.685 with the shim, PDK without SRAM). Steps 2 to 7 of TIM_STEPS.md, except:
- step 0: slot 7 taken from `sg13cmos5l_cm_slot7` branch `claude/c6-pads-layout` e9a747911c6d331d45f99384c406d51c4ec19e42
  (not yet merged into `main`), so `s7_version: claude/c6-pads-layout e9a7479…` in config.txt;
- step 5 (Verilog by hand) not applied; its instructions were generated (logs/03) and every FIND block was checked to
  occur in the files (once; twice for the "BOTH instances" block). The Verilog does not enter the GDS build;
- nothing committed (config.txt edit left uncommitted).

| log | step | result |
|---|---|---|
| 01_setup | make setup | exit 0 (SRAM files absent in this PDK checkout, known) |
| 02_custom-io | make custom-io | exit 0; 2 pads imported from dependencies/slot_7/pads, 106 cells, FIXED_BBOX 0 0 16000 36000, custom_io.spice with 12 subcircuits |
| 03_verilog_hints | scripts/custom_io_verilog.py | 13 core nets; find/replace blocks for 4 files |
| 04-11 | clean-config, config, padframe, frame-custom-io, wrappers, gds-slots, projects-gds SLOTS=7, gds-prefill | all exit 0 |
| 12_netcheck | docs/custom_io/tools/netcheck_slot7.py on the pre-fill GDS | RESULT all 13 pins OK |

Slot 7 submodule git dir: 824 KB. Not done: make lvs-top, DRC, the other 17 slots (not fetched).
