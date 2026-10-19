---
name: security-incident-response
description: "Run security incident playbooks: containment, evidence, eradication and recovery."
---
Script: `python3 .kilo/skills/scripts/ir_playbook.py` (run with --dry-run first). ir_playbook.py executes a playbook's steps, records evidence, and updates the incident timeline
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
