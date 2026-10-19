---
name: role-handoff-protocol
description: "Write a structured handoff comment (inputs consumed, artifacts produced, status, open questions, next role) so the next agent can start without re-reading the thread."
---
Script: `python3 .kilo/skills/scripts/handoff.py` (run with --dry-run first). handoff.py posts the handoff block, sets the next-role label, and fails if a declared artifact path is missing
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
