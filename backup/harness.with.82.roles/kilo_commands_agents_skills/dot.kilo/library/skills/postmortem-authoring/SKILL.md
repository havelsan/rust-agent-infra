---
name: postmortem-authoring
description: "Run a blameless review with timeline, causes and tracked action items."
---
Script: `python3 .kilo/skills/scripts/postmortem_gen.py` (run with --dry-run first). postmortem_gen.py builds the draft from the incident timeline and opens action-item issues
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
