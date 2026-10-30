#!/usr/bin/env python3
"""Check that a UI spec has all required sections and no leftover placeholders."""
import re
import sys

REQUIRED = ["Purpose", "Users", "Screens", "Flows", "States", "Accessibility", "Open questions"]
if len(sys.argv) != 2:
    sys.exit("usage: check_ui_spec.py spec.md")
text = open(sys.argv[1], encoding="utf-8").read()
problems = []
for sec in REQUIRED:
    m = re.search(rf"^##\s+{re.escape(sec)}\s*$(.*?)(?=^##\s|\Z)", text, re.M | re.S)
    if not m:
        problems.append(f"missing section: {sec}")
    elif not m.group(1).strip():
        problems.append(f"empty section: {sec}")
for m in re.finditer(r"<[^>\n]{3,80}>", text):
    problems.append(f"placeholder left: {m.group(0)}")
for p in problems:
    print("PROBLEM", p)
print("OK" if not problems else f"{len(problems)} problem(s)")
sys.exit(1 if problems else 0)
