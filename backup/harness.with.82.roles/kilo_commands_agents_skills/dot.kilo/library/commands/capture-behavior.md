---
description: "[Java→Rust] Characterization tests against the running Java system"
agent: team-leader
---
Run `kctx run capture-behavior $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /capture-behavior <module> [--method golden/contract/db-diff] [--env <url>]
Chain: @software-test-development-engineer -> @software-testing-engineer -> @software-quality-assurance-engineer
Output: Characterization tests against the running Java system. Default gates: review, QA, security.
