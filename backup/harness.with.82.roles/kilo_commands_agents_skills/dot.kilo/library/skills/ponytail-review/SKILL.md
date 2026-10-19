---
name: ponytail-review
description: "Review a change for over-engineering: needless dependencies, abstractions with one use, extra files and speculative generality; ask for the simplest version."
---
Script: `bash .kilo/skills/scripts/ponytail_diff.sh` (run with --dry-run first). ponytail_diff.sh measures added lines, new files and new Cargo dependencies against a base ref and fails when growth passes the configured limits
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
Checklist: new dependency while std or an existing crate fits? abstraction or trait with one implementation? new file or crate where a function suffices? config for a constant? reimplementing std? Ask for the simplest version that is still correct and secure; praise deletions.
