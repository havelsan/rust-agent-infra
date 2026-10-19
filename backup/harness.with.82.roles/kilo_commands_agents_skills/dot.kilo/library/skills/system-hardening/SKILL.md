---
name: system-hardening
description: "Harden operating systems and network services against known attack classes."
---
Script: `bash .kilo/skills/scripts/hardening_scan.sh` (run with --dry-run first). hardening_scan.sh checks OS and service settings against a CIS-style baseline and lists deviations
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
