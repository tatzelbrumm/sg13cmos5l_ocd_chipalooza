<!--
SPDX-FileCopyrightText: 2026 Christoph Maier
SPDX-License-Identifier: Apache-2.0
-->
# en_ctrl_3v3 v2 / ls_up_fs (fail-safe enable and level shifter of the slot glue): characterization data sheet

> **Scope: partly the taped-out circuit.** The taped-out `slot_7` does **not** instantiate the cell `en_ctrl_3v3` as such. Its enable and mode bits are shifted by seven instances of `ls_up_fs` (`efs_ls_core`), the level shifter of `en_ctrl_3v3` v2 (CACE file created for the cell around it), followed by `inv_hv` / `nand2_hv` gates. This sheet is the only CACE characterization of that shifter: the shifter is the circuit under test in the groups below, but the suite exercises the whole `en_ctrl_3v3` v2 (enable plus select-bit shifters and its `en_3v3_b` inverter), not the slot's `s7_ctrl`. Groups that concern `vddl` (the cell's old 1.2 V supply input, no longer connected inside) are left in because the suite contains them; they show that `vddl` does not matter, which is a property of the taped-out use (no 1.2 V supply is needed). Results are for the schematic netlist (2026-11-08); the layout of this cell was DRC / LVS checked, not extracted.

**Cell:** `en_ctrl_3v3`  
**Description (from the CACE file):** Fail-safe 1.2 V -> 3.3 V enable and select bits without a 1.2 V supply (v2)  
**PDK:** ihp-sg13cmos5l  
**Designer:** Christoph Maier, CACE file created October 20, 2026  
**Source:** [`macros/en_ctrl_3v3/verification/cace/en_ctrl_3v3.yaml`](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/blob/9052bd35928c6d40344e8e686c9abbe736bfadb9/macros/en_ctrl_3v3/verification/cace/en_ctrl_3v3.yaml) at design-repository commit `9052bd35`; results [`verification/cace/results/`](https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single/tree/9052bd35928c6d40344e8e686c9abbe736bfadb9/macros/en_ctrl_3v3/verification/cace/results)  
**Generated:** by `datasheets/tools/make_datasheet.py` from the committed CACE files; **no simulation was run for this sheet** and nothing was re-checked against the taped-out netlist.

## Pins

| pin | type | direction | description | limits |
|---|---|---|---|---|
| `vddh` | power | inout | 3.3 V supply (iovdd in the pad, vdd_3v3 in the slot fallback) | Vmin 3.0 Vmax 3.6 |
| `vddl` | power | inout | 1.2 V supply, not connected inside since v2 (kept for the symbol) | Vmin 0 Vmax 1.32 |
| `vss` | ground | inout | Ground |  |
| `en_1v2` | digital | input | Enable request, 0 .. 1.2 V, active high |  |
| `sel0_1v2` | digital | input | Select bit 0, 0 .. 1.2 V |  |
| `sel1_1v2` | digital | input | Select bit 1, 0 .. 1.2 V |  |
| `vdd1v2_sense` | signal | input | The slot's gated vdd_1v2 (presence sense) |  |
| `vdd3v3_sense` | signal | input | The slot's gated vdd_3v3 (presence sense) |  |
| `en_3v3` | digital | output | Enable, 0 .. vddh, active high |  |
| `sel0_3v3` | digital | output | Select bit 0, 0 .. vddh |  |
| `sel1_3v3` | digital | output | Select bit 1, 0 .. vddh |  |
| `en_3v3_b` | digital | output | NOT en_3v3, 0 .. vddh |  |

## Default conditions

| condition | typical | unit | description |
|---|---|---|---|
| `corner_mos` | tt |  | Process corner MOSFET |
| `temp` | 27 | °C | Ambient temperature |
| `sup` | 0.5 |  | Supply set, 0 = (vddl, vddh) = (1.08, 3.0) V, 1 = (1.32, 3.6) V, 0.5 = (1.2, 3.3) V |
| `case` | 0 |  | DC input state (see the testbench template) |
| `scenario` | 1 |  | vddl in tran_vddl, 1 = 0 V (slot vdd_1v2 off), 2 = floating at 0.62 V |
| `cload` | 50 | fF | Load at en_3v3 |

## CACE run summaries: schematic

Results directory: `verification/cace/results/en_ctrl_3v3`. One table per parameter group, as CACE wrote it in `summary_<group>.md` (rows with status *Skip* belong to other groups and are left out): limit and measured minimum / typical / maximum over the runs of the group, and CACE's verdict. *Runs* is the number of rows of the group's CSV.

**Verdicts in this view:** 33 pass, 0 fail, 0 other (rows of all groups).

### truth_params

*Runs:* 8  
*Swept conditions:* case: 0, 1, 2, 3, 4, 5, 6, 7; corner_mos: tt; temp: 27; sup: 0.5; cload: 50  

| quantity | min limit | min value | typ value | max limit | max value | status |
|---|---:|---:|---:|---:|---:|---|
| en_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| sel_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| I vddh | any | 49.860 nA | 99.718 nA | 240 nA | 149.576 nA | Pass ✅ |
| I vddl | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd1v2_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd3v3_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I en_1v2 | any | -0.000 nA | -0.000 nA | 0.3 nA | -0.000 nA | Pass ✅ |

### pvt_params

*Runs:* 20  
*Swept conditions:* case: 0; corner_mos: ss, sf, tt, fs, ff; temp: -40, 125; sup: 0, 1; cload: 50  

| quantity | min limit | min value | typ value | max limit | max value | status |
|---|---:|---:|---:|---:|---:|---|
| en_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| sel_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| I vddh | any | 54.794 nA | 96.077 nA | 240 nA | 172.220 nA | Pass ✅ |
| I vddl | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd1v2_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd3v3_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I en_1v2 | any | 0.000 nA | 0.000 nA | 0.3 nA | 0.000 nA | Pass ✅ |

### vddl_off_params

*Runs:* 40  
*Swept conditions:* case: 2, 3; corner_mos: ss, sf, tt, fs, ff; temp: -40, 125; sup: 0, 1; cload: 50  

| quantity | min limit | min value | typ value | max limit | max value | status |
|---|---:|---:|---:|---:|---:|---|
| en_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| sel_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| I vddh | any | 27.482 nA | 69.985 nA | 240 nA | 172.220 nA | Pass ✅ |
| I vddl | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd1v2_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd3v3_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I en_1v2 | any | -0.000 nA | 0.000 nA | 0.3 nA | 0.000 nA | Pass ✅ |

### float_params

*Runs:* 20  
*Swept conditions:* case: 4, 5; corner_mos: ss, sf, tt, fs, ff; temp: -40, 125; sup: 0; cload: 50  

| quantity | min limit | min value | typ value | max limit | max value | status |
|---|---:|---:|---:|---:|---:|---|
| en_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| sel_3v3 error | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |
| I vddh | any | 27.482 nA | 54.368 nA | 240 nA | 107.881 nA | Pass ✅ |
| I vddl | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd1v2_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I vdd3v3_sense | any | -0.000 nA | -0.000 nA | 1 nA | -0.000 nA | Pass ✅ |
| I en_1v2 | any | -0.000 nA | 0.000 nA | 0.3 nA | 0.000 nA | Pass ✅ |

### tran_en_params

*Runs:* 20  
*Swept conditions:* corner_mos: ss, sf, tt, fs, ff; temp: -40, 125; sup: 0, 1; cload: 50  

| quantity | min limit | min value | typ value | max limit | max value | status |
|---|---:|---:|---:|---:|---:|---|
| Enable delay | any | 0.784 ns | 1.341 ns | 40 ns | 2.423 ns | Pass ✅ |
| Disable delay | any | 51.421 ns | 65.673 ns | 410 ns | 81.399 ns | Pass ✅ |

### tran_vddl_params

*Runs:* 20  
*Swept conditions:* scenario: 1, 2; corner_mos: ss, sf, tt, fs, ff; temp: -40, 125; sup: 0; cload: 50  

| quantity | min limit | min value | typ value | max limit | max value | status |
|---|---:|---:|---:|---:|---:|---|
| Enable delay, vddl off | any | 1.063 ns | 1.659 ns | 40 ns | 2.423 ns | Pass ✅ |
| Disable delay, vddl off | any | 57.132 ns | 68.453 ns | 410 ns | 81.399 ns | Pass ✅ |
| en_3v3 after disable | any | 0.000 V | 0.000 V | 0.1 V | 0.000 V | Pass ✅ |

## What is not in this sheet

- Any group that has no CSV or summary in the results directory (not run, or run in another view).
- Whether the simulated netlist equals the block as taped out (see `../characterization_candidates.md`).
- Monte Carlo statistics beyond what the group's own summary reports (min / typ / max over the runs).
- Measurements on silicon: none exist at the time of writing.
