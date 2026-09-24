# References for the OCD Chipalooza chat

## Local sources

- Source repository: `~/EDA/sg13cmos5l_ocd_chipalooza/` (read only throughout this chat).
- Top-level design instructions: [`README`](../../../sg13cmos5l_ocd_chipalooza/README).
- Configuration: [`config.txt`](../../../sg13cmos5l_ocd_chipalooza/config.txt).
- Top-level Magic cells: [`sg13cmos5l_ocd_chipalooza.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/sg13cmos5l_ocd_chipalooza.mag), [`sg13cmos5l_ocd_chipalooza_final.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/sg13cmos5l_ocd_chipalooza_final.mag).
- Hierarchy and instance counts: [`chipalooza_frame.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/chipalooza_frame.mag), [`project_control_area.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/project_control_area.mag), [`sg13cmos5l_padframe.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/sg13cmos5l_padframe.mag), [`housekeeping_top.mag`](../../../sg13cmos5l_ocd_chipalooza/magic/housekeeping_top.mag).
- Repository setup: [`scripts/layout_setup.tcl`](../../../sg13cmos5l_ocd_chipalooza/scripts/layout_setup.tcl), [`magic/README`](../../../sg13cmos5l_ocd_chipalooza/magic/README).
- Digest created during this chat: [`README_checklist.md`](../README_checklist.md).
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

The `tinyBGR` clone URL appears in the transcript because it was pasted accidentally. The user asked to ignore it, and it was not used as a reference for this work.

## OgueyAebischer CACE discussion

- [CACE `reference.yaml` deck](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/blob/oguey/macros/OgueyAebischerBias/verification/cace/reference.yaml).
- [CACE testbench templates](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/tree/oguey/macros/OgueyAebischerBias/verification/cace/templates).
- [Sonnet session log](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/blob/sudel_buecher/sudelbuecher/chatlog/2026-09-04_ocd_reconciliation_and_ogueyaebischerbias_cace.md).
- [Opus session log](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/blob/sudel_buecher/sudelbuecher/chatlog/2026-09-04_opus_cace_templates_and_oab_sizing.md).
- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference): raw output mode and its `Alt-R` binding.
