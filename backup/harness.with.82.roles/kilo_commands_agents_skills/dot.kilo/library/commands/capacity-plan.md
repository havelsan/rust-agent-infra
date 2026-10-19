---
description: "[Infra / Ops] Forecast and cost model"
agent: team-leader
---
Run `kctx run capacity-plan $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /capacity-plan <service> [--horizon 6m/1y] [--growth-model]
Chain: @site-reliability-engineer -> @performance-engineer -> @financial-analyst
Output: Forecast and cost model. Default gates: review, QA, security.
