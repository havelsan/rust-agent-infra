#!/usr/bin/env python3
"""mem.py - layered memory and step tracker for small-context agents (standard library only).

L1 local : $MEM_DIR/<issue>/state.json + notes.md   (default MEM_DIR=.mem)
L2 remote: checkpoint comment on the Gitea issue    (checkpoint prints it, the agent posts it with the gitea-mcp
                                                     issue_write tool; restore reads it back from stdin)

Typical use:  start -> plan -> (next -> done)* -> clear
"""
import argparse
import json
import os
import re
import shutil
import signal
import sys
import time
from pathlib import Path

MEM_DIR = Path(os.environ.get("MEM_DIR", ".mem"))
CTX = int(os.environ.get("MEM_CONTEXT_TOKENS", "32000"))
MAX_STEPS, STEP_CHARS, SUM_CHARS, NOTE_CHARS, NOTES_CAP = 8, 160, 240, 300, 3000
MARK = "<!-- agent-checkpoint -->"
STATE_RE = re.compile(r"<!-- agent-state: (\{.*?\}) -->", re.S)


signal.signal(signal.SIGPIPE, signal.SIG_DFL)


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def idir(issue):
    return MEM_DIR / str(issue)


def load(issue):
    p = idir(issue) / "state.json"
    if not p.exists():
        die(f'no memory for issue {issue}. Run: mem.py start {issue} --goal "..."')
    return json.loads(p.read_text(encoding="utf-8"))


def save(s):
    d = idir(s["issue"])
    d.mkdir(parents=True, exist_ok=True)
    s["updated"] = int(time.time())
    (d / "state.json").write_text(json.dumps(s, ensure_ascii=False, indent=1), encoding="utf-8")


def clip(text, n):
    text = " ".join(str(text).split())
    return text if len(text) <= n else text[: n - 1] + "…"


def step_of(s, sid):
    for x in s["steps"]:
        if x["id"] == sid:
            return x
    die(f"no step {sid}")


def current(s):
    for st in ("doing", "pending"):
        for x in s["steps"]:
            if x["status"] == st:
                return x
    return None


def notes_file(issue):
    return idir(issue) / "notes.md"


def recall_text(s, max_chars):
    done = [x for x in s["steps"] if x["status"] == "done"]
    cur = current(s)
    todo = [x for x in s["steps"] if x["status"] == "pending" and x is not cur]
    nf = notes_file(s["issue"])
    notes = ""
    if nf.exists():
        lines = [l[2:] for l in nf.read_text(encoding="utf-8").splitlines() if l.startswith("- ")]
        notes = " ; ".join(lines)[-600:]

    def build(sumlen):
        out = [f"ISSUE #{s['issue']} GOAL: {s['goal']}"]
        if done:
            out.append("DONE: " + " | ".join(f"{x['id']} {clip(x['summary'], sumlen)}" for x in done))
        if cur:
            extra = f" (attempt {cur['attempts'] + 1})" if cur["attempts"] else ""
            out.append(f"NOW: {cur['id']} {cur['text']}{extra}")
        else:
            out.append("NO OPEN STEPS")
        if todo:
            out.append("TODO: " + " | ".join(f"{x['id']} {x['text']}" for x in todo))
        if notes:
            out.append("NOTES: " + notes)
        return "\n".join(out)

    text = ""
    for n in (SUM_CHARS, 120, 60, 30):
        text = build(n)
        if len(text) <= max_chars:
            return text
    return text[:max_chars]


def parse_state(text):
    """Find the newest agent-state JSON in checkpoint comment text."""
    found = None
    for m in STATE_RE.finditer(text):
        found = m.group(1)
    return json.loads(found) if found else None


def cmd_restore(a):
    s = parse_state(sys.stdin.read())
    if not s:
        die("no '<!-- agent-state: {...} -->' found on stdin")
    s["issue"] = a.issue
    save(s)
    print(f"restored #{a.issue} from checkpoint text")
    print(recall_text(s, a.max_chars))


def cmd_start(a):
    if not (idir(a.issue) / "state.json").exists():
        save({"issue": a.issue, "goal": clip(a.goal or "see issue", 200), "steps": [], "created": int(time.time())})
        print(f"(new) workspace lost? restore the last '[Agent] checkpoint' comment: mem.py restore {a.issue}")
    print(recall_text(load(a.issue), a.max_chars))


def cmd_plan(a):
    s = load(a.issue)
    if s["steps"] and not a.replace:
        die("a plan exists. Use 'split' for a big step, or --replace to start over")
    if not 1 <= len(a.steps) <= MAX_STEPS:
        die(f"give 1 to {MAX_STEPS} steps. Plan phases first, split a phase when you reach it")
    for t in a.steps:
        if len(t) > STEP_CHARS:
            die(f"step too long ({len(t)} > {STEP_CHARS} chars). One step = one concern: {t[:50]}...")
    s["steps"] = [{"id": str(i), "text": t, "status": "pending", "attempts": 0, "summary": ""}
                  for i, t in enumerate(a.steps, 1)]
    save(s)
    print(f"planned {len(a.steps)} step(s). Next: mem.py next {a.issue}")


def cmd_next(a):
    s = load(a.issue)
    cur = current(s)
    if not cur:
        print("ALL STEPS DONE. Finish with issue-completion.")
        return
    cur["status"] = "doing"
    save(s)
    open_n = sum(1 for x in s["steps"] if x["status"] in ("pending", "doing"))
    print(f"STEP {cur['id']} ({open_n} open): {cur['text']}")
    if cur["attempts"]:
        print(f"previous attempt failed: {cur['summary']}")


def cmd_done(a):
    s = load(a.issue)
    x = step_of(s, a.step) if a.step else current(s)
    if not x:
        die("no current step")
    if len(a.summary) > SUM_CHARS:
        print(f"note: summary cut to {SUM_CHARS} chars. Put details in a file or the wiki.", file=sys.stderr)
    x["status"], x["summary"] = "done", clip(a.summary, SUM_CHARS)
    save(s)
    print("step %s done. %s" % (x["id"], "ALL STEPS DONE." if not current(s) else f"Next: mem.py next {a.issue}"))


def cmd_fail(a):
    s = load(a.issue)
    x = step_of(s, a.step) if a.step else current(s)
    if not x:
        die("no current step")
    x["attempts"] += 1
    x["status"], x["summary"] = "pending", clip("FAILED: " + a.reason, SUM_CHARS)
    save(s)
    if x["attempts"] >= 2:
        print(f"SPLIT: step {x['id']} failed {x['attempts']}x. Run: mem.py split {a.issue} {x['id']} \"sub1\" \"sub2\" "
              "or return the issue as blocked if information is missing.")
    else:
        print("recorded. Retry once with a smaller change, or split.")


def cmd_split(a):
    s = load(a.issue)
    x = step_of(s, a.step)
    if not 2 <= len(a.sub) <= 4:
        die("split into 2 to 4 sub-steps")
    if x["id"].count(".") >= 2:
        die("already split twice. Return the issue as blocked and ask the Coordinator to re-scope")
    for t in a.sub:
        if len(t) > STEP_CHARS:
            die(f"sub-step too long: {t[:50]}...")
    idx = s["steps"].index(x)
    x["status"] = "split"
    kids = [{"id": f"{x['id']}.{i}", "text": t, "status": "pending", "attempts": 0, "summary": ""}
            for i, t in enumerate(a.sub, 1)]
    s["steps"][idx + 1:idx + 1] = kids
    save(s)
    print(f"step {x['id']} split into {len(kids)}. Next: mem.py next {a.issue}")


def cmd_note(a):
    d = idir(a.issue)
    if not d.exists():
        die("no memory for this issue. Run start first")
    nf = notes_file(a.issue)
    lines = nf.read_text(encoding="utf-8").splitlines() if nf.exists() else []
    lines.append("- " + clip(a.text, NOTE_CHARS))
    dropped = 0
    while len("\n".join(lines)) > NOTES_CAP and len(lines) > 1:
        lines.pop(0)
        dropped += 1
    nf.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("noted" + (f" ({dropped} oldest note(s) dropped; keep facts in the wiki)" if dropped else ""))


def cmd_recall(a):
    print(recall_text(load(a.issue), a.max_chars))


def cmd_checkpoint(a):
    """Print the checkpoint comment. The agent posts it: issue_write method=add_comment."""
    s = load(a.issue)
    state = json.dumps(s, ensure_ascii=False, separators=(",", ":")).replace("-->", "--\\u003e")
    body = (f"[{a.agent}] checkpoint\n{MARK}\n**Checkpoint (agent memory L2)**\n\n{recall_text(s, a.max_chars)}\n\n"
            f"<!-- agent-state: {state} -->\n")
    (idir(a.issue) / "checkpoint.md").write_text(body, encoding="utf-8")
    print(body)
    print(f"[post the text above as a comment on #{a.issue}: issue_write method=add_comment]", file=sys.stderr)


def cmd_clear(a):
    shutil.rmtree(idir(a.issue), ignore_errors=True)
    print(f"cleared local memory of #{a.issue}")


def cmd_budget(a):
    total = a.used or 0
    for f in a.files:
        p = Path(f)
        if not p.is_file():
            print(f"missing {f}")
            continue
        t = len(p.read_text(encoding="utf-8", errors="replace")) // 4
        total += t
        print(f"{t:6d} tokens  {f}")
    pct = 100 * total / CTX
    verdict = "OK" if pct < 50 else ("WARN: finish this step, then checkpoint" if pct < 75
                                      else "RESET: checkpoint now, then /reset, then mem.py start")
    print(f"total ~{total} of {CTX} tokens ({pct:.0f}%): {verdict}")
    sys.exit(0 if pct < 75 else 2)


def cmd_slice(a):
    text = Path(a.file).read_text(encoding="utf-8", errors="replace")
    parts, cur = [], ""
    for line in text.splitlines(keepends=True):
        if len(cur) + len(line) > a.chars and cur:
            parts.append(cur)
            cur = ""
        cur += line
    if cur:
        parts.append(cur)
    if not 1 <= a.part <= max(len(parts), 1):
        die(f"part must be 1..{len(parts)}")
    print(f"[{a.file} part {a.part}/{len(parts)}]")
    print(parts[a.part - 1] if parts else "")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    def add(name, fn, issue=True):
        s = sub.add_parser(name)
        if issue:
            s.add_argument("issue", type=int)
        s.set_defaults(fn=fn)
        return s

    s = add("start", cmd_start); s.add_argument("--goal"); s.add_argument("--max-chars", type=int, default=2500)
    s = add("plan", cmd_plan); s.add_argument("steps", nargs="+"); s.add_argument("--replace", action="store_true")
    add("next", cmd_next)
    s = add("done", cmd_done); s.add_argument("summary"); s.add_argument("--step")
    s = add("fail", cmd_fail); s.add_argument("reason"); s.add_argument("--step")
    s = add("split", cmd_split); s.add_argument("step"); s.add_argument("sub", nargs="+")
    s = add("note", cmd_note); s.add_argument("text")
    s = add("recall", cmd_recall); s.add_argument("--max-chars", type=int, default=2500)
    s = add("checkpoint", cmd_checkpoint); s.add_argument("--max-chars", type=int, default=1200)
    s.add_argument("--agent", default=os.environ.get("AGENT_NAME", "agent"), help="your role name, e.g. Developer")
    s = add("restore", cmd_restore); s.add_argument("--max-chars", type=int, default=2500)
    add("clear", cmd_clear)
    s = add("budget", cmd_budget, issue=False); s.add_argument("files", nargs="*"); s.add_argument("--used", type=int, help="tokens already used, from the UI")
    s = add("slice", cmd_slice, issue=False); s.add_argument("file"); s.add_argument("part", type=int); s.add_argument("--chars", type=int, default=6000)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
