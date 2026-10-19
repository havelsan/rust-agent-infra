---
name: defect-triage
description: "Classify, deduplicate, prioritize and route defects."
---
Script: `python3 .kilo/skills/scripts/bug_triage.py` (run with --dry-run first). bug_triage.py sets severity and component labels, finds duplicates, and assigns an owner
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
