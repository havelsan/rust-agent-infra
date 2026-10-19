# Rust code review checklist

Review the diff against the issue and the requirement IDs first, then the code.

## 1. Fit with the task
- Does the change do what the issue and the requirements say, and nothing more?
- Is every requirement ID in the issue covered by a test?
- Are there unrelated changes, dead code, or leftover debug output?

## 2. Architecture
- Is each type in the right layer? Does any inner crate import an outer one?
- Are ports defined inside and implemented outside?
- Does a new dependency pass `crate-download-filter` and fit the ADRs?

## 3. Correctness and safety
- Are all errors handled and typed? No `unwrap`, `expect`, `panic!`, `todo!`.
- Are inputs validated at the border? Are invalid states impossible to construct?
- Are integer overflow, empty input, and boundary values handled?
- Is there any `unsafe`? Is there a written safety argument?
- Are loops bounded? Is there any recursion?

## 4. Tests
- Do tests fail without the change? Do they cover boundaries and error paths?
- Are tests deterministic (no real time, network, or random without a seed)?

## 5. Readability
- Names match the domain language. Functions are about 60 lines or shorter.
- Comments explain why, not what.
- Public items have doc comments.

## 6. Principles
- `PRINCIPLES.md` and `COMMON_MISTAKES.md` checked (`principles-check`).

## Finding format

`severity | file:line | problem | suggested fix`, with severity `blocker` (must fix), `major` (should fix), `minor` (optional).
A review with no blocker and no major finding is "approved".
