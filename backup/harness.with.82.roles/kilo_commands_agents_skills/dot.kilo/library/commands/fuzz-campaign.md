---
description: "[Quality / Security] Fuzz targets, crash triage"
agent: team-leader
---
Run `kctx run fuzz-campaign $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /fuzz-campaign --target <fn/parser> [--duration 4h] [--corpus <dir>]
Chain: @software-test-development-engineer -> @application-security-engineer
Output: Fuzz targets, crash triage. Default gates: review, QA, security.
