#!/usr/bin/env python3
"""Print a markdown status report of project-01 issues; optionally publish it to the wiki.

Groups issues by status label, flags stalled and unassigned issues.
"""
import argparse
import datetime as dt
import json
import os
import subprocess
import sys

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
GITEA = os.environ.get("GITEA_CLI", os.path.join(infra, "harness/base-skills/gitea-issues/scripts/gitea.py"))
WIKI = os.environ.get("WIKI_CLI", os.path.join(infra, "harness/base-skills/gitea-wiki/scripts/wiki.py"))

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--stale-hours", type=float, default=24.0)
p.add_argument("--max-items", type=int, default=8, help="max issues listed per section")
p.add_argument("--wiki", metavar="PAGE", help="publish the report to this wiki page")
p.add_argument("--now", help="ISO time for testing")
a = p.parse_args()

r = subprocess.run([sys.executable, GITEA, "list", "--state", "all", "--json"], capture_output=True, text=True)
if r.returncode:
    sys.exit(r.stderr.strip())
issues = json.loads(r.stdout)
now = dt.datetime.fromisoformat(a.now.replace("Z", "+00:00")) if a.now else dt.datetime.now(dt.timezone.utc)

def status_of(i):
    for l in i.get("labels") or []:
        if l["name"].startswith("status:"):
            return l["name"][7:]
    return "closed" if i["state"] == "closed" else "no-status"

def who(i):
    return ",".join(x["login"] for x in i.get("assignees") or []) or "-"

groups = {}
stale, unassigned = [], []
for i in issues:
    st = status_of(i)
    groups.setdefault(st, []).append(i)
    if i["state"] == "open":
        if who(i) == "-":
            unassigned.append(i)
        if st in ("todo", "in-progress"):
            age = (now - dt.datetime.fromisoformat(i["updated_at"].replace("Z", "+00:00"))).total_seconds() / 3600
            if age > a.stale_hours:
                stale.append((i, age))

out = [f"# Project status ({now:%Y-%m-%d %H:%M} UTC)", "", "| Status | Count |", "| --- | ---: |"]
for st in ("todo", "in-progress", "blocked", "done", "closed", "no-status"):
    if st in groups:
        out.append(f"| {st} | {len(groups[st])} |")
for st in ("blocked", "in-progress", "todo"):
    if st in groups:
        out += ["", f"## {st}"] + [f"- #{i['number']} ({who(i)}) {i['title']}" for i in groups[st][:a.max_items]]
        if len(groups[st]) > a.max_items:
            out.append(f"- (+{len(groups[st]) - a.max_items} more)")
if stale:
    out += ["", f"## Stalled (no update for more than {a.stale_hours:g} h)"]
    out += [f"- #{i['number']} ({who(i)}) {i['title']} - {age:.0f} h" for i, age in stale]
if unassigned:
    out += ["", "## Open without assignee"] + [f"- #{i['number']} {i['title']}" for i in unassigned]
report = "\n".join(out) + "\n"
print(report)

if a.wiki:
    w = subprocess.run([sys.executable, WIKI, "put", a.wiki, "--file", "-", "--message", "status report"],
                       input=report, capture_output=True, text=True)
    if w.returncode:
        sys.exit(w.stderr.strip())
    print(w.stdout.strip())
