---
description: "[Java→Rust] Idiomatic Rust module passing the characterization tests"
agent: team-leader
---
Run `kctx run port-module $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /port-module <module> --from java:<path> --to rust:<crate> [--strategy strangler/rewrite] [--api-compat strict/relaxed] [--parity-tests <suite>] [--ui keep/redesign]
Chain: @software-development-engineer/@backend-developer -> @software-review-engineer -> @software-test-development-engineer
Output: Idiomatic Rust module passing the characterization tests. Default gates: review, QA, security.
