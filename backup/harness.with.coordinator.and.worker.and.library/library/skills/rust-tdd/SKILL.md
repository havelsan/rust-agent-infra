---
name: rust-tdd
description: TDD workflow for Rust with data-driven tests and a fmt, clippy, test gate. Use when writing behavior, fixing bugs, or checking that code is green.
---

# rust-tdd

A test written first proves the requirement is understood and that the test can fail. A test written after the code often only describes what the code already does.

## Cycle

1. **Red**: write one test that states a requirement and run it. Check that it fails for the expected reason (a missing function is not the reason that counts. A wrong result is).
2. **Green**: write the smallest code that passes.
3. **Refactor**: remove duplication and improve names while the tests stay green. Check the layer rules.
4. Repeat. Commit at green.

## Gate

```bash
$RUST_AGENT_INFRA_DIR/harness/library/skills/rust-tdd/scripts/tdd_cycle.sh [-p crate] [test_filter]
```

It runs `cargo fmt --check`, `cargo clippy -D warnings`, and `cargo test`, then prints PASS or FAIL for each. A change is done only when all three pass.

## Data-driven tests

When the same check applies to many inputs, use a table of cases (see `references/data-driven-tests.md`). Cover boundaries and error cases. Name the failing row in the assertion message.

## Rules

- One behavior per test. The name says the behavior: `zero_id_is_rejected`.
- Tests return `Result` and use `?`. Do not use `unwrap()`, to match the production rules.
- A bug fix starts with a test that reproduces the bug.
- Do not change a test to make code pass. If the test is wrong, say why in the commit and the issue comment.
- Test the public behavior of a unit. Do not test private details that will change.
- No test may depend on time, network, or the order of other tests. Use a fake behind a port.
