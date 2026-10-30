#!/usr/bin/env python3
"""Build wiki page files for project requirements from requirement lines.

Input lines look like:  REQ-001: The system shall ... [status: accepted] [source: #12]
Writes markdown files to $MEM_DIR/wiki-out (default .mem/wiki-out):
  Requirements-Index.md (table), Requirements-Index-2.md ... when a page passes --max-chars,
  and with --by-prefix one page per prefix group (Requirements-FR.md).
The script does not talk to Gitea. Publish each file with the gitea-mcp wiki_write tool (see gitea-wiki).
"""
import argparse
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

REQ = re.compile(r"^\s*(?:[-*]\s*)?((?:[A-Z]{2,4})-?\d+)\s*[:.)-]\s*(.+?)\s*$")

p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
p.add_argument("files", nargs="+")
p.add_argument("--by-prefix", action="store_true")
p.add_argument("--max-chars", type=int, default=5000, help="split a page above this size (0 = never)")
p.add_argument("--out", default=os.path.join(os.environ.get("MEM_DIR", ".mem"), "wiki-out"))
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

HEAD = ["| ID | Requirement | Status | Source |", "| --- | --- | --- | --- |"]


def row(rid, v):
    return f"| {rid} | {v[0].replace('|', '/')} | {v[1]} | {v[2]} |"


def key(rid):
    m = re.match(r"([A-Z]+)-?(\d+)", rid)
    return (m.group(1), int(m.group(2)))


def page_name(base, n):
    return base if n == 1 else f"{base} {n}"


def build(base, purpose, items, total_note=""):
    """Split rows into pages of at most --max-chars. Returns {page title: text}."""
    chunks, cur, size = [], [], 0
    for rid, v in items:
        r = row(rid, v)
        if a.max_chars and cur and size + len(r) > a.max_chars:
            chunks.append(cur)
            cur, size = [], 0
        cur.append(r)
        size += len(r) + 1
    chunks.append(cur)
    pages = {}
    for n, chunk in enumerate(chunks, 1):
        nav = []
        if n > 1:
            nav.append(f"Previous: [[{page_name(base, n - 1)}]]")
        if n < len(chunks):
            nav.append(f"Next: [[{page_name(base, n + 1)}]]")
        text = f"Purpose: {purpose}\n\n" + "\n".join(HEAD + chunk) + "\n"
        if nav:
            text += "\n" + " | ".join(nav) + "\n"
        if n == len(chunks) and total_note:
            text += "\n" + total_note + "\n"
        pages[page_name(base, n)] = text
    return pages


ordered = sorted(rows.items(), key=lambda kv: key(kv[0]))
pages = build("Requirements Index", "all project requirements.", ordered, f"Total: {len(ordered)}")
if a.by_prefix:
    groups = defaultdict(list)
    for rid, v in ordered:
        groups[key(rid)[0]].append((rid, v))
    for prefix, items in groups.items():
        pages.update(build(f"Requirements {prefix}", f"{prefix} requirements.", items))

out = Path(a.out)
out.mkdir(parents=True, exist_ok=True)
for title, text in pages.items():
    path = out / (title.replace(" ", "-") + ".md")
    path.write_text(text, encoding="utf-8")
    print(f"{path}  title={title!r}  {len(text)} chars")
