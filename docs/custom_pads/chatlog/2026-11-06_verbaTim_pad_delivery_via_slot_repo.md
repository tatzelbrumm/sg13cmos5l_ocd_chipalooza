# verbaTim: pad delivery through the slot repository (excerpt of the session chat log)

Verbatim excerpt, for Tim, of the cloud session's visible conversation from the user's message
"ok I was able to view the harness both with magic and by gds/sg13cmos5l_ocd_chipalooza.gds.gz" to the
assistant's question "Shall I do both, and is `final/pads/` the place you want the pad deliverables?".
Exported (2026-11-06T01:32Z) from the session transcript with the same filter as the full log
(`2026-11-05_claude_custom_pad_harness_test.md`, same directory): user messages and the assistant's visible
text only; no reasoning, tool output or system text. Tim's statement is quoted inside the user's message.

**User:**

ok I was able to view the harness both with magic and by gds/sg13cmos5l_ocd_chipalooza.gds.gz

So far so good. Tim says:
Okay, but as I specified, the pad layouts have to be in your slot repository in whatever is the default branch (presumably main). I cannot make any use of your fork of the chipalooza harness chip or its contents. When I build the harness chip, it will have access to your slot repository as a submodule.

How is this possible?

**Assistant:**

It's possible, and only the delivery path changes. In this test, the harness got the pads by copying them into the fork (`magic/custom_io/`). In Tim's model the harness gets them from your slot repo, which it already clones as `dependencies/slot_7` on its default branch. The mechanics we tested (import, label procs, frame clean-up, pin straps) stay the same.

## What changes

**1. In your slot repo, on `main`** (Tim takes the default branch, with `s7_version: - -` or a commit on `main`):
- the two pad GDS files, at a fixed path such as `final/pads/sg13cmos5l_IOPadDiff2Single.gds` and `final/pads/sg13cmos5l_IOPadSingle2Diff.gds`;
- their LVS netlists, e.g. `final/pads/*.spice` (today's `*_magic.spice`);
- a small manifest, e.g. `final/pads/pads.txt`, listing the cell names. This lets the harness find the pads without guessing;
- `final/gds/slot_7.gds` with the 13 pins: real circuitry later, the stand-in for now.

Today all of this exists only on `toplevel` and `harness-test`, and `main` is stale. So it means updating `main`. That's your call, and I won't touch `main` without your go.

**2. In the harness (the patch series for Tim)**, reordered so that the slot repo is the source:
- `make projects` first. The README already does it at step 4, before the pads are needed.
- `setup_custom_io.sh` reads the pads from `dependencies/slot_<N>/final/pads/` for every custom pad type in `config.txt`. It then builds `magic/custom_io/` and `netlist/schematic/custom_io.spice` from them, the same way `make setup` builds the foundry libraries. Both become generated and gitignored, so nothing of yours is committed in Tim's repo.
- `CUSTOM_PADS` in `parse_config.py` is then derived from the imported pad cells' own ports rather than written into the script. That also stops other slot owners' custom pads from needing a harness edit.
- After that, the rest runs as tested: `config` → `padframe` → `frame-custom-io` → `wrappers` → `gds-prefill`.

**3. One ordering point Tim should know about:** your `slot_7.gds` pin positions come from the wrapper that the harness generates from your pads. The cycle is: pads on `main` → harness regenerates the wrapper → you place matching pins in `slot_7.gds` → push to `main`. That's what we did here, and the pin table is the hand-off.

## What I can do now

1. **Slot repo:** a new branch, e.g. `pad-delivery`, from `toplevel`, with `final/pads/` (GDS, netlists, manifest) and `final/gds/slot_7.gds`, ready for you to merge into `main` or open as a PR. I won't push to `main` myself unless you tell me to.
2. **Harness, on `custom-pad-test`:** rework the patch series so the pads come only from `dependencies/slot_7`. Then rerun the whole sequence from a fresh clone with nothing in `magic/custom_io/`, to prove that Tim's build needs nothing from your fork.

Shall I do both, and is `final/pads/` the place you want the pad deliverables?
