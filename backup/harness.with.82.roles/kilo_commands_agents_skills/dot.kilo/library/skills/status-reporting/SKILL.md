---
name: status-reporting
description: "Aggregate progress, blockers, risks and milestone health into a short report."
---
Script: `python3 .kilo/skills/scripts/status_report.py` (run with --dry-run first). status_report.py queries Gitea issues and milestones and renders a markdown report
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
