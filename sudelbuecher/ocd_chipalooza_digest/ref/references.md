# References for the OCD Chipalooza chat

## Local sources

- Source repository: `~/EDA/sg13cmos5l_ocd_chipalooza/`. The repository was read for analysis; the user later exported `gds/slot7_wrapper.gds` from Magic and saved an IO pad GDS from KLayout.
- Top-level design instructions: [`README`](../../../sg13cmos5l_ocd_chipalooza/README).
- Configuration: [`config.txt`](../../../sg13cmos5l_ocd_chipalooza/config.txt).
- Top-level Magic cells: [`sg13cmos5l_ocd_chipalooza.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/sg13cmos5l_ocd_chipalooza.mag), [`sg13cmos5l_ocd_chipalooza_final.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/sg13cmos5l_ocd_chipalooza_final.mag).
- Hierarchy and instance counts: [`chipalooza_frame.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/chipalooza_frame.mag), [`project_control_area.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/project_control_area.mag), [`sg13cmos5l_padframe.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/sg13cmos5l_padframe.mag), [`housekeeping_top.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/housekeeping_top.mag).
- Repository setup: [`scripts/layout_setup.tcl`](../../../sg13cmos5l_ocd_chipalooza/scripts/layout_setup.tcl), [`magic/README`](../../../sg13cmos5l_ocd_chipalooza/magic/README).
- Digest created during this chat: [`README_checklist.md`](../README_checklist.md).
- Slot assignment table supplied by the user: [`chipalooza_slot_assignments.md`](../chipalooza_slot_assignments.md). Its designer and circuit assignments were not independently sourced.
- Physical slot and pin map: [`doc/sg13cmos5l_chipalooza_harness_64pin.pdf`](../../../sg13cmos5l_ocd_chipalooza/doc/sg13cmos5l_chipalooza_harness_64pin.pdf).
- Magic GDS technology file: [`gds/ihp-sg13cmos5l-GDS.tech`](../../../sg13cmos5l_ocd_chipalooza/gds/ihp-sg13cmos5l-GDS.tech).
- Slot 7 export: [`gds/slot7_wrapper.gds`](../../../sg13cmos5l_ocd_chipalooza/gds/slot7_wrapper.gds).
- IO pad files compared: [`sg13cmos5l_IOPadAnalog.gds`](../../../sg13cmos5l_ocd_chipalooza/gds/sg13cmos5l_IOPadAnalog.gds) and [`sg13cmos5l_IOPadAnalog_from_magic.gds`](../../../sg13cmos5l_ocd_chipalooza/gds/sg13cmos5l_IOPadAnalog_from_magic.gds).
- KLayout PDK setup: [`sg13cmos5l.lyt`](../../../IHP-Open-PDK/ihp-sg13cmos5l/libs.tech/klayout/tech/sg13cmos5l.lyt) and [`sg13cmos5l.lyp`](../../../IHP-Open-PDK/ihp-sg13cmos5l/libs.tech/klayout/tech/sg13cmos5l.lyp).
- Related project inspected for a KLayout example: [`sg13cmos5l_cm_ip__single2diff2single/README.md`](../../../sg13cmos5l_cm_ip__single2diff2single/README.md).
- Installed Magic Cell Manager implementation inspected in the EDA container: `/foss/tools/magic/lib/magic/tcl/cellmgr.tcl` (read only). Its `magic::addlistset` routine lists child cell definitions and chooses the first instance for each definition.

## Magic documentation

- [Cell hierarchies tutorial](https://opencircuitdesign.com/magic/tutorials/tut4.html): instance selection, expansion, and editing.
- [Select command](https://opencircuitdesign.com/magic/commandref/select.html): `select cell` and named-instance selection.
- [Expand command](https://opencircuitdesign.com/magic/commandref/expand.html): `expand selection`, `expand all`, and shortcuts.
- [Unexpand command](https://opencircuitdesign.com/magic/commandref/unexpand.html): collapsing selected or all instances.
- [Edit command](https://www.opencircuitdesign.com/magic/commandref/edit.html): switching the edit cell.
- [Findbox command](https://opencircuitdesign.com/magic/commandref/findbox.html): centering or fitting the cursor box.
- [Zoom command](https://opencircuitdesign.com/magic/commandref/zoom.html): zoom factors.
- [View command](https://www.opencircuitdesign.com/magic/commandref/view.html): fitting the full layout.
- [Tool command](https://opencircuitdesign.com/magic/commandref/changetool.html): mouse behavior in the box tool.
- [DRC command](https://opencircuitdesign.com/magic/commandref/drc.html): background-checker control.
- [Cell Manager command](https://opencircuitdesign.com/magic/commandref/cellmanager.html): tree behavior and actions.
- [Magic graphics interface guide](https://opencircuitdesign.com/magic/howto.html): X11, Cairo, and OpenGL backends.
- [Cellname command](https://opencircuitdesign.com/magic/commandref/cellname.html), [Flush command](https://opencircuitdesign.com/magic/commandref/flush.html), [Quit command](https://opencircuitdesign.com/magic/commandref/quit.html), and [Load command](https://opencircuitdesign.com/magic/commandref/load.html): loaded cells and discarding changes.

## Chipalooza and KLayout documentation

- [Chipalooza leaderboard](https://opencircuitdesign.com/chipalooza/leaderboard-2.html) and [rules](https://opencircuitdesign.com/chipalooza/rules-2.html): public contest pages examined for assignments.
- [Harness and pinout PDF on GitHub](https://github.com/RTimothyEdwards/sg13cmos5l_ocd_chipalooza/blob/main/doc/sg13cmos5l_chipalooza_harness_64pin.pdf): physical arrangement of 18 slots and dedicated pins.
- [KLayout technology manager](https://klayout.de/doc/about/technology_manager.html), [setup](https://www.klayout.de/doc/manual/setup.html), and [saving layouts](https://www.klayout.de/doc/manual/save.html): technology selection, display background, and cell subtree export.

## Fork branches checked during this chat

- [`tatzelbrumm/sg13cmos5l_ocd_chipalooza` main](https://github.com/tatzelbrumm/sg13cmos5l_ocd_chipalooza/tree/main): live branch tip `8e5e475cf831ef72b59d6d3d9fb12a90ec9df7af` when checked on 2026-09-24.
- [`tatzelbrumm/sg13cmos5l_ocd_chipalooza` tatzelbranch](https://github.com/tatzelbrumm/sg13cmos5l_ocd_chipalooza/tree/tatzelbranch): live branch tip `8a8bf0723f49c9d0da5476933e120f49910ba020` when checked on 2026-09-24.
- Both tips were checked with `git ls-remote tatzelfork refs/heads/main refs/heads/tatzelbranch` and matched the corresponding local branch tips. The branch URLs are for navigation; they were not used as evidence for the live tip check.

The `tinyBGR` clone URL appears in the transcript because it was pasted accidentally. The user asked to ignore it, and it was not used as a reference for this work.

## OgueyAebischer CACE discussion

- [CACE `reference.yaml` deck](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/blob/oguey/macros/OgueyAebischerBias/verification/cace/reference.yaml).
- [CACE testbench templates](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/tree/oguey/macros/OgueyAebischerBias/verification/cace/templates).
- [Sonnet session log](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/blob/sudel_buecher/sudelbuecher/chatlog/2026-09-04_ocd_reconciliation_and_ogueyaebischerbias_cace.md).
- [Opus session log](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/blob/sudel_buecher/sudelbuecher/chatlog/2026-09-04_opus_cace_templates_and_oab_sizing.md).
- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference): raw output mode and its `Alt-R` binding.
