---
description: "[Java→Rust] Module order, interop plan, feature-flag and rollback plan"
agent: team-leader
---
Run `kctx run plan-migration $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /plan-migration <system> [--strategy strangler/big-bang/rewrite] [--order <modules>] [--flags]
Chain: @project-manager -> @team-leader -> @software-architect
Output: Module order, interop plan, feature-flag and rollback plan. Default gates: review, QA, security.
