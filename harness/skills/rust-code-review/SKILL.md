---
name: rust-code-review
description: Review Rust changes with automatic checks and a checklist and report findings by severity. Use for Reviewer tasks.
---

# rust-code-review

A review catches what the author cannot see. Automatic checks remove the easy findings, so the reviewer's time goes to design and meaning.

## Procedure

1. Read the issue, the linked requirements, and the diff. Know what the change should do before you read how it does it.
2. Run the automatic checks. They write `review-report.md`:

```bash
$RUST_AGENT_INFRA_DIR/harness/library/skills/rust-code-review/scripts/review_gate.sh <project-dir>
```

Any FAIL is a `blocker` until fixed. Tools that are not installed show as SKIPPED. Say so in the review.

3. Read the code with `references/review-checklist.md`. Ask of each hunk which requirement needs it (`minimal-build`). Check the layers, error handling, tests, and the principles (`principles-check`, `nasa-rules-solid`).
4. For each module in references directory,  run the module according to the "Runbook per module" as described below. Never load more than one module at once.
5. Write findings as `severity | file:line | problem | suggested fix`. Use `blocker`, `major`, `minor`. Quote the line when it is not obvious.
6. Decide: **approved** (no blocker, no major) or **changes requested**. Comment on the issue (`issue-comment-protocol`) with the decision, counts, and the top findings. Put long reports in the wiki.
7. Hand the issue back: label `to:Coordinator` (`issue-completion`). Do not fix the code yourself. A reviewer who edits the code reviews their own work.

## Rules

- Review the change, not the author.
- Give a reason and a fix for each finding.
- For each finding create a distinct issue for the Coordinator: `issue_write` `create`, labels `["to:Coordinator", "status:todo"]`, body `Finding of #<n>: <severity> | <file:line> | <problem> | <fix>`.
- Do not approve what you did not check. Say which parts you did not review.
- Praise is allowed when a solution is good. It tells the Developer what to repeat.

## Steps (split points)

Use with `step-protocol`. 1. Automatic gate. 2. Read the diff per file or per 200 changed lines, one step each, `note` findings as you go. 3. Decision comment.


## Runbook per module (one module at a time)

1. Pick modules from the table below, highest priority first.
2. Load ONE module. Review the code against it. Output a short findings list: `rule-id | location | fix`.
3. Review the code. If you find an issue, give a reason and a fix for each finding. For each finding create a distinct issue for the Coordinator: `issue_write` `create`, labels `["to:Coordinator", "status:todo"]`, body `Finding of #<n>: <severity> | <file:line> | <problem> | <fix>`.
4. Unload the module (start a fresh context or drop it), keep only the findings list.
5. Load the next module. Repeat.


Budget rule for a 32k window: router/findings ~3k + one module <=8k + code under review + answer. Keep the code under review below ~10k tokens per pass; for big files review one function or module at a time.

## Which modules for which task

- Writing/reviewing any Rust: 01-02 (ownership), 03-04 (errors)
- Async/Tokio code: async modules, then concurrency
- unsafe/FFI: unsafe module, then concurrency
- Library/public API: api-design, type-safety, traits, naming, docs
- Hot-path performance: memory, performance, compiler-opt, collections
- Project hygiene / CI: project-structure, linting, testing

## Modules

| # | Module | Priority | Rules | ~Tokens |
|---|-------|----------|-------|---------|
| 01 | `rust-01-ownership-1of2` — Ownership & Borrowing | CRITICAL | 6 | 5.6k |
| 02 | `rust-02-ownership-2of2` — Ownership & Borrowing | CRITICAL | 6 | 5.9k |
| 03 | `rust-03-errors-1of2` — Error Handling | CRITICAL | 6 | 6.8k |
| 04 | `rust-04-errors-2of2` — Error Handling | CRITICAL | 6 | 6.8k |
| 05 | `rust-05-memory-1of3` — Memory Optimization | CRITICAL | 6 | 6.5k |
| 06 | `rust-06-memory-2of3` — Memory Optimization | CRITICAL | 5 | 6.2k |
| 07 | `rust-07-memory-3of3` — Memory Optimization | CRITICAL | 6 | 7.2k |
| 08 | `rust-08-unsafe` — Unsafe Code | CRITICAL | 7 | 7.2k |
| 09 | `rust-09-api-design-1of3` — API Design | HIGH | 5 | 6.8k |
| 10 | `rust-10-api-design-2of3` — API Design | HIGH | 6 | 7.1k |
| 11 | `rust-11-api-design-3of3` — API Design | HIGH | 6 | 6.9k |
| 12 | `rust-12-async-1of4` — Async/Await | HIGH | 5 | 6.5k |
| 13 | `rust-13-async-2of4` — Async/Await | HIGH | 4 | 5.5k |
| 14 | `rust-14-async-3of4` — Async/Await | HIGH | 4 | 5.3k |
| 15 | `rust-15-async-4of4` — Async/Await | HIGH | 5 | 6.2k |
| 16 | `rust-16-concurrency` — Concurrency | HIGH | 4 | 3.5k |
| 17 | `rust-17-compiler-opt-1of2` — Compiler Optimization | HIGH | 6 | 7.0k |
| 18 | `rust-18-compiler-opt-2of2` — Compiler Optimization | HIGH | 6 | 7.4k |
| 19 | `rust-19-numeric` — Numeric & Arithmetic Safety | HIGH | 5 | 4.8k |
| 20 | `rust-20-type-safety-1of2` — Type Safety | MEDIUM | 6 | 6.6k |
| 21 | `rust-21-type-safety-2of2` — Type Safety | MEDIUM | 7 | 6.4k |
| 22 | `rust-22-traits-generics` — Trait & Generics Design | MEDIUM | 6 | 6.8k |
| 23 | `rust-23-conversions-const` — Conversions + Const & Compile-Time | MEDIUM | 7 | 5.4k |
| 24 | `rust-24-serde` — Serde | MEDIUM | 8 | 7.2k |
| 25 | `rust-25-pattern-matching` — Pattern Matching | MEDIUM | 5 | 3.9k |
| 26 | `rust-26-macros` — Macros | MEDIUM | 8 | 7.5k |
| 27 | `rust-27-closures` — Closures | MEDIUM | 5 | 4.8k |
| 28 | `rust-28-collections` — Collections | MEDIUM | 4 | 4.1k |
| 29 | `rust-29-naming-1of2` — Naming Conventions | MEDIUM | 9 | 6.3k |
| 30 | `rust-30-naming-2of2` — Naming Conventions | MEDIUM | 7 | 6.6k |
| 31 | `rust-31-testing-1of3` — Testing | MEDIUM | 6 | 5.7k |
| 32 | `rust-32-testing-2of3` — Testing | MEDIUM | 4 | 5.0k |
| 33 | `rust-33-testing-3of3` — Testing | MEDIUM | 5 | 5.0k |
| 34 | `rust-34-docs-1of2` — Documentation | MEDIUM | 6 | 5.7k |
| 35 | `rust-35-docs-2of2` — Documentation | MEDIUM | 6 | 5.9k |
| 36 | `rust-36-observability` — Observability | MEDIUM | 7 | 6.4k |
| 37 | `rust-37-performance-1of2` — Performance Patterns | MEDIUM | 7 | 6.7k |
| 38 | `rust-38-performance-2of2` — Performance Patterns | MEDIUM | 6 | 6.6k |
| 39 | `rust-39-project-structure-1of2` — Project Structure | LOW | 7 | 6.4k |
| 40 | `rust-40-project-structure-2of2` — Project Structure | LOW | 7 | 6.3k |
| 41 | `rust-41-linting-1of2` — Clippy & Linting | LOW | 6 | 5.4k |
| 42 | `rust-42-linting-2of2` — Clippy & Linting | LOW | 7 | 6.2k |
| 43 | `rust-43-anti-patterns-1of2` — Anti-patterns | REFERENCE | 8 | 7.1k |
| 44 | `rust-44-anti-patterns-2of2` — Anti-patterns | REFERENCE | 7 | 7.5k |
