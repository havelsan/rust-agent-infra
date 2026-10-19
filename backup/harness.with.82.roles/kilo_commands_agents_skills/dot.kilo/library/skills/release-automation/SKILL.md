---
name: release-automation
description: "Automate versioning, changelog, tagging, signing and artifact publishing."
---
Script: `bash .kilo/skills/scripts/release.sh` (run with --dry-run first). release.sh bumps SemVer, tags, builds and signs artifacts, and attaches them to the Gitea release
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
