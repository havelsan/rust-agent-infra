---
name: approval-gate-management
description: "Enforce review, QA, security, release and Product Owner gates before an issue can close or a PR can merge."
---
Script: `python3 .kilo/skills/scripts/gate_check.py` (run with --dry-run first). gate_check.py checks required labels and approvals on an issue or PR and returns pass or fail with the missing gates
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
