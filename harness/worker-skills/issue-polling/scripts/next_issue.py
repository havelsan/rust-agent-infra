#!/usr/bin/env python3
"""Print the next issue for this Worker as JSON, or exit 1 when there is none.

Picks the oldest open issue assigned to the Worker whose status label is todo
(or missing). Issues labelled status:blocked or status:done are skipped.
Use --wait to poll until one appears.
"""
import argparse
import json
import os
import subprocess
import sys
import time

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
GITEA = os.environ.get("GITEA_CLI", os.path.join(infra, "harness/base-skills/gitea-issues/scripts/gitea.py"))

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--assignee", default=os.environ.get("WORKER_USER"))
p.add_argument("--wait", type=int, metavar="SECONDS", help="poll interval; 0 or omitted = check once")
p.add_argument("--max-body", type=int, default=3000, help="cut the issue body here")
p.add_argument("--timeout", type=int, default=0, help="stop waiting after this many seconds (0 = never)")
a = p.parse_args()

def gitea(*args):
    r = subprocess.run([sys.executable, GITEA, *args], capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr.strip())
    return r.stdout.strip()

me = a.assignee or gitea("whoami")

def find():
    issues = json.loads(gitea("list", "--state", "open", "--assignee", me, "--json"))
    open_work = []
    for i in sorted(issues, key=lambda x: x["number"]):
        labels = {l["name"] for l in i.get("labels") or []}
        if labels & {"status:blocked", "status:done"}:
            continue
        open_work.append((0 if "status:in-progress" in labels else 1, i))
    # An in-progress issue means an earlier session was interrupted: resume it first.
    open_work.sort(key=lambda t: t[0])
    return open_work[0][1] if open_work else None


start = time.time()
while True:
    issue = find()
    if issue:
        print(json.dumps({"number": issue["number"], "title": issue["title"], "body": (issue.get("body") or "")[:a.max_body],
                          "labels": [l["name"] for l in issue.get("labels") or []]}, indent=2))
        sys.exit(0)
    if not a.wait:
        sys.exit(1)
    if a.timeout and time.time() - start > a.timeout:
        sys.exit(1)
    time.sleep(a.wait)
