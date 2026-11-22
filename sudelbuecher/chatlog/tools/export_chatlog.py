#!/usr/bin/env python3
"""Verbatim chat-log export (copied from sg13cmos5l_cm_ip__single2diff2single, sudel_buecher branch, design_considerations/pad_buffer_alternatives/export.py).

Emits, in file order along the live parentUuid chain: user text blocks (system reminders and
file-delivery notices stripped), visible assistant text blocks, and tool calls as *[ ]* summaries
(tool name + first line of the main argument cut at 150 chars, plus tool errors).
AskUserQuestion is shown to the user, so its questions and options and the user's answers are verbatim.
Messages the user sends while a turn runs (queued_command attachments) are user turns, marked "sent mid-turn";
background task notifications arriving that way are one summary line, as elsewhere (2026-10-28).
Thinking blocks are never read into the output; a final check asserts no 40-char window of any
thinking block occurs in the file, and that every user/assistant text occurs verbatim.
Usage: export.py <transcript.jsonl> <out.md> <header.md> [--until N]
"""
import json, re, sys, datetime, zoneinfo

TZ = zoneinfo.ZoneInfo("Europe/Berlin")
MAIN_ARG = {"Bash": "command", "mcp__remote-devices__device_bash": "command", "Read": "file_path",
            "Write": "file_path", "Edit": "file_path", "Glob": "pattern", "Grep": "pattern",
            "WebSearch": "query", "WebFetch": "url", "ToolSearch": "query",
            "mcp__memory__memory_read": "path", "Agent": "description", "SendMessage": "summary",
            "TaskCreate": "subject", "TaskUpdate": "taskId", "Projects": "path",
            "mcp__remote-devices__device_commit_files": "files", "SendUserMessage": "message"}

def strip_user(text):
    text = re.sub(r"<system-reminder>.*?</system-reminder>\s*", "", text, flags=re.S)
    text = re.sub(r"<user_memory_snapshot>.*?</user_memory_snapshot>\s*", "", text, flags=re.S)
    text = re.sub(r"^@\"/mnt/user-data/attachments/[^\n]*\n(The files from earlier[^\n]*\n)?", "", text, flags=re.M)
    text = re.sub(r"This conversation belongs to a project\..*?@-mentioned paths instead\.\s*", "", text, flags=re.S)
    text = re.sub(r"\[Image: original [^\]]*\]\s*", "", text)
    text = text.strip()
    if text.startswith('@"/mnt/user-data/attachments') and "delivered automatically" in text: return ""
    if text.startswith("The files from earlier in this conversation were delivered automatically"): return ""
    if text.startswith("[Request interrupted by user for tool use]"): return "*[the user interrupted a tool call]*"
    if text.startswith("[Request interrupted by user]"): text = text[len("[Request interrupted by user]"):].strip()
    return text

def notification(text):
    """A background-agent notification is not a user turn: one summary line, the report itself stays out."""
    m = re.search(r"<summary>(.*?)</summary>", text, flags=re.S)
    s = (m.group(1).strip() if m else "agent finished").split("\n")[0]
    return "*[background task notification: " + (s[:150] + " …" if len(s) > 150 else s) + "]*"

def ts(rec):
    t = rec.get("timestamp")
    if not t: return ""
    d = datetime.datetime.fromisoformat(t.replace("Z", "+00:00")).astimezone(TZ)
    return d.strftime("%Y-%m-%d %H:%M")

def summary(tu):
    name = tu.get("name", "?"); inp = tu.get("input", {}) or {}
    key = MAIN_ARG.get(name)
    val = inp.get(key) if key else None
    if val is None:
        val = json.dumps(inp, ensure_ascii=False)
    if not isinstance(val, str): val = json.dumps(val, ensure_ascii=False)
    first = val.strip().split("\n")[0]
    if len(first) > 150: first = first[:150] + "…"
    if name == "SendUserMessage":
        return "**Assistant (message sent mid-work):** " + inp.get("message", "")
    if name == "AskUserQuestion":
        out = ["**Assistant (questions asked):**"]
        for q in inp.get("questions", []):
            out.append("- " + q.get("question", ""))
            for o in q.get("options", []):
                out.append("  - " + o.get("label", "") + (": " + o["description"] if o.get("description") else ""))
        return "\n".join(out)
    return f"*[{name}: `{first}`]*" if key in ("command", "pattern", "query") else f"*[{name}: {first}]*"

def main():
    src, out, header = sys.argv[1:4]
    until = int(sys.argv[sys.argv.index("--until") + 1]) if "--until" in sys.argv else None
    recs = [json.loads(l) for l in open(src)]
    if until: recs = recs[:until]
    byid = {r.get("uuid"): r for r in recs if r.get("uuid")}
    # live chain: from the last record with a uuid, follow parentUuid
    last = [r for r in recs if r.get("uuid") and r.get("type") in ("user", "assistant")][-1]
    live = set(); r = last
    while r is not None:
        live.add(r["uuid"]); r = byid.get(r.get("parentUuid"))
    lines = [open(header).read().rstrip(), ""]
    user_texts, asst_texts, turn = [], [], 0
    tool_err = {}
    for r in recs:
        if r.get("uuid") not in live: continue
        m = r.get("message") or {}; c = m.get("content")
        if r["type"] == "user":
            if isinstance(c, str):
                t = strip_user(c)
                if "<task-notification>" in t[:400]:
                    lines += [notification(t), ""]; continue
                if t.startswith("*[the user interrupted"):
                    lines += [t, ""]; continue
                if t:
                    turn += 1; lines += [f"## Turn {turn} — {ts(r)}", "", "**User:** " + t, ""]; user_texts.append(t)
            else:
                for b in c or []:
                    if b.get("type") == "text":
                        t = strip_user(b["text"])
                        if t.startswith("<task-notification>") or "<task-notification>" in t[:400]:
                            lines += [notification(t), ""]; continue
                        if t.startswith("*[the user interrupted"):
                            lines += [t, ""]; continue
                        if t:
                            turn += 1; lines += [f"## Turn {turn} — {ts(r)}", "", "**User:** " + t, ""]; user_texts.append(t)
                    elif b.get("type") == "tool_result" and isinstance(r.get("toolUseResult"), dict) \
                            and "answers" in r["toolUseResult"] and not b.get("is_error"):
                        ans = r["toolUseResult"]["answers"]
                        t = "\n".join(f"- {q} → {a}" for q, a in ans.items())
                        turn += 1; lines += [f"## Turn {turn} — {ts(r)}", "", "**User (answers):**", t, ""]
                        user_texts.extend(ans.values())
                    elif b.get("type") == "tool_result" and b.get("is_error"):
                        cc = b.get("content"); e = cc if isinstance(cc, str) else " ".join(x.get("text", "") for x in cc or [])
                        e = e.strip().split("\n")[0][:200]
                        lines += [f"*[error: {e}]*", ""]
        elif r["type"] == "attachment" and (r.get("attachment") or {}).get("type") == "queued_command":
            p = r["attachment"].get("prompt")
            t = strip_user(p if isinstance(p, str) else "\n".join(x.get("text", "") for x in p or [] if isinstance(x, dict)))
            if "<task-notification>" in t[:400]:
                lines += [notification(t), ""]; continue
            if t:
                turn += 1; lines += [f"## Turn {turn} — {ts(r)} (sent mid-turn)", "", "**User:** " + t, ""]; user_texts.append(t)
        elif r["type"] == "assistant":
            for b in c or []:
                if b.get("type") == "text" and b["text"].strip():
                    lines += ["**Assistant:** " + b["text"].strip(), ""]; asst_texts.append(b["text"].strip())
                elif b.get("type") == "tool_use":
                    lines += [summary(b), ""]
    body = "\n".join(lines) + "\n"
    open(out, "w").write(body)
    # checks (print counts only)
    miss_u = sum(1 for t in user_texts if t not in body); miss_a = sum(1 for t in asst_texts if t not in body)
    overlap = 0; nthink = 0
    for r in recs:
        for b in ((r.get("message") or {}).get("content") or []) if isinstance((r.get("message") or {}).get("content"), list) else []:
            if b.get("type") in ("thinking", "redacted_thinking"):
                th = b.get("thinking") or ""
                if not th.strip(): continue
                nthink += 1
                for i in range(0, max(1, len(th) - 40), 20):
                    if th[i:i + 40] in body: overlap += 1; break
    print(f"turns={turn} user_texts={len(user_texts)} missing={miss_u} assistant_texts={len(asst_texts)} missing={miss_a} thinking_blocks={nthink} overlapping={overlap} bytes={len(body)}")

main()
