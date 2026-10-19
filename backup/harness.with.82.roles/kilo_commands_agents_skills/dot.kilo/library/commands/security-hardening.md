---
description: "[Java→Rust] Hardening report and fix issues"
agent: team-leader
---
Run `kctx run security-hardening $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /security-hardening <module> [--checks unsafe,deps,authn,authz]
Chain: @security-engineer -> @application-security-engineer -> @cloud-security-engineer
Output: Hardening report and fix issues. Default gates: review, QA, security.
