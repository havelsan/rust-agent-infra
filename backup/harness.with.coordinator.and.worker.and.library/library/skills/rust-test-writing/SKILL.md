---
name: rust-test-writing
description: Write Rust unit, integration, and data-driven tests from requirements and find untested functions. Use for Tester tasks.
---

# rust-test-writing

Tests are the executable form of the requirements. The Tester works from the requirement, not from the code, so the tests can fail when the code is wrong.

## Procedure

1. Read the issue and the requirement IDs. For each requirement write down the expected behavior, the boundaries, and the error cases before reading the implementation.
2. Find what is untested:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/rust-test-writing/scripts/find_untested.py <project-dir>
```

This lists public functions that no test mentions. It is a gap finder. For line coverage use `cargo llvm-cov` or `cargo tarpaulin` if installed.
3. Choose the kind of test:
   - **Unit**: in `#[cfg(test)] mod tests` next to the code. One behavior per test.
   - **Integration**: in `tests/`. Use the public API only.
   - **Data-driven**: a table of cases for many inputs (`rust-tdd`, `references/data-driven-tests.md`).
4. Name tests by behavior (`rejects_negative_speed`). Put the requirement ID in a comment.
5. Cover the boundaries: zero, one, maximum, maximum plus one, empty, invalid, and the error path of every `Result`.
6. Make tests deterministic: no real clock, network, or global state. Use fakes behind ports.
7. Run the gate (`rust-tdd/scripts/tdd_cycle.sh`). A new test must fail when the behavior is broken. Check one case by breaking the code on purpose, then undo it.
8. Report with `issue-completion`: requirement IDs covered, number of tests added, gaps that remain.

## Rules

- Tests return `Result` and use `?`. No `unwrap()`.
- Never delete or weaken a failing test to get green. Report the defect to the Coordinator.
- If the requirement is too vague to test, say so. Return it as `blocked` for the Analyzer role.

## Steps (split points)

Use with `step-protocol`. One requirement per step: table of cases, then test code, then run. Last step: gap finder.
