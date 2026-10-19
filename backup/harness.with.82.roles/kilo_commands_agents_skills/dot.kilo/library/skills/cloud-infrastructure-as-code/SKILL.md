---
name: cloud-infrastructure-as-code
description: "Define cloud networks, compute, storage and managed services declaratively with policy checks."
---
Script: `bash .kilo/skills/scripts/iac_plan.sh` (run with --dry-run first). iac_plan.sh runs OpenTofu or Terraform validate and plan, then policy and cost checks, and posts the plan to the issue
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
