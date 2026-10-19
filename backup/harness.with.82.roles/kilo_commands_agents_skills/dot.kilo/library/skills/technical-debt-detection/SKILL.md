---
name: technical-debt-detection
description: "Find duplication, complexity, dead code, TODOs and layering violations and rank them."
---
Script: `bash .kilo/skills/scripts/debt_scan.sh` (run with --dry-run first). debt_scan.sh combines clippy, complexity metrics, duplicate detection and TODO scans into a ranked report
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
