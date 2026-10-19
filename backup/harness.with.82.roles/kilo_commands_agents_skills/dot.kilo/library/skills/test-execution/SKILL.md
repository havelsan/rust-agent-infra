---
name: test-execution
description: "Run unit, integration and end-to-end suites and report results."
---
Script: `bash .kilo/skills/scripts/run_tests.sh` (run with --dry-run first). run_tests.sh runs cargo nextest, outputs JUnit, and attaches failures to the issue
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
