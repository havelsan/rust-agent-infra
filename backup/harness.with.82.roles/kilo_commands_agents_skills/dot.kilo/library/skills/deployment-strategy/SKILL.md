---
name: deployment-strategy
description: "Run rolling, blue-green and canary deployments with automatic rollback on SLO breach."
---
Script: `bash .kilo/skills/scripts/deploy.sh` (run with --dry-run first). deploy.sh performs the chosen rollout, watches health checks, and rolls back on failure
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
