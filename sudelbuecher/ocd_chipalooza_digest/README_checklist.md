# SG13CMOS5L OCD Chipalooza README checklist

Source: read-only review of [`sg13cmos5l_ocd_chipalooza/README`](../../sg13cmos5l_ocd_chipalooza/README), with filenames checked against that repository on 2026-09-23. All paths below are relative to the source repository. An unchecked box describes work in the source README; it does **not** mean the work has not already been done. The README says its instructions are incomplete and still use individual scripts rather than a Makefile.

## What is being assembled

- [ ] Plan the three levels: the 80-pad padframe, `chipalooza_frame_wrapper` with shared housekeeping, biases and power switches, and up to 18 analog or mixed-signal project slots. Each slot has 3.3 V and 1.2 V switched supplies plus control, status, bias and shared analog connections. The README says slots 1–16 have configurable dedicated pads; check the note below about the current configuration.
- [ ] Clone or fork the source repository and use a branch for each test chip. Initialize the example's dependent IP with `git submodule update --init --recursive`; the checked-in submodules are `dependencies/sg13cmos5l_ocd_ip__analog_switches/` and `dependencies/sg13cmos5l_ocd_ip__biasgen/` (see `.gitmodules`). Add other IP as submodules when needed.

## Configure and create the frame

- [ ] Set `PDK_ROOT` to the directory containing `ihp-sg13cmos5l/`.
- [ ] Run `scripts/setup.sh` to import PDK standard-cell and I/O Magic views into `magic/sg13cmos5l_stdcell/` and `magic/sg13cmos5l_io/`. Both directories currently exist.
- [ ] Edit `config.txt`: choose an eight-hex-digit `project_id` (the README recommends reserving the low four bits for revisions) and select foundry pad types for the dedicated signal pads. Keep pad entries in physical counter-clockwise order, use unindexed core signal names, and preserve a wirebond pad in every selected position. Power, SPI and shared-resource pad locations are fixed. The checked-in format is `sN_an[x]: <pad_type> <core_signal_name>`; for example, `s1_an[0]: sg13cmos5l_IOPadAnalog s1_an_0`.
- [ ] Check signal naming when choosing pad types: input/output pads have one core signal; tri-state pads add an enable (and some variants add constant zero/one); bidirectional pads use `_in`, `_out`, `_ena`, `_zero`, `_one`; analog pads connect the pad directly and expose an `_esd` signal. `config.txt` lists the actual pad cell names.
- [ ] Run `scripts/parse_config.py` after protecting any existing generated work. Its current outputs are `verilog/gl/sg13cmos5l_padframe.v`, `verilog/gl/chipalooza_frame_wrapper.v`, and `scripts/gen_padframe.tcl`; **all three already exist, and the parser refuses to overwrite them**. The README's `verilog/gl/openframe_project_wrapper.v` is an older name and is absent.
- [ ] Generate the padframe layout with `scripts/run_gen_padframe.sh` from the repository root. Its current script changes into `magic/` and sources `scripts/gen_padframe.tcl`; `magic/sg13cmos5l_padframe.mag` already exists. The README instead says to start in `magic/` and refers once to `sg13cmos5_padframe.mag`; check the script before rerunning. Also preserve the existing `magic/chipalooza_frame_wrapper.mag` and `magic/openframe_project_wrapper.mag`.
- [ ] Run `scripts/set_user_id.py` to program the configured ID. It edits `magic/user_id_vias.mag`, `magic/user_id_textblock.mag`, and `verilog/gl/sg13cmos5l_ocd_chipalooza.v`. The two Magic files exist; that Verilog file does **not** exist here. The README names `caravel_openframe.v` and `user_id_programming.v` as edited outputs, but the current script targets the newer top-level Verilog name. Resolve that missing input before running this step.

## Build each project and its wrapper

- [ ] For synthesized blocks, run LibreLane separately. From its standard flow take `51-openroad-fillinsertion/*.pnl.v` for LVS, `*.nl.v` for mixed-mode simulation, and `55-magic-streamout-1/*.mag` for layout. Use an include list or `SIM`/`LVS` conditionals to select the right netlists. These are flow output patterns, not checked-in filenames.
- [ ] Keep the analog project as a separate hierarchy, conventionally `openframe_user_project` (`magic/openframe_user_project.mag` exists), and connect it within the frame wrapper. The README suggests copying wrapper pin geometry into the project layout, then removing or renaming unused labels. Keep the wrapper boundary and padframe-matching pins intact; regenerated wrapper files can otherwise erase project work.

## Assemble, fill and verify

- [ ] From `magic/`, run `../scripts/run_gen_wrapper_gds.sh`. The current output is `gds/chipalooza_frame_wrapper.gds.gz`, using `magic/chipalooza_frame_wrapper.mag`. The README's `gds/openframe_project_wrapper.gds.gz` is an older name. No generated GDS is currently present in `gds/`.
- [ ] From `magic/`, run `../scripts/run_gen_openframe_gds.sh` to assemble the wrapper, padframe and seal ring. Current output names are `magic/sg13cmos5l_ocd_chipalooza.mag` (already present) and `gds/sg13cmos5l_ocd_chipalooza.gds.gz` (absent). The README calls the GDS `sg13cmos5l_caravel_openframe.gds.gz`.
- [ ] From `gds/`, run `../scripts/generate_fill.py sg13cmos5l_ocd_chipalooza.gds.gz -dist`. Expect `gds/sg13cmos5l_ocd_chipalooza_fill_pattern.gds.gz`. The README's fill command and output use the older `caravel_openframe` basename.
- [ ] From `magic/`, run `../scripts/run_gen_filled_final_gds.sh`. Set `PROJECT` to the IHP-assigned top-cell name for submission. The current script defaults to `sg13cmos5l_ocd_chipalooza_final`, producing `magic/${PROJECT}.mag` and `gds/${PROJECT}.gds.gz`; the README states the older `sg13cmos5l_caravel_openframe_final` default. `magic/sg13cmos5l_ocd_chipalooza_final.mag` already exists.
- [ ] From `validate/`, run `./run_klayout_drc_final.sh` on the final GDS and review `validate/${PROJECT}.lyrdb`. Set `PROJECT` explicitly: this validation script still defaults to `sg13cmos5l_caravel_openframe_final`.
- [ ] From `magic/`, run `./run_extract_openframe.sh` and check `netlist/layout/${PROJECT}.spice`. Set `PROJECT` explicitly: this script also retains the old default and loads an old `caravel_openframe` fill-cell placeholder.
- [ ] From `validate/`, adapt `run_lvs_openframe.sh` for the actual project schematic/netlists and run final LVS. It expects `netlist/schematic/openframe_user_project.spice` and `verilog/gl/${PROJECT}.v`, neither of which is present here for the current default name. The README says Magic/Netgen top-level LVS currently fails because of PDK padframe I/O netlist issues; resolving those issues remains an open task.

## README/current-tree discrepancies to settle before executing the flow

- `config.txt` currently contains entries for slots **17 and 18**, although the README says only slots 1–16 have configurable dedicated pads. Check the actual padframe and slot interface before editing those entries.
- The README's analog-pad example labels `sg13cmos5l_IOPadInOut30mA` as analog; checked-in `config.txt` uses `sg13cmos5l_IOPadAnalog` for analog positions. Follow the checked-in configuration and parser rather than that example.
- The generation scripts now use `sg13cmos5l_ocd_chipalooza` and `chipalooza_frame_wrapper` names, while extraction and LVS retain `sg13cmos5l_caravel_openframe_final` defaults. Use a consistent explicit `PROJECT` and inspect any stale cell names before running the final checks.
