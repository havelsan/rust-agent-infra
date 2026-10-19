---
description: "[Core] Patch release and rollback plan"
agent: team-leader
---
Run `kctx run hotfix $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /hotfix <incident#> --version <semver> [--rollback-plan]
Chain: @incident-manager -> @site-reliability-engineer -> @software-development-engineer -> @release-manager
Output: Patch release and rollback plan. Default gates: review, QA, security.
