---
description: "[Quality / Security] Vulnerability and license report"
agent: team-leader
---
Run `kctx run dependency-audit $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /dependency-audit [--tools cargo-audit,cargo-deny] [--licenses allow-list]
Chain: @application-security-engineer -> @legal-counsel
Output: Vulnerability and license report. Default gates: review, QA, security.
