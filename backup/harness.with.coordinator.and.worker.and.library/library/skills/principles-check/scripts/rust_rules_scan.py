#!/usr/bin/env python3
"""Heuristic scan of Rust code for NASA-style rule violations.

Usage: rust_rules_scan.py [PATH ...] [--max-fn-lines 60] [--strict]
Skips tests/, benches/, target/, and everything after '#[cfg(test)]' in a file.
Exit code 1 with --strict when findings exist.
"""
import argparse
import os
import re
import sys

TOKEN = re.compile(r'//[^\n]*|/\*.*?\*/|r(#*)".*?"\1|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\\\'])\'', re.S)
FN = re.compile(r"\bfn\s+([A-Za-z_]\w*)")
SKIP_DIRS = {"target", "tests", "benches", ".git", "node_modules"}

def blank(m):
    return re.sub(r"[^\n]", " ", m.group(0))

def files(paths):
    for p in paths:
        if os.path.isfile(p) and p.endswith(".rs"):
            yield p
        for root, dirs, names in os.walk(p):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            for n in names:
                if n.endswith(".rs"):
                    yield os.path.join(root, n)

def body_end(text, start):
    depth = 0
    for i in range(start, len(text)):
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i
    return len(text) - 1

def scan(path, max_lines):
    raw = open(path, encoding="utf-8", errors="replace").read()
    text = TOKEN.sub(blank, raw)
    cut = text.find("#[cfg(test)]")
    if cut != -1:
        text = text[:cut]
    line_of = lambda idx: text.count("\n", 0, idx) + 1
    out = []
    for m in FN.finditer(text):
        name = m.group(1)
        brace = text.find("{", m.end())
        semi = text.find(";", m.end())
        if brace == -1 or (semi != -1 and semi < brace):
            continue
        end = body_end(text, brace)
        body = text[brace:end + 1]
        n_lines = body.count("\n") + 1
        if n_lines > max_lines:
            out.append((line_of(m.start()), "N4", f"fn {name} has {n_lines} lines (limit {max_lines})"))
        if re.search(r"(?<![\w.])" + re.escape(name) + r"\s*\(", body[1:]):
            out.append((line_of(m.start()), "N1", f"fn {name} may call itself (recursion)"))
        for lm in re.finditer(r"\bloop\s*\{|\bwhile\s+true\b", body):
            seg = body[lm.start():lm.start() + 1500]
            if not re.search(r"\b(break|return)\b|\?", seg):
                out.append((line_of(brace + lm.start()), "N2", f"unbounded loop in fn {name} without break/return"))
    for rx, code, msg in [
        (r"\.unwrap\(\)", "N7", "unwrap() can panic; return a Result"),
        (r"\.expect\(", "N7", "expect() can panic; return a Result"),
        (r"\bpanic!\s*\(", "N7", "panic! in library code"),
        (r"\btodo!\s*\(|\bunimplemented!\s*\(", "N7", "todo!/unimplemented! left in code"),
        (r"\bunsafe\b", "N9", "unsafe code; needs a written safety argument"),
        (r"#!?\[allow\(", "N10", "allow(...) hides a warning"),
        (r"\bstatic\s+mut\b", "N10", "static mut: global mutable state"),
    ]:
        for m in re.finditer(rx, text):
            out.append((line_of(m.start()), code, msg))
    return sorted(set(out))

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("paths", nargs="*", default=["."])
p.add_argument("--max-fn-lines", type=int, default=60)
p.add_argument("--max-findings", type=int, default=40, help="print at most this many findings")
p.add_argument("--strict", action="store_true")
a = p.parse_args()

total, shown = {}, 0
for f in sorted(set(files(a.paths))):
    for line, code, msg in scan(f, a.max_fn_lines):
        if shown < a.max_findings:
            print(f"{f}:{line}: {code} {msg}")
            shown += 1
        total[code] = total.get(code, 0) + 1
if sum(total.values()) > shown:
    print(f"(+{sum(total.values()) - shown} more findings not shown)")
print("\nsummary: " + (", ".join(f"{k}={v}" for k, v in sorted(total.items())) or "no findings"))
sys.exit(1 if (a.strict and total) else 0)
