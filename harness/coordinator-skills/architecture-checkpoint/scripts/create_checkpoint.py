#!/usr/bin/env python3
"""Create an 'Architecture checkpoint' issue for the Architect role, unless one is already open."""
import argparse
import json
import os
import subprocess
import sys
import tempfile

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
GITEA = os.environ.get("GITEA_CLI", os.path.join(infra, "harness/base-skills/gitea-issues/scripts/gitea.py"))
PREFIX = "Architecture checkpoint"

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--assignee", default=os.environ.get("WORKER_USER"))
p.add_argument("--focus", default="", help="extra area to look at")
a = p.parse_args()
if not a.assignee:
    sys.exit("error: set WORKER_USER or pass --assignee")

def gitea(*args):
    r = subprocess.run([sys.executable, GITEA, *args], capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr.strip())
    return r.stdout

for i in json.loads(gitea("list", "--state", "open", "--json")):
    if i["title"].startswith(PREFIX):
        print(f"checkpoint already open: #{i['number']}")
        sys.exit(0)

body = """Role: Architect

Goal: check the architectural status of the project and report drift.

Steps:
1. Run the `architecture-assessment` skill on the workspace.
2. Compare the result with the wiki pages `Architecture Overview` and the latest ADRs.
3. Write findings to the wiki page `Architecture Status` (use `architecture-wiki`).
4. Comment on this issue with: drift found, risks, recommended issues.

Done when: `Architecture Status` is updated and every finding has a severity.
"""
if a.focus:
    body += f"\nExtra focus: {a.focus}\n"
with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as fh:
    fh.write(body)
num = gitea("create", "--title", f"{PREFIX} {os.popen('date +%F').read().strip()}", "--body-file", fh.name,
            "--assignee", a.assignee, "--label", "status:todo", "--label", "role:architect").strip()
os.unlink(fh.name)
print(f"created checkpoint #{num}")
