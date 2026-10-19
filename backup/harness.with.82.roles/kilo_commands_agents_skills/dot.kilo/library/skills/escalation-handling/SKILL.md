---
name: escalation-handling
description: "Summarize a blocker with options and a recommendation for the Product Owner, and track the decision."
---
Script: `python3 .kilo/skills/scripts/escalate.py` (run with --dry-run first). escalate.py builds the options summary, assigns the issue to the PO, and records the decision when the PO replies
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
