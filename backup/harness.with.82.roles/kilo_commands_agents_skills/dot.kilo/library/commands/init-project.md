---
description: "[Core] Cargo workspace, repo layout, CI skeleton, ADR folder, issue and label templates"
agent: team-leader
---
Run `kctx run init-project $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /init-project <name> [--layout workspace/single] [--ci gitea-actions] [--license]
Chain: @team-leader -> @software-architect -> @platform-engineer -> @devops-engineer -> @configuration-manager
Output: Cargo workspace, repo layout, CI skeleton, ADR folder, issue and label templates. Default gates: review, QA, security.
