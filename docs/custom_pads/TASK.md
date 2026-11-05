# TASK FILE for the cloud agent: custom-pad integration test on the harness fork

Read this whole file before doing anything. It was written 2026-11-05 by the user's chat assistant.
It lives on branch `toplevel` of `tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single`.

You are working on a TEST PLATFORM, not on a tape-out. Goal: find out, by doing it, what it takes to
get two custom I/O pad cells (and the slot 7 design behind them) through the Chipalooza harness flow,
and leave a reproducible record. Everything you do goes on sandbox branches of the user's own forks.

### Hard rules (read first, they override everything below)

1. Harness repo: `tatzelbrumm/sg13cmos5l_ocd_chipalooza` (a fork of `RTimothyEdwards/...`, which is the
   tape-out-ready design). Create branch `custom-pad-test` from the fork's `main`. Push ONLY that branch.
   Never push to `main` or any other existing branch. Never push, open a PR, issue or comment to
   `RTimothyEdwards/*`. Do not add an upstream remote with push URL. No force-push.
2. Slot repo: `tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single`. Read from branch `toplevel`, NOT from
   `main` (`main` is stale and lacks the pad GDS; the pad GDS and `slot.klay.gds` are on `toplevel`).
   Create `harness-test` from the tip of `toplevel` and record its commit hash in the findings. The only
   thing you may push there is that new branch `harness-test`. Never push to `toplevel`. Never switch a checkout to the orphan branch
   `sudel_buecher` (it empties the working tree). Its `CLAUDE.md` applies; its Makefile targets
   need `export PDK_ROOT=/foss/pdks; source .designinit`.
3. Additive changes only to the harness: prefer new files and new branches inside existing scripts over
   rewriting them. Every edit to an existing file is listed in the findings file with a reason.
4. No spreadsheets, no Microsoft formats. Explicit over implicit: in the findings, write out every
   command with its full path and every assumption you made.
5. Environment: `export PDK_ROOT=/foss/pdks PDK=ihp-sg13cmos5l`. LibreLane/OpenROAD are not installed
   and are not needed. Never disable TLS checks or work around the network allowlist; if a download
   is refused, say so and continue with what you have.
6. Time is short. Work in the phases below, commit and push after each phase, and keep going to the next
   unless a STOP condition is hit. Do not ask the user questions; take the most reasonable reading,
   write it down in the findings file, and continue.

### What the pads are (facts from the user's design; verify against the files)

- Source: slot repo, `macros/sg13cmos5l_IOPadDiff2Single/layout/klayout/sg13cmos5l_IOPadDiff2Single.klay.gds`
  and `macros/sg13cmos5l_IOPadSingle2Diff/layout/klayout/sg13cmos5l_IOPadSingle2Diff.klay.gds`
  (top cells carry the file's cell name; dbu 0.001; bbox x -0.62..80.62, y 0..180 um).
  Schematics, symbols and spice: same macros' `schematic/`, `netlist/` folders.
- Core-side pins (Metal2 on the top edge, y = 180): D2S `vinp vinn vref iref en_3v3_b en_3v3`;
  S2D `vref iref en_3v3 en_3v3_b outp outn vcm`. Pad pin `pad`. Rails `iovdd iovss vdd vss`.
  `en_ctrl_3v3` and `bias_gen_pd` are deliberately OUTSIDE the pad cells.
- Feedback loops are closed INSIDE the pad cells; there are no feedback pins on the cell interface
  (the lists above are complete). D2S: `vfb` is tied to `pad` (Kelvin line from the pad junction). S2D:
  `vfbp` / `vfbn` are tied to `outp` / `outn` on the pad's top sheet. Only the CACE fixtures
  (`d2s_mpdda_pd_sel`, `s2d_mpdda_pd_sel`) open the loops, with `vfb`, `vfbp`, `vfbn` as pins, for loop
  gain; they are not part of the cells and not part of this task. The layouts carry the labels `vfb`,
  `vfbp`, `vfbn` (and `vcmfb`) only inside sub-cells. Check that, after import into magic, none of
  these shows up as a port of the pad cell (the ports must be exactly the pin lists above).
- Known and accepted, from the pad macros' READMEs: the cells pass the klayout strict-port LVS, but the
  magic + netgen LVS (which is what this harness uses) fails ONLY on the `vss` pin, because `vss` and
  `iovss` are one p-substrate node (the sheets tie them with a 1 ohm `Rsub`, simulation only). Expect
  exactly this in the padframe/top LVS. Report it as known; do not "fix" it by changing the cells.
- Planned assignment: `s7_an[0]` = IOPadSingle2Diff, `s7_an[1]` = IOPadDiff2Single, with the S2D outputs
  wired to the D2S inputs inside the slot. Pads are on the harness pad ring, support circuitry is in slot 7.
- Slot frame: `macros/slot/layout/klayout/slot.klay.gds` (537.15 x 273 um, slot7_wrapper-compatible).
- Known traps found by inspection, check each one:
  a. Foundry pad cells in this harness are 80 um wide (`FIXED_BBOX 0 0 16000 36000` at magscale 1 2 in
     `magic/sg13cmos5l_io/sg13cmos5l_IOPadAnalog.mag`). The custom cells are 81.24 um wide with geometry
     from -0.62 to 80.62. Find out whether that overlaps neighbours in the ring, and whether the rails
     abut like the foundry cells. If not, report the exact offending shapes.
  b. 21 sub-cell names occur in BOTH pad GDS files (for example `DCNDiode`, `DCPDiode`, `Clamp_N_M1`,
     `nmosHV`, `rppd`, `edge_stubs`). Same name does not mean same content. Compare per cell (KLayout XOR).
     Different content under one name must be renamed with a unique prefix before both are loaded into
     one magic session. Also check against the foundry cells in `magic/sg13cmos5l_io/`.
  c. `magic/sg13cmos5l_io/` is in `.gitignore` and is regenerated by `scripts/setup.sh`. Custom cells
     therefore must NOT live there.

### Connecting the pads to slot 7 (you do all of this; the user has not done any of it)

How the connection works in this harness, from the scripts (verify): `gen_padframe.tcl` paints a small
M3 (or M2 on the top side) strip at the pad's core-side pin and labels it, via `label_*_analog`. The slot
wrappers are carved out of `chipalooza_frame` by `run_gen_user_wrappers.sh`, which turns every label inside the
537.15 x 273 um slot box into a port (`port makeall`). Slots 10 to 18 are flipped sideways. So the pad and
the slot meet BY ABUTMENT at the slot boundary: a pin in `slot_7.gds` connects if its shape overlaps the
frame's strip, same layer, same name. Therefore `slot_7.gds` must carry, on the correct edge, pin shapes on
the correct layer at the positions the regenerated wrapper has, plus the labels the harness expects
(GDS layers: 30 = Metal3 and 10 = Metal2, datatype 2 = pin, 25 = label).
Back-annotation: whatever name and position a pin gets in the regenerated wrapper must be mirrored in
`slot_7.gds`, in the slot repo's own LEF/lib/vh views (`final/lef`, `final/lib`, `final/vh`), in
`verilog/rtl/slot7_wrapper.v`, in the generated xschem symbol, and in the `config.txt` core signal names.
Do it in one place (a small table in the findings file: signal, pad, layer, edge, position) and derive
the others from it, so that they cannot drift apart.

Pad core pins, measured from the user's GDS (top edge, y = 180 um, Metal2, shapes 0.29 um wide, x in um
relative to the cell origin, pad cell is 81.24 um wide; check against the files):
- D2S: vinp 6.21, vinn 6.75, vref 7.29, iref 44.55, en_3v3_b 45.09, en_3v3 45.62. Note the 0.54 um pitch
  of the groups: M3 strips will not fit at that pitch, so a fan-out (M2/M3/M4 jogs) is needed.
- S2D: vref 6.21, outp 17.82, outn 23.91, vcm 29.96, en_3v3 36.60, en_3v3_b 47.79, iref 53.45.
- Slot frame today (right edge): `s7_an[0]` M3 y 132-157, `s7_an[1]` M3 y 242-267, `s7_an_0_esd` y about
  163.7, `vss_1v2` M2 y 11.6-71; left edge carries the harness pins at 0.44 um pitch, y 72-113.
The two pads sit in the ring at `pad_s7_an_0` and `pad_s7_an_1`; the existing M3 pins at the slot edge
belong to the analog pad and go away or move when the pad type changes.

What `slot_7.gds` must contain, at minimum:
1. All new pins, per the table above, with legal spacing and width on their layer (run the DRC on it).
2. Minimal wiring, as a proof of concept only: S2D `outp` to D2S `vinp` and S2D `outn` to D2S `vinn`,
   routed in Metal3/Metal4 with vias as needed, inside the slot, no shorts between the nets. This is a
   stand-in. Once real circuits fill `slot_7.gds` this wiring will change, and the pad integration test
   does not depend on it. Do not spend time optimising it.
3. All 13 pad core pins are DISTINCT wrapper ports (one port per pad pin; do not merge ports in the
   wrapper). Sharing is decided inside the slot by wiring, not by the interface. Apart from supplies, the
   two pads do not share nets by necessity. Pin by pin:

   | pin | D2S | S2D | treatment in this test |
   |---|---|---|---|
   | `vinp`, `vinn` | pin | none | wired to S2D `outp`, `outn` (item 2) |
   | `outp`, `outn` | none | pin | wired to D2S `vinp`, `vinn` (item 2) |
   | `vcm` | none | pin | own port, stub |
   | `vref` | pin | pin | two ports, two stubs. May be tied in the slot only if both pads want the same voltage; that is open (S2D suite 1.2 V, D2S suite 1.65 V), so do not tie them |
   | `iref` | pin | pin | two ports, two stubs: two independent sourced currents (harness `ibias0` to D2S, `ibias1` to S2D) |
   | `en_3v3`, `en_3v3_b` | pin | pin | four ports; the same enable drives both pads logically, so tying the two `en_3v3` and the two `en_3v3_b` stubs together is allowed if it is trivial, otherwise leave four stubs |
   | `pad` | pin | pin | ring side, goes to the bondpad of `s7_an[1]` (D2S) and `s7_an[0]` (S2D); not a core port |
   | `iovdd`, `iovss`, `vdd` (S2D also `vss`) | rails | rails | supplies through the ring and the existing supply pins; not core signal ports |

   For every net that would come from support circuitry (bias sources, enable level shifter, `vref`/`vcm`
   source): do NOT invent circuits. Tie each to a labelled stub (a pin-labelled via stack on a short wire)
   so that the connectivity is visible and testable, and list the stubs in the findings.
4. Supplies as in the existing frame (`vdd_1v2`, `vss_1v2`, `vdd_3v3`, `vss_3v3`); the harness replaces
   ungated supplies by obstruction metal in the wrapper, so do not route over those areas.

Layers and how to get from the pad pins to the slot edge. The pad cells bring their core pins out on Metal2
(0.29 um shapes); the harness label procs for pads on the right and left sides paint Metal3 strips, and
for the top side Metal2. Choose the cheapest option that works, in this order, and write down which one
you took and why:
1. Do everything inside `slot_7.gds` and the generated frame strips: M3 pins at the slot edge, with vias
   (V2, and V3 to Metal4 if needed) and short jogs to reach the M2 pad pins. No change to the pad layout.
2. If the 0.54 um pin clusters of the D2S (`vinp vinn vref`, `iref en_3v3_b en_3v3`) cannot be fanned out
   legally in the frame or slot, change the pad layout, additively and cheaply: add Metal3 landing pads
   and a fan-out on top of the existing M2 core pins (new shapes plus V2 only; no change to devices or
   existing wiring; keep names and positions of the pin labels or move them together with the shapes).
   Do this on the `harness-test` branch of the slot repo, where the pad layouts live, and then re-import
   into the harness (Phase 1). Re-run the pad macros' own DRC and LVS (their Makefile targets, see the
   slot repo `CLAUDE.md`) so that the change is shown to be layout-only. Do not edit the foundry cells.
3. Connecting two abutting wires on different metals (for example M2 pad pins to M3 frame strips) is
   allowed by a via placed in whichever side is cheaper, provided it does not change label names, ports,
   or the way `run_gen_user_wrappers.sh` and `get_project_gds.sh` find and place things. If it would
   upset the harness procedure (for example a new layer in a label proc that other slots use), do not do
   it; record it as a proposal for Tim instead.
Any of 1 to 3 that touches the harness scripts is additive and per custom pad type only; other slots
and the foundry pad types must produce byte-identical results in `make config` and `make padframe`
(check this explicitly: diff the generated output for the unmodified slots against the baseline from
Phase 0).

Verify by extraction: run the harness LVS flow on slot 7 (or at least extract the pre-fill top and show,
net by net, that each pad core pin reaches its intended slot net and nothing else). Report every net
that does not.

### Phase 0: recon and baseline (read-only, then one baseline run)

Read: `README` (steps 1-15), `Makefile`, `config.txt`, `scripts/setup.sh`, `scripts/parse_config.py`,
`scripts/gen_padframe_template.tcl`, `scripts/gen_padframe.tcl`, `scripts/run_gen_padframe.sh`,
`scripts/run_gen_user_wrappers.sh`, `scripts/run_gen_wrapper_gds.sh`, `scripts/get_projects.sh`,
`scripts/get_project_gds.sh`, `scripts/run_gen_prefill_gds.sh`, `scripts/gen_xschem_sym.py`,
`scripts/check_staleness.py`, `validate/run_lvs_padframe.sh`, `validate/run_lvs_ocd_chipalooza.sh`,
`magic/run_extract_padframe.sh`. Clone with `--recurse-submodules` (three submodules from RTimothyEdwards).

Baseline: `make setup`, `make check`, then reproduce the unmodified padframe path far enough to prove the
environment works (for example `make clean-config`, `make config`, `make padframe`, compare with the
committed files). Write down which targets work in this cloud environment and which do not.

### Phase 1: import the pad GDS (question 1)

Place (proposal; deviate only with a written reason):
- `magic/custom_io/gds/<cell>.gds`: the two source GDS copied verbatim from the slot repo, with the
  slot-repo commit hash and sha256 of each recorded in `magic/custom_io/PROVENANCE.md`.
- `magic/custom_io/<cell>.mag`: generated by magic from those GDS (commit them: the directory is tracked).
- `magic/custom_io/lef/<cell>.lef`: only if Phase 2 finds a LEF is needed.
- `scripts/layout_setup.tcl`: one added line `addpath custom_io`.
- Provide `scripts/setup_custom_io.sh`, additive, rebuilding the .mag from the GDS the same way
  `scripts/setup.sh` imports the foundry library (`gds readonly`, `gds rescale false`).
Resolve traps (a) and (b) here. Core pins must come through as magic ports with correct labels.
STOP condition: if the cells cannot be made to coexist in one magic session, report why and stop.

### Phase 2: make them digestible (question 2: LEF or not?)

Find out, do not assume. Concretely: (i) grep every script for where the foundry IO LEF
(`libs.ref/sg13cmos5l_io/lef/sg13cmos5l_io.lef`) is read and what depends on it; (ii) build the padframe
once WITHOUT a custom LEF and once with one (`lef write` from magic) and report any difference in the
generated `magic/sg13cmos5l_padframe.mag` and in GDS; (iii) state the answer in one line in the findings.
Also needed, to be found and added:
- Pad-type handling in `scripts/parse_config.py` (it tests the 11 foundry names in 4 places and prints
  "Bad pad type" for anything else). Make it data-driven: one table `CUSTOM_PADS` mapping the cell name to
  its core signal list (derive the list from the pad cell's own pin list), used in all 4 places.
- The templates that feed it: `scripts/sg13cmos5l_padframe_template.v`,
  `scripts/chipalooza_frame_wrapper_template.v`, `scripts/gen_padframe_template.tcl`
  (do not edit the generated `scripts/gen_padframe.tcl`: it says so).
- `config.txt`: `s7_an[0]` and `s7_an[1]` set to the custom types, with core signal names.
- LVS: a pad netlist for the custom cells in a NEW file `netlist/schematic/custom_io.spice` (take it from
  the slot repo's `netlist/schematic/*`), and the extra `readnet` lines (or black-box lines, as the
  existing scripts do for IO cells) in `validate/run_lvs_padframe.sh` and `validate/run_lvs_ocd_chipalooza.sh`.
- Xschem symbols and `_lvs.v` views: `make symbols`, then `make check`.
Wrapper ports (this is the core of the task, see also "Connecting the pads to slot 7" below): the custom
pads bring 13 core-side signals (D2S 6, S2D 7) instead of the analog pad's 2. Make the generator produce
them: new label procs next to `label_right_analog` / `label_left_analog` / `label_top_analog` in the
template (one per pad core pin, M3 strip plus label plus `port make`), so that the regenerated frame
carries the new pins and `run_gen_user_wrappers.sh` (`port makeall`) turns them into ports of
`slot7_wrapper`. Also update `verilog/rtl/slot7_wrapper.v` and `verilog/gl/*` (port lists; note the rules
in that file's header comment about scalar `real` ports), and the generated xschem symbols.
STOP condition: if a step needs a change to the chip core routing in `chipalooza_frame` that cannot be done
additively on the sandbox branch, write down the exact change needed and continue with what is possible.

### Phase 3: run the padframe sequence (question 3)

On the sandbox branch run, in this order, logging each command's full output to `docs/custom_pads/logs/`:
`make clean-config`, `make config`, `make padframe`, `make wrappers` and `make gds-slots` (decide from the
scripts which of the two is the right one for README step 7 and say why), `make check`.
Then run the available DRC on the padframe/pad area (klayout DRC deck from the PDK) and the padframe LVS
(`make extract-padframe`, `make lvs-padframe`). Report error counts and the first 10 distinct messages.

### Phase 4: slot 7 through the ordinary flow (question 4)

The slot repo has no `slot_7.gds` yet (only `final/gds/sg13cmos5l_cm_ip__single2diff2single.gds`). The
harness needs a file `slot_7.gds` with top cell `slot_7`, in `final/gds/` or `gds/` (exactly one of
`.gds` or `.gds.gz`), frozen by commit hash.
1. In the slot repo create branch `harness-test`. Build `final/gds/slot_7.gds` (top cell `slot_7`) so that it
   ACCOMMODATES the extra pad connections of the regenerated `slot7_wrapper` from Phase 3. Start from the
   frame `macros/slot/layout/klayout/slot.klay.gds` (KLayout python; do not use git for the layout work),
   and do the routing yourself, see "Connecting the pads to slot 7" below. The result is still a plumbing
   demo, not a design: put a README line in that branch saying so, and list what is real and what is a
   stand-in. If anything about the wrapper boundary does not match the frame, say so in the findings
   and say what you changed to make it match; do not adapt silently.
2. In the harness `config.txt` on `custom-pad-test` set `s7_version` to that branch's commit (look at how
   the other `sN_version` lines are written, and at `scripts/get_projects.sh --help` for the format).
3. Run: `make projects SLOTS=7`, `make projects-gds SLOTS=7`, `make user-id`, `make gds-prefill`, then the
   klayout DRC on the pre-fill GDS (`make drc`). `make fill` and `make gds-final` only if time remains.
   Do not run the whole `make all`-style chain for 18 slots.
4. Check that slot 7 landed where `slot7_wrapper` is and that the custom pads are in the pad ring.
   Produce one PNG of the pad ring section and one of the slot 7 area (KLayout python, layout-to-image).

### Record keeping (required: this is a proof-of-concept trial run, so the steps must be documented)

Two kinds of record, both committed on the sandbox branch `custom-pad-test` under `docs/custom_pads/`
(the user files them into their own record branch later; do NOT touch any existing `sudel_buecher` branch,
do not check it out, and do not push to it). The slot repo's `CLAUDE.md` says "no chat log unless asked":
it is asked, here, and only here.

1. RUN LOG, from the first command to the last.
   - Tee every `make` target and every script you run, stdout and stderr separately:
     `<command> > >(tee docs/custom_pads/logs/NN_<name>.out) 2> >(tee docs/custom_pads/logs/NN_<name>.err >&2)`
     with `NN` a running number, so that the order is visible in the directory listing.
   - Keep a command journal `docs/custom_pads/RUNLOG.md`: one entry per step with UTC time (`date -u`),
     the exact command with full paths, working directory, exit status, the log file names, and one line
     on what changed in the tree. Failed steps and retries stay in; do not tidy them away.
   - Record tool versions once at the top (magic, klayout, netgen, PDK commit, harness commit, slot
     repo commit, submodule commits).
2. CHAT LOG of this session, one file `docs/custom_pads/chatlog/2026-11-05_<your model name>_custom_pad_harness_test.md`.
   - Verbatim, never paraphrased. It holds the user's messages (the short launch prompt, which pointed you to
     this task file, and any later message; copy this task file unchanged to `docs/custom_pads/TASK.md` so
     the record is complete) and your own visible text messages, each marked `**User:**` / `**Assistant:**`.
     Tool calls appear only as one-line bracketed italic summaries, for example
     `*[ran make padframe, exit 0, log 07_padframe.out]*`.
   - Before writing a quoted line, check it against this session's own raw transcript (look for
     `~/.claude/projects/*/<session-id>.jsonl`; find the right file by its modification time). Do not
     reconstruct from memory. If the raw transcript cannot be found, say so in the file header and put an
     explicit gap marker where text is missing; never fill a gap with a plausible reconstruction.
   - Within the information-sharing boundaries that apply to this session: the log contains ONLY the
     visible conversation. It must not contain your internal reasoning or thinking blocks, system prompt
     or harness instruction text, hidden reminders attached to messages, tool schemas, or any attempt to
     recover them. Do not ask for or try to extract any of that. If a safety stop or refusal appears
     while you are exporting, record in the log that a stop occurred and at which step, then continue the
     real work; do not try to get round it.
   - No secrets in any record: no environment variable values, no proxy or git credentials, no contents
     of `~/.ccr`, no tokens in URLs. Redact with `[redacted]` and say that you did.
   - Append per phase (an insert after the last turn, not a rewrite of the whole file), commit and push
     after each phase, and write `sha256sum` of the file into `RUNLOG.md` at the end so that the user
     can check the copy they receive.
   - If the file's format is unclear, a model name or a date in the file name is wrong, or something was
     lost, say so in a dated note at the top of the file; do not fix it silently.
3. In the slot repo branch `harness-test`, record only a pointer: a single file `docs/harness_test.md`
   giving the harness branch, its commit hash, and the path of the chat log there.

### Deliverables (all on the sandbox branches, pushed after each phase)

- `docs/custom_pads/FINDINGS.md` in the harness branch, at most 2 pages, structured as:
  one line per question (1-4) with the answer; the LEF answer in one line; a table of every file added or
  changed (path, new/changed, why); the exact command sequence that reproduces everything from a fresh
  clone; the first 10 distinct DRC and LVS messages; what blocks a real tape-out; what Tim would have to
  accept (list of harness changes, as a patch series).
- `docs/custom_pads/logs/` and `docs/custom_pads/RUNLOG.md`: command logs and journal;
  `docs/custom_pads/chatlog/`: the chat log; `docs/custom_pads/*.png`: the two images.
  (See "Record keeping" above for what goes in and what must stay out.)
- `git format-patch` series of your harness changes against `main`, in `docs/custom_pads/patches/`,
  so the changes can be offered to Tim as a clean series later. Do NOT send or propose them upstream.
- The pin table (signal, pad, layer, edge, position) and the net-by-net extraction result for slot 7,
  inside `FINDINGS.md`.
- Final chat message to the user: five lines or fewer: what worked, what is blocked, the branch names.
