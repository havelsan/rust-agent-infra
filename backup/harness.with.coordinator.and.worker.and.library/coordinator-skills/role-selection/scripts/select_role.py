#!/usr/bin/env python3
"""Suggest a Worker role for a task description (keyword heuristic).

Usage: select_role.py "text"   |   select_role.py --issue-file body.md
The result is a suggestion. The Coordinator decides.
"""
import argparse
import re
import sys

KEYWORDS = {
    "Analyzer": ["analyze", "analyse", "consistency", "ambiguity", "ambiguous", "contradiction", "requirement",
                 "requirements", "completeness", "ste100", "validate document", "check issue", "clarity"],
    "Researcher": ["crate", "crates", "library", "libraries", "framework", "dependency", "package", "evaluate option",
                   "find a ready", "downloads"],
    "Architect": ["architecture", "layer", "layers", "bounded context", "adr", "module boundary", "dependency graph",
                  "component", "structure", "coupling"],
    "Developer": ["implement", "code", "function", "feature", "bug", "fix", "refactor", "struct", "trait", "module",
                  "algorithm"],
    "Designer": ["ui", "ux", "screen", "layout", "wireframe", "user interface", "usability", "mockup", "design system"],
    "Reviewer": ["review", "code review", "clippy", "lint", "pull request", "audit code", "style"],
    "Tester": ["test", "tests", "unit test", "integration test", "coverage", "test case", "test cases", "property test"],
    "Qa": ["release", "rpm", "deb", "package build", "final check", "acceptance", "quality assurance", "installer"],
}

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("text", nargs="?")
p.add_argument("--issue-file")
a = p.parse_args()
text = a.text or (open(a.issue_file, encoding="utf-8").read() if a.issue_file else sys.stdin.read())
low = text.lower()

scores = {}
for role, words in KEYWORDS.items():
    hits = [w for w in words if re.search(r"\b" + re.escape(w) + r"\b", low)]
    if hits:
        scores[role] = hits
if not scores:
    print("No role matched. Ask the Human or split the task.")
    sys.exit(1)
for role, hits in sorted(scores.items(), key=lambda kv: -len(kv[1])):
    print(f"{role}: {len(hits)} hit(s) -> {', '.join(hits)}")
if len([r for r, h in scores.items() if len(h) == max(map(len, scores.values()))]) > 1:
    print("Tie or mixed task: split it into one issue per role.")
