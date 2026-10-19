---
description: "[Java→Rust] Canary rollout, SLO watch, go/no-go (PO approval)"
agent: team-leader
---
Run `kctx run cutover-module $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /cutover-module <module> [--rollout canary:N%/full] [--slo <name>] [--rollback-on]
Chain: @release-manager -> @site-reliability-engineer -> @devops-engineer -> @incident-manager
Output: Canary rollout, SLO watch, go/no-go (PO approval). Product Owner approval at the end.
