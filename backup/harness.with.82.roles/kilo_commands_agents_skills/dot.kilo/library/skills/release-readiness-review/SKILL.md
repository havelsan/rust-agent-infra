---
name: release-readiness-review
description: "Check that tests, security, docs and approvals are complete before shipping, and define rollback."
---
Script: `python3 .kilo/skills/scripts/readiness_check.py` (run with --dry-run first). readiness_check.py aggregates gate status, open blockers and test results into a go/no-go checklist
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
