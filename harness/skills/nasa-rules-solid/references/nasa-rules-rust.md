# NASA's "Power of Ten" rules applied to Rust

Always read the project's `PRINCIPLES.md` too. It has priority.

| # | Rule | In Rust |
| ---: | --- | --- |
| 1 | Simple control flow, no recursion | No recursion. Use loops with explicit stacks if a tree must be walked. Avoid deep `match` nesting |
| 2 | Loops have a fixed upper bound | Iterate over bounded collections or ranges. For `loop`, add a counter or a bounded source and a clear exit |
| 3 | No dynamic allocation after start-up | Where the requirement demands it: allocate buffers at start (`Vec::with_capacity`), reuse them, avoid growth in the main loop. State the exception in an ADR for ordinary software |
| 4 | Functions about 60 lines or less | Split by purpose. One function does one thing |
| 5 | Average two assertions per function | Validate inputs and invariants (`debug_assert!` for internal invariants, `Result` for external input). Test assertions count in tests |
| 6 | Smallest possible scope for data | Declare variables at first use. No `static mut`. Prefer immutable bindings |
| 7 | Check every result and every parameter | No ignored `Result` (`#[must_use]` is on by default). No `unwrap`/`expect`/`panic!`. Validate parameters at the border |
| 8 | Limited preprocessor | Limit macros. Write macros only when a function cannot do the job. Limit `cfg` attributes |
| 9 | Restrict pointers | No `unsafe`. No raw pointers. If unavoidable, isolate in one small module with a written safety argument |
| 10 | All warnings on, zero warnings, static analysis | `clippy -D warnings`, `cargo fmt --check`, workspace lints, and `cargo audit` in CI |

## Common deviations that are acceptable (with a written reason)

- `expect()` in `main` for start-up configuration, with a message that says what is missing.
- Recursion in a data structure whose depth is bounded by a documented constant.
- Allocation in non-real-time code.
