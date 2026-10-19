---
name: incident-response
description: "Coordinate detection, triage, mitigation, communication and recovery during production incidents."
---
Script: `python3 .kilo/skills/scripts/incident_open.py` (run with --dry-run first). incident_open.py creates the incident issue, a timeline log and communication templates, and pages the on-call agents
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
