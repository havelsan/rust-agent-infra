#!/usr/bin/env python3
"""Find the 'Role: <name>' line of an issue and print the matching role file.

Role files are searched in $RUST_AGENT_INFRA_DIR/harness/library/roles as <name>.md,
<name>/ROLE.md or <name>/SKILL.md (case-insensitive).
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
GITEA = os.environ.get("GITEA_CLI", os.path.join(infra, "harness/base-skills/gitea-issues/scripts/gitea.py"))
ROLES_DIR = Path(os.environ.get("ROLES_DIR", os.path.join(infra, "harness/library/roles")))

p = argparse.ArgumentParser(description=__doc__)
g = p.add_mutually_exclusive_group(required=True)
g.add_argument("--issue", type=int)
g.add_argument("--body-file")
p.add_argument("--name-only", action="store_true", help="print only the role name")
p.add_argument("--max-chars", type=int, default=6000, help="cut the role file here (0 = no cut)")
a = p.parse_args()

labels = []
if a.issue:
    r = subprocess.run([sys.executable, GITEA, "get", str(a.issue)], capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr.strip())
    issue = json.loads(r.stdout)
    body = issue.get("body") or ""
    labels = [l["name"] for l in issue.get("labels") or []]
else:
    body = Path(a.body_file).read_text(encoding="utf-8")

m = re.search(r"(?im)^\s*role\s*:\s*([A-Za-z][\w-]*)\s*$", body)
role = m.group(1) if m else next((l[5:] for l in labels if l.startswith("role:")), None)
if not role:
    sys.exit("error: no 'Role: <name>' line and no role:* label. Return the issue to the Coordinator.")
if a.name_only:
    print(role)
    sys.exit(0)

wanted = role.lower()
found = None
if ROLES_DIR.is_dir():
    for entry in sorted(ROLES_DIR.iterdir()):
        stem = entry.stem.lower() if entry.is_file() else entry.name.lower()
        if stem == wanted:
            found = entry if entry.is_file() else next(
                (entry / n for n in ("ROLE.md", "SKILL.md", "README.md") if (entry / n).exists()), None)
            break
if not found:
    available = sorted(e.stem if e.is_file() else e.name for e in ROLES_DIR.iterdir()) if ROLES_DIR.is_dir() else []
    sys.exit(f"error: role '{role}' not found in {ROLES_DIR}. Available: {available}")
print(f"# ROLE: {role}  (from {found})\n")
role_text = found.read_text(encoding="utf-8")
if a.max_chars and len(role_text) > a.max_chars:
    print(role_text[:a.max_chars])
    print(f"\n[role file cut at {a.max_chars} chars. Read the rest with: mem.py slice {found} 2]")
else:
    print(role_text)
