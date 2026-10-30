#!/usr/bin/env python3
"""Finish a Worker issue: post the standard comment, set the status label, hand back to the Coordinator."""
import argparse
import os
import subprocess
import sys

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
GITEA = os.environ.get("GITEA_CLI", os.path.join(infra, "harness/base-skills/gitea-issues/scripts/gitea.py"))
FORMAT = os.environ.get("FORMAT_CLI", os.path.join(infra, "harness/base-skills/issue-comment-protocol/scripts/format_comment.py"))

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("issue", type=int)
p.add_argument("--role", required=True)
p.add_argument("--status", default="done", choices=["done", "blocked"])
p.add_argument("--done", required=True, help="what was done")
p.add_argument("--result", default="")
p.add_argument("--changed", action="append", default=[])
p.add_argument("--next", dest="next_step", default="")
p.add_argument("--handoff", default=os.environ.get("COORDINATOR_USER"), help="assignee after finishing")
p.add_argument("--keep-memory", action="store_true", help="do not clear .mem/<issue> after done")
p.add_argument("--close", action="store_true", help="also close the issue (default: leave to Coordinator)")
a = p.parse_args()

def run(cmd, stdin=None):
    r = subprocess.run(cmd, input=stdin, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr.strip())
    return r.stdout

cmd = [sys.executable, FORMAT, "--role", a.role, "--status", a.status, "--done", a.done]
if a.result:
    cmd += ["--result", a.result]
for c in a.changed:
    cmd += ["--changed", c]
if a.next_step:
    cmd += ["--next", a.next_step]
comment = run(cmd)

g = [sys.executable, GITEA]
run(g + ["comment", str(a.issue), "--body-file", "-"], stdin=comment)
run(g + ["status", str(a.issue), a.status])
if a.handoff:
    run(g + ["assign", str(a.issue), a.handoff])
if a.close and a.status == "done":
    run(g + ["state", str(a.issue), "closed"])
MEM = os.environ.get("MEM_CLI", os.path.join(infra, "harness/base-skills/agent-memory/scripts/mem.py"))
if a.status == "done" and not a.keep_memory and os.path.exists(MEM):
    subprocess.run([sys.executable, MEM, "clear", str(a.issue)], capture_output=True)
print(f"#{a.issue}: {a.status}" + (f", assigned to {a.handoff}" if a.handoff else "") + (", closed" if a.close and a.status == "done" else ""))
