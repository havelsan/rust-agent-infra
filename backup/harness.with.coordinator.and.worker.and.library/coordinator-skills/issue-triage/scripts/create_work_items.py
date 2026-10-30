#!/usr/bin/env python3
"""Create Worker issues from a JSON plan.

Plan format (list):
  [{"title": "...", "role": "Analyzer", "body": "...", "parent": 1}, ...]
Each issue gets 'Role: <role>' as its first line, label status:todo and role:<role>,
and is assigned to $WORKER_USER (override with --assignee).
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

ROLES = {"analyzer", "researcher", "architect", "developer", "designer", "reviewer", "tester", "qa"}
infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
GITEA = os.environ.get("GITEA_CLI", os.path.join(infra, "harness/base-skills/gitea-issues/scripts/gitea.py"))

p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
p.add_argument("plan", help="JSON file")
p.add_argument("--assignee", default=os.environ.get("WORKER_USER"))
p.add_argument("--dry-run", action="store_true")
a = p.parse_args()
if not a.assignee:
    sys.exit("error: set WORKER_USER or pass --assignee")

items = json.load(open(a.plan, encoding="utf-8"))
for n, it in enumerate(items, 1):
    role = it.get("role", "")
    if role.lower() not in ROLES:
        sys.exit(f"error: item {n} has unknown role '{role}'. Valid: {sorted(ROLES)}")
    lines = [f"Role: {role.capitalize() if role.lower() != 'qa' else 'Qa'}"]
    if it.get("parent"):
        lines.append(f"Parent: #{it['parent']}")
    lines += ["", it.get("body", "").strip()]
    body = "\n".join(lines) + "\n"
    if a.dry_run:
        print(f"--- {it['title']}\n{body}")
        continue
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as fh:
        fh.write(body)
    out = subprocess.run(
        [sys.executable, GITEA, "create", "--title", it["title"], "--body-file", fh.name,
         "--assignee", a.assignee, "--label", "status:todo", "--label", "role:" + role.lower()],
        capture_output=True, text=True)
    os.unlink(fh.name)
    if out.returncode:
        sys.exit(out.stderr.strip())
    print(f"#{out.stdout.strip()} {role}: {it['title']}")
