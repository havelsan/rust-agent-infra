---
description: "[Java→Rust] Old-versus-new diff report"
agent: team-leader
---
Run `kctx run parity-test $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /parity-test <module> [--mode shadow-traffic/replay/batch] [--tolerance] [--duration]
Chain: @software-quality-assurance-engineer -> @software-testing-engineer -> @software-test-development-engineer
Output: Old-versus-new diff report. Default gates: review, QA, security.
