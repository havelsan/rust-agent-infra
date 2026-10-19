---
description: "[Quality / Security] Benchmarks in CI with threshold gates"
agent: team-leader
---
Run `kctx run perf-regression $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /perf-regression <crate> [--bench criterion] [--threshold 5%]
Chain: @performance-engineer -> @software-test-development-engineer
Output: Benchmarks in CI with threshold gates. Default gates: review, QA, security.
