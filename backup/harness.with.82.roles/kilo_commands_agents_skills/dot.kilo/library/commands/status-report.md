---
description: "[Core] Progress, blockers, risks"
agent: team-leader
---
Run `kctx run status-report $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /status-report [--period week/sprint/milestone] [--audience po/team]
Chain: @team-leader -> @project-manager
Output: Progress, blockers, risks. Default gates: review, QA, security.
