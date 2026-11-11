#!/usr/bin/env python3
"""Heuristic lint for requirement text (markdown or plain text).

Finds: vague words, TBD markers, missing 'shall', long sentences, passive voice,
duplicate requirements, and possible contradictions (shall vs shall not).
It is a first pass. Consistency, entailment, and satisfiability need human-level reading.
"""
import argparse
import re
import sys
from collections import defaultdict

VAGUE = ["fast", "quickly", "easy", "easily", "user-friendly", "appropriate", "as needed", "etc", "and/or",
         "some", "several", "approximately", "reasonable", "robust", "flexible", "efficient", "minimal",
         "maximize", "minimize", "if possible", "as soon as possible", "adequate", "normal", "typical",
         "sufficient", "support", "handle"]
PASSIVE = re.compile(r"\b(is|are|was|were|be|been|being)\s+\w+ed\b", re.I)
REQ_LINE = re.compile(r"^\s*(?:[-*]\s*)?((?:REQ|SRS|FR|NFR)-?\d+)\s*[:.)-]\s*(.+)$", re.I)

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("file", help="text or markdown file, or - for stdin")
p.add_argument("--max-findings", type=int, default=40, help="print at most this many findings")
p.add_argument("--max-words", type=int, default=25, help="sentence length limit (ASD-STE100: 20 procedures, 25 descriptions)")
a = p.parse_args()
lines = (sys.stdin if a.file == "-" else open(a.file, encoding="utf-8")).read().splitlines()

findings = []
def add(n, cat, sev, msg):
    findings.append((n, cat, sev, msg))

reqs = {}
norm_seen = defaultdict(list)
for n, line in enumerate(lines, 1):
    low = line.lower()
    for w in VAGUE:
        if re.search(r"\b" + re.escape(w) + r"\b", low):
            add(n, "ambiguity", "medium", f"vague term '{w}'")
    if re.search(r"\b(tbd|tbc|to be defined|to be decided|\?\?)\b", low):
        add(n, "completeness", "high", "open item (TBD/TBC)")
    for s in re.split(r"(?<=[.!?])\s+", line):
        wc = len(s.split())
        if wc > a.max_words:
            add(n, "clarity", "low", f"sentence has {wc} words (limit {a.max_words})")
    if PASSIVE.search(line):
        add(n, "clarity", "low", "possible passive voice; name the actor")
    m = REQ_LINE.match(line)
    if m:
        rid, text = m.group(1).upper(), m.group(2).strip()
        reqs[rid] = (n, text)
        if not re.search(r"\b(shall|must)\b", text, re.I):
            add(n, "completeness", "medium", f"{rid} has no 'shall' or 'must'")
        key = re.sub(r"[^a-z0-9 ]", "", text.lower())
        key = re.sub(r"\s+", " ", key)
        norm_seen[key].append(rid)

for key, ids in norm_seen.items():
    if len(ids) > 1:
        add(reqs[ids[1]][0], "redundancy", "medium", f"{', '.join(ids)} have the same text")

pos = {}
for rid, (n, text) in reqs.items():
    t = re.sub(r"\s+", " ", text.lower())
    if re.search(r"\bshall not\b|\bmust not\b", t):
        base = re.sub(r"\b(shall|must) not\b", "SHALL", t)
    else:
        base = re.sub(r"\b(shall|must)\b", "SHALL", t)
    neg = bool(re.search(r"\b(shall|must) not\b", t))
    pos.setdefault(base, []).append((rid, neg, n))
for base, items in pos.items():
    if len({neg for _, neg, _ in items}) > 1:
        ids = ", ".join(r for r, _, _ in items)
        add(items[0][2], "contradiction", "high", f"possible contradiction (shall vs shall not): {ids}")

findings.sort()
order = {"high": 0, "medium": 1, "low": 2}
findings.sort(key=lambda f: (order[f[2]], f[0]))
for n, cat, sev, msg in findings[:a.max_findings]:
    print(f"line {n}: [{sev}] {cat}: {msg}")
if len(findings) > a.max_findings:
    print(f"(+{len(findings) - a.max_findings} lower-severity findings not shown; use --max-findings)")
counts = defaultdict(int)
for _, _, sev, _ in findings:
    counts[sev] += 1
print(f"\n{len(findings)} finding(s): high={counts['high']} medium={counts['medium']} low={counts['low']}; "
      f"{len(reqs)} requirement line(s) recognised")
sys.exit(1 if counts["high"] else 0)
