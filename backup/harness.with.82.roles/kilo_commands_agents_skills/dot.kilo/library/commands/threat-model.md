---
description: "[Quality / Security] Threat model and mitigation issues"
agent: team-leader
---
Run `kctx run threat-model $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /threat-model <component> [--method stride/attack-tree] [--trust-boundary]
Chain: @security-engineer -> @security-architect -> @application-security-engineer -> @system-architect
Output: Threat model and mitigation issues. Default gates: review, QA, security.
