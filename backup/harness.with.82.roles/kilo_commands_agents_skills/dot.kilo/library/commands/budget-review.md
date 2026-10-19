---
description: "[Business] Cost versus plan and forecast"
agent: team-leader
---
Run `kctx run budget-review $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /budget-review [--period quarter/year] [--include cloud,compute,headcount]
Chain: @financial-analyst -> @finance-manager-cfo -> @project-manager
Output: Cost versus plan and forecast. Default gates: review, QA, security.
