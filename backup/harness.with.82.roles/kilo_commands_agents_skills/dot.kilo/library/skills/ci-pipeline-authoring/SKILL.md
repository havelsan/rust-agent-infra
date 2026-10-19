---
name: ci-pipeline-authoring
description: "Write and maintain Gitea Actions pipelines: build, test, lint, audit, release."
---
Script: `python3 .kilo/skills/scripts/gen_workflow.py` (run with --dry-run first). gen_workflow.py generates workflow YAML from a policy file and validates it before commit
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
