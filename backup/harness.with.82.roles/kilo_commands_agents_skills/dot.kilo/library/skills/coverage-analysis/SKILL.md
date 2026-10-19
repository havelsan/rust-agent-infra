---
name: coverage-analysis
description: "Measure coverage and identify untested critical paths."
---
Script: `bash .kilo/skills/scripts/coverage.sh` (run with --dry-run first). coverage.sh runs cargo llvm-cov, compares to the threshold, and lists uncovered functions
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
