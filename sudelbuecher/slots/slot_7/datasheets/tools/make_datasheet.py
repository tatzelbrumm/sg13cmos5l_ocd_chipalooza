#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Christoph Maier
# SPDX-License-Identifier: Apache-2.0
"""Markdown data sheet of one cell from its committed CACE files (no simulation is run).

Reads <cell>.yaml (pins, default conditions, parameter groups with conditions) and, per results directory, the
summary_<group>.md written by CACE (the rows whose status is not Skip are reproduced) and <group>.csv (number of runs).
Usage: make_datasheet.py <cell.yaml> <out.md> --title T --repo-url URL --commit SHA --cell-path PATH
                         --view LABEL=RESULTS_DIR [--view ...] [--intro FILE] [--notes FILE]
"""
import argparse, csv, glob, json, os, re, yaml

ZW = "​"

def cells(line):
    return [c.strip().replace(ZW, "") for c in line.strip().strip("|").split("|")]

def read_summary(path):
    rows = []
    hdr = None
    for l in open(path, encoding="utf-8"):
        if not l.startswith("|"):
            continue
        c = cells(l)
        if c and c[0] == "Parameter":
            hdr = c; continue
        if set("".join(c)) <= set(":-"):
            continue
        if hdr and len(c) == len(hdr):
            rows.append(dict(zip(hdr, c)))
    return rows

def cond_text(v):
    if isinstance(v, dict):
        if "enumerate" in v: return ", ".join(str(x) for x in v["enumerate"])
        if "typical" in v and len(v) == 1: return str(v["typical"])
        if "range" in v: return "range " + json.dumps(v["range"])
        if "minimum" in v and "maximum" in v: return f"{v['minimum']} … {v['maximum']} (step {v.get('stepsize','')})"
        return json.dumps(v, default=str)
    return str(v)

def nruns(csvpath):
    try:
        with open(csvpath, newline="") as f:
            return max(0, sum(1 for _ in f) - 1)
    except OSError:
        return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("yaml"); ap.add_argument("out")
    ap.add_argument("--title", required=True); ap.add_argument("--repo-url", required=True)
    ap.add_argument("--commit", required=True); ap.add_argument("--cell-path", required=True)
    ap.add_argument("--view", action="append", required=True)
    ap.add_argument("--intro"); ap.add_argument("--notes")
    a = ap.parse_args()
    y = yaml.safe_load(open(a.yaml))
    base = f"{a.repo_url}/blob/{a.commit}/{a.cell_path}"
    tree = f"{a.repo_url}/tree/{a.commit}/{a.cell_path}"
    L = ["<!--", "SPDX-FileCopyrightText: 2026 Christoph Maier", "SPDX-License-Identifier: Apache-2.0", "-->",
         f"# {a.title}", ""]
    if a.intro: L += [open(a.intro).read().strip(), ""]
    au = y.get("authorship", {})
    L += [f"**Cell:** `{y['name']}`  ", f"**Description (from the CACE file):** {y.get('description','')}  ",
          f"**PDK:** {y.get('PDK','')}  ", f"**Designer:** {au.get('designer','')}, CACE file created {au.get('creation_date','')}  ",
          f"**Source:** [`{a.cell_path}/verification/cace/{os.path.basename(a.yaml)}`]({base}/verification/cace/{os.path.basename(a.yaml)}) at design-repository commit `{a.commit[:8]}`; "
          f"results [`verification/cace/results/`]({tree}/verification/cace/results)  ",
          "**Generated:** by `datasheets/tools/make_datasheet.py` from the committed CACE files; **no simulation was run for this sheet** and nothing was re-checked against the taped-out netlist.", ""]
    L += ["## Pins", "", "| pin | type | direction | description | limits |", "|---|---|---|---|---|"]
    for n, p in (y.get("pins") or {}).items():
        lim = " ".join(f"{k} {p[k]}" for k in ("Vmin", "Vmax") if k in p)
        L.append(f"| `{n}` | {p.get('type','')} | {p.get('direction','')} | {p.get('description','')} | {lim} |")
    L += ["", "## Default conditions", "", "| condition | typical | unit | description |", "|---|---|---|---|"]
    for n, c in (y.get("default_conditions") or {}).items():
        L.append(f"| `{n}` | {c.get('typical','')} | {c.get('unit','')} | {c.get('description','')} |")
    L.append("")
    groups = y.get("parameters") or {}
    total = {}
    sections = []
    for label, d in (v.split("=", 1) for v in a.view):
        S = [f"## CACE run summaries: {label}", "",
             f"Results directory: `verification/cace/results/{os.path.basename(d)}`. "
             "One table per parameter group, as CACE wrote it in `summary_<group>.md` (rows with status *Skip* belong to other groups and are left out): "
             "limit and measured minimum / typical / maximum over the runs of the group, and CACE's verdict. *Runs* is the number of rows of the group's CSV.", ""]
        counts = {"Pass": 0, "Fail": 0, "other": 0}
        gl = []
        for g, spec in groups.items():
            sp = os.path.join(d, f"summary_{g}.md")
            if not os.path.exists(sp):
                continue
            rows = [r for r in read_summary(sp) if "Skip" not in r.get("Status", "")]
            runs = nruns(os.path.join(d, f"{g}.csv"))
            conds = (spec.get("conditions") or {})
            ctext = "; ".join(f"{k}: {cond_text(v)}" for k, v in conds.items())
            G = [f"### {g}", ""]
            if spec.get("display") or spec.get("description"):
                G += [f"{spec.get('display','')} {spec.get('description','')}".strip(), ""]
            rt = ("n/a (no CSV in the results directory)" if runs is None else
                  f"{runs}" if runs else "0 rows in the committed CSV (header only: the per-run data were not committed; the values below are CACE's own summary)")
            G += [f"*Runs:* {rt}  ", f"*Swept conditions:* {ctext or 'default only'}  ", ""]
            G += ["| quantity | min limit | min value | typ value | max limit | max value | status |", "|---|---:|---:|---:|---:|---:|---|"]
            for r in rows:
                st = r["Status"]
                key = "Pass" if "Pass" in st else "Fail" if "Fail" in st else "other"
                counts[key] += 1
                G.append(f"| {r['Parameter']} | {r['Min Limit']} | {r['Min Value']} | {r['Typ Value']} | {r['Max Limit']} | {r['Max Value']} | {st} |")
            G.append("")
            gl += G
            sections.append((label, g, runs, len(rows)))
        S += [f"**Verdicts in this view:** {counts['Pass']} pass, {counts['Fail']} fail, {counts['other']} other (rows of all groups).", ""]
        S += gl
        total[label] = counts
        L += S
    if a.notes: L += ["## Notes", "", open(a.notes).read().strip(), ""]
    L += ["## What is not in this sheet", "",
          "- Any group that has no CSV or summary in the results directory (not run, or run in another view).",
          "- Whether the simulated netlist equals the block as taped out (see `../characterization_candidates.md`).",
          "- Monte Carlo statistics beyond what the group's own summary reports (min / typ / max over the runs).",
          "- Measurements on silicon: none exist at the time of writing.", ""]
    open(a.out, "w", encoding="utf-8").write("\n".join(L))
    for label, c in total.items():
        print(a.out, label, c)

main()
