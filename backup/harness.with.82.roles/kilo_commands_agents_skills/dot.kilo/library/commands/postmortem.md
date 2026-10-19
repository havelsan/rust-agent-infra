---
description: "[Infra / Ops] Review and action items with owners"
agent: team-leader
---
Run `kctx run postmortem $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /postmortem <incident#> [--blameless yes]
Chain: @incident-manager -> @site-reliability-engineer -> @team-leader -> @philosopher
Output: Review and action items with owners. Default gates: review, QA, security.
