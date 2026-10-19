#!/usr/bin/env python3
"""List public functions that no test mentions (a gap finder, not a coverage tool).

A function counts as tested if its name appears in a #[cfg(test)] section of any src file
or in any file under tests/. For real line coverage use cargo-llvm-cov or cargo-tarpaulin.
"""
import os
import re
import sys

root = sys.argv[1] if len(sys.argv) > 1 else "."
SKIP = {"target", ".git"}
src_files, test_text = [], []
for r, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if d not in SKIP]
    for f in files:
        if not f.endswith(".rs"):
            continue
        path = os.path.join(r, f)
        text = open(path, encoding="utf-8", errors="replace").read()
        if os.sep + "tests" + os.sep in path or path.startswith("tests" + os.sep):
            test_text.append(text)
        else:
            i = text.find("#[cfg(test)]")
            if i != -1:
                test_text.append(text[i:])
            src_files.append((path, text if i == -1 else text[:i]))
tests = "\n".join(test_text)

missing = 0
for path, code in sorted(src_files):
    for m in re.finditer(r"^\s*pub(?:\([^)]*\))?\s+(?:async\s+)?(?:const\s+)?fn\s+([A-Za-z_]\w*)", code, re.M):
        name = m.group(1)
        if name in ("new", "default", "fmt", "from", "clone", "drop"):
            continue
        if not re.search(r"\b" + re.escape(name) + r"\b", tests):
            print(f"{path}:{code.count(chr(10), 0, m.start()) + 1}: pub fn {name} has no test mentioning it")
            missing += 1
print(f"\n{missing} untested public function(s)")
sys.exit(1 if missing else 0)
