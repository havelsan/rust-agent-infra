---
description: "[Infra / Ops] Gitea Actions pipeline"
agent: team-leader
---
Run `kctx run setup-ci $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /setup-ci [--pipeline build,test,lint,audit,release] [--runners]
Chain: @devops-engineer -> @platform-engineer -> @configuration-manager
Output: Gitea Actions pipeline. Default gates: review, QA, security.
