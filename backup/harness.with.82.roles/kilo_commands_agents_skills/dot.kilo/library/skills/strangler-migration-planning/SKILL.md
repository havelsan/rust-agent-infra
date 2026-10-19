---
name: strangler-migration-planning
description: "Plan incremental migration: module ordering, feature flags, rollback points and cutover criteria."
---
Script: `python3 .kilo/skills/scripts/migration_plan.py` (run with --dry-run first). migration_plan.py orders modules by coupling and risk and creates the migration epic with per-module issues
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
