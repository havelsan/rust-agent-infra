---
description: "[Infra / Ops] Drift report against the configuration baseline"
agent: team-leader
---
Run `kctx run env-drift-check $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /env-drift-check [--env <name>] [--baseline <tag>]
Chain: @configuration-manager -> @devops-engineer
Output: Drift report against the configuration baseline. Default gates: review, QA, security.
