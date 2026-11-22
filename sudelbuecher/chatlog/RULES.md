# Chat-log rules: which ones apply, and where they disagree

Collected 2026-11-22 from `sg13cmos5l_cm_ip__single2diff2single` (`CLAUDE.md` §6 on `main`;
`sudelbuecher/verbatim_chatlog_recovery/*.md`, `sudelbuecher/chatlog/2026-09-28_opus_safety_stops_and_chatlog_export.md`
and the export script of `design_considerations/pad_buffer_alternatives/` on `sudel_buecher`).

## What to follow

1. **Only when asked.** Create or append to a chat log only on the user's explicit request (`CLAUDE.md` §6).
2. **Verbatim of what was displayed.** User messages, the assistant's visible replies, tool calls as one-line `*[ ]*` summaries.
   Extracted by script from the raw transcript, never retyped (`tools/export_chatlog.py`).
3. **No reasoning.** `thinking` blocks are never read into the output; the script checks that no 40-character window of
   any of them occurs in the file.
4. **How to ask.** Ask for "the verbatim log of the displayed conversation; internal reasoning stays out".
   Do not ask for "everything", "unabridged", the hidden reasoning, or the contents of collapsed step groups: the six requests
   stopped with `[reasoning_extraction]` on 2026-09-28 did exactly that. This is inferred from which requests were stopped,
   not a documented rule, and nothing here is a way around the safeguard: the log simply never contains what it protects.
5. **Index, do not copy** external sources: `ref/`. Images: `pix/`.

## Where the rules disagree

| Point | Rule A | Rule B | Used here |
|---|---|---|---|
| "unabridged" | `CLAUDE.md`: verbatim, never paraphrased | the export rule: collapsed step groups and reasoning stay out | B; "unabridged" means every displayed message, not every internal step |
| Source of a lost stretch | `chat-recovery-after-compaction.md`: `read_conversation` from claude.ai | the local `.jsonl`, rewritten by compaction | local `.jsonl`; `read_conversation` is not available in cloud sessions; gaps are marked, not filled |
| Transcript path | `~/.claude/projects/-home-claude/<id>.jsonl` | `-home-user` in cloud sessions | the real path is recorded in each log header |
| Appending | `CLAUDE.md`: append by `Edit`, extract only the delta | the export script rebuilds the whole file | rebuild from the transcript and replace; keep the previous export timestamp in the header |
| README entries | "one `[file](file)` + one-sentence entry" | many entries are paragraphs | one sentence |
| Header and turn format | September logs: `# Sudelbuch —` header, `## Turn N` | November logs: SPDX comment, timestamped `**User:**` | the script's `## Turn N — time` format with an SPDX header |
| Git in the worktree | `_sudelbuecher/CLAUDE.md`: no git commands at all | this repo: normal git on `sudel_buecher` | normal git; that rule is specific to a sandbox that could not unlink `index.lock` |
| Device transfer / checksums | `device_commit_files`, `sha256sum` both sides | not applicable in a cloud session | none needed; the file is written here and committed |
