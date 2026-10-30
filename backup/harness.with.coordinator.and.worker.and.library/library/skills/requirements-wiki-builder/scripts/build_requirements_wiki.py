#!/usr/bin/env python3
"""Build wiki pages for project requirements from requirement lines.

Input lines look like:  REQ-001: The system shall ... [status: accepted] [source: #12]
Creates/updates the wiki page 'Requirements Index' (table) and, with --by-prefix,
one page per prefix group (e.g. 'Requirements FR').
"""
import argparse
import os
import re
import subprocess
import sys
from collections import defaultdict

infra = os.environ.get("RUST_AGENT_INFRA_DIR", "")
WIKI = os.environ.get("WIKI_CLI", os.path.join(infra, "harness/base-skills/gitea-wiki/scripts/wiki.py"))
REQ = re.compile(r"^\s*(?:[-*]\s*)?((?:[A-Z]{2,4})-?\d+)\s*[:.)-]\s*(.+?)\s*$")

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("files", nargs="+")
p.add_argument("--by-prefix", action="store_true")
p.add_argument("--dry-run", action="store_true")
a = p.parse_args()

rows = {}
for f in a.files:
    for line in open(f, encoding="utf-8"):
        m = REQ.match(line)
        if not m:
            continue
        rid, text = m.group(1), m.group(2)
        status = re.search(r"\[status:\s*([^\]]+)\]", text)
        source = re.search(r"\[source:\s*([^\]]+)\]", text)
        clean = re.sub(r"\s*\[(?:status|source):[^\]]*\]", "", text)
        if rid in rows and rows[rid][0] != clean:
            print(f"warning: {rid} defined twice with different text", file=sys.stderr)
        rows[rid] = (clean, status.group(1) if status else "draft", source.group(1) if source else "-")
if not rows:
    sys.exit("error: no requirement lines found (expected 'REQ-001: text')")

def table(items):
    out = ["| ID | Requirement | Status | Source |", "| --- | --- | --- | --- |"]
    for rid, (text, st, src) in items:
        out.append(f"| {rid} | {text.replace('|', '/')} | {st} | {src} |")
    return "\n".join(out)

def key(rid):
    m = re.match(r"([A-Z]+)-?(\d+)", rid)
    return (m.group(1), int(m.group(2)))

ordered = sorted(rows.items(), key=lambda kv: key(kv[0]))
pages = {"Requirements Index": "Purpose: all project requirements.\n\n" + table(ordered) + f"\n\nTotal: {len(ordered)}\n"}
if a.by_prefix:
    groups = defaultdict(list)
    for rid, v in ordered:
        groups[key(rid)[0]].append((rid, v))
    for prefix, items in groups.items():
        pages[f"Requirements {prefix}"] = f"Purpose: {prefix} requirements.\n\n" + table(items) + "\n"

for name, text in pages.items():
    if a.dry_run:
        print(f"=== {name}\n{text}")
        continue
    r = subprocess.run([sys.executable, WIKI, "put", name, "--file", "-", "--message", "requirements update"],
                       input=text, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr.strip())
    print(r.stdout.strip())
