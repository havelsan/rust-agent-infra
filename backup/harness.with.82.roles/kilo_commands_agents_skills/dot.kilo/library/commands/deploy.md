---
description: "[Infra / Ops] Deployment with rollback path"
agent: team-leader
---
Run `kctx run deploy $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /deploy <service> --env <env> [--strategy rolling/blue-green/canary]
Chain: @devops-engineer -> @release-manager -> @site-reliability-engineer
Output: Deployment with rollback path. Default gates: review, QA, security.
