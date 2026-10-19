#!/usr/bin/env python3
"""Ask the Human a question on an issue: comment, set status:blocked, assign to $HUMAN_USER."""
import argparse
import os
import subprocess
import sys

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
GITEA = os.environ.get("GITEA_CLI", os.path.join(infra, "harness/base-skills/gitea-issues/scripts/gitea.py"))

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("issue", type=int)
p.add_argument("--question", required=True)
p.add_argument("--context", default="", help="why the decision is needed")
p.add_argument("--option", action="append", default=[], help="answer option (repeatable)")
p.add_argument("--recommend", default="", help="letter of the recommended option, e.g. B")
p.add_argument("--human", default=os.environ.get("HUMAN_USER"))
a = p.parse_args()
if not a.human:
    sys.exit("error: set HUMAN_USER or pass --human")

lines = ["**Decision needed from Human**", "", f"**Question:** {a.question}", ""]
if a.context:
    lines += [f"**Why it matters:** {a.context}", ""]
if a.option:
    lines.append("**Options:**")
    for i, opt in enumerate(a.option):
        lines.append(f"- **{chr(65 + i)}**: {opt}")
    lines.append("")
if a.recommend:
    lines += [f"**Recommendation:** option {a.recommend}", ""]
lines.append("Reply on this issue and assign it back to the Coordinator. The work is paused until then.")
body = "\n".join(lines)

def run(*args, stdin=None):
    r = subprocess.run([sys.executable, GITEA, *args], input=stdin, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr.strip())
    print(r.stdout.strip())

run("comment", str(a.issue), "--body-file", "-", stdin=body)
run("status", str(a.issue), "blocked")
run("assign", str(a.issue), a.human)
