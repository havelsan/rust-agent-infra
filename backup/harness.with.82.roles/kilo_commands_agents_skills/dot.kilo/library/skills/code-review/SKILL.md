---
name: code-review
description: "Review PRs for correctness, architecture adherence, idiomatic Rust, maintainability and security."
---
Script: `python3 .kilo/skills/scripts/review_pr.py` (run with --dry-run first). review_pr.py fetches the diff, runs the checklist and clippy results, and posts inline comments with a verdict
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
