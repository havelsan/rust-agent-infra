---
name: support-ticket-triage
description: "Classify and route support tickets, and escalate to engineering with full context."
---
Script: `python3 .kilo/skills/scripts/ticket_triage.py` (run with --dry-run first). ticket_triage.py classifies a ticket, links related issues, and sets priority and queue
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
