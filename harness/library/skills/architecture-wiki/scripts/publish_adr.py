#!/usr/bin/env python3
"""Publish an Architecture Decision Record to the wiki and update the 'ADR Index' page."""
import argparse
import datetime
import os
import re
import subprocess
import sys

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
WIKI = os.environ.get("WIKI_CLI", os.path.join(infra, "harness/base-skills/gitea-wiki/scripts/wiki.py"))

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--title", required=True)
p.add_argument("--context", required=True, help="the problem and forces")
p.add_argument("--decision", required=True)
p.add_argument("--consequences", required=True)
p.add_argument("--alternatives", default="")
p.add_argument("--status", default="proposed", choices=["proposed", "accepted", "superseded", "rejected"])
p.add_argument("--issue", type=int, help="related issue number")
p.add_argument("--dry-run", action="store_true")
a = p.parse_args()

def wiki(*args, stdin=None, check=True):
    r = subprocess.run([sys.executable, WIKI, *args], input=stdin, capture_output=True, text=True)
    if r.returncode and check:
        sys.exit(r.stderr.strip())
    return r

listing = wiki("list", check=not a.dry_run)
if listing.returncode:
    print("note: wiki not reachable in dry-run; numbering starts at 1", file=sys.stderr)
pages = listing.stdout.split()
nums = [int(m.group(1)) for t in pages if (m := re.match(r"ADR-(\d+)", t))]
number = max(nums, default=0) + 1
slug = re.sub(r"[^A-Za-z0-9]+", "-", a.title).strip("-")
page = f"ADR-{number:03d}-{slug}"

text = f"""# ADR-{number:03d}: {a.title}

- Status: {a.status}
- Date: {datetime.date.today().isoformat()}
- Related issue: {('#' + str(a.issue)) if a.issue else '-'}

## Context
{a.context}

## Decision
{a.decision}

## Consequences
{a.consequences}
"""
if a.alternatives:
    text += f"\n## Alternatives considered\n{a.alternatives}\n"

if a.dry_run:
    print(f"=== {page}\n{text}")
    sys.exit(0)

wiki("put", page, "--file", "-", "--message", f"ADR {number:03d}", stdin=text)
idx = wiki("get", "ADR Index", check=False)
index = idx.stdout.rstrip("\n") if idx.returncode == 0 else "# ADR Index\n"
index += f"\n- [[{page}]] - {a.title} ({a.status})\n"
wiki("put", "ADR Index", "--file", "-", "--message", f"index ADR {number:03d}", stdin=index)
print(f"published {page}")
