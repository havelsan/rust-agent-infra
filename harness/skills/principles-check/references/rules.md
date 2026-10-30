# Project principles checklist

Sources: `$RUST_DEV_ENV/reference-projects/PRINCIPLES.md` (Elon Musk's recommendations, SOLID, NASA's 10 rules) and `COMMON_MISTAKES.md`. Read both files in full before a check. This file only maps them to checks.

## What the scanner reports (`rust_rules_scan.py`)

| Code | Check | Related rule |
| --- | --- | --- |
| N1 | Direct recursion | NASA 1: simple control flow |
| N2 | `loop {}` or `while true` without a visible bound or exit | NASA 2: bounded loops |
| N4 | Function longer than 60 lines | NASA 4: short functions |
| N7 | `unwrap()`, `expect()`, `panic!`, `todo!`, `unimplemented!` outside tests | NASA 7: handle errors, validate inputs |
| N9 | `unsafe` block or function | NASA 9: restrict pointer use |
| N10 | `#[allow(...)]` that hides warnings; `static mut` | NASA 10: zero warnings; NASA 6: small scope |

The scanner is a heuristic. A hit is a question for the reviewer, not a verdict.

## What only a reader can check

- Musk's recommendations: question each requirement, delete parts that are not needed, simplify, then speed up, then automate. Look for features nobody asked for and code that exists "just in case".
- SOLID: one reason to change per type, extension without edits, substitutable implementations, small traits, dependency on abstractions.
- Items listed in `COMMON_MISTAKES.md`.
