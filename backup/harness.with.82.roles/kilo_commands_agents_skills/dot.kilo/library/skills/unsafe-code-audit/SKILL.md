---
name: unsafe-code-audit
description: "Review each `unsafe` block for soundness and justification."
---
Script: `bash .kilo/skills/scripts/unsafe_report.sh` (run with --dry-run first). unsafe_report.sh runs cargo geiger, lists unsafe usage per crate, and checks safety comments
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
