---
name: clinical-safety-checking
description: "Check medical terminology, safety thresholds and compliance with clinical guidelines."
---
Script: `python3 .kilo/skills/scripts/threshold_check.py` (run with --dry-run first). threshold_check.py compares configured limits and outputs with guideline values and flags violations
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
