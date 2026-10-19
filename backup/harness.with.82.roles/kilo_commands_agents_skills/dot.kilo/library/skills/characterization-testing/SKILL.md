---
name: characterization-testing
description: "Record the legacy system's real behavior as golden tests before changing it."
---
Script: `python3 .kilo/skills/scripts/capture_golden.py` (run with --dry-run first). capture_golden.py replays inputs against the legacy system and stores outputs as golden files
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
