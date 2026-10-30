#!/usr/bin/env python3
"""Report size and filler in a text file (agent notes, comments, memory files).

Usage: terse_lint.py FILE [--max-tokens 400]
Exit 1 when the file is above the limit or has many filler phrases.
"""
import argparse
import re
import sys

FILLER = ["i think", "i believe", "it seems", "let me", "i will now", "i'll now", "certainly", "of course",
          "sure,", "please note", "it is important to", "in order to", "basically", "essentially", "just",
          "as you can see", "i hope this helps", "feel free to", "great question"]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument("file")
p.add_argument("--max-tokens", type=int, default=400)
a = p.parse_args()
text = open(a.file, encoding="utf-8", errors="replace").read()
low = text.lower()
tokens = len(text) // 4
hits = {f: len(re.findall(r"\b" + re.escape(f), low)) for f in FILLER}
hits = {k: v for k, v in hits.items() if v}
print(f"~{tokens} tokens (limit {a.max_tokens})")
for k, v in sorted(hits.items(), key=lambda kv: -kv[1]):
    print(f"filler: '{k}' x{v}")
bad = tokens > a.max_tokens or sum(hits.values()) >= 3
if tokens > a.max_tokens:
    print("too long: cut, move detail to a file or the wiki, or run /caveman-compress on it")
sys.exit(1 if bad else 0)
