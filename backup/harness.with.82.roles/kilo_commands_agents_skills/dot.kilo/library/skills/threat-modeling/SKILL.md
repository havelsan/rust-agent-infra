---
name: threat-modeling
description: "Identify assets, trust boundaries, threats and mitigations (STRIDE, attack trees)."
---
Script: `python3 .kilo/skills/scripts/stride_gen.py` (run with --dry-run first). stride_gen.py generates a STRIDE table per component from the architecture model and opens mitigation issues
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
