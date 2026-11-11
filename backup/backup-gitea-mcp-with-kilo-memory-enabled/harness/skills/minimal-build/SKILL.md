---
name: minimal-build
description: Write the least code that meets the requirement, using a ponytail-style ladder before any new code, and keep each step's diff small. Use it before writing code, a new function, a dependency, or a document section, and when reviewing a diff for over-building.
---

# minimal-build

Based on the ponytail skill (DietrichGebert/ponytail) and the project principle "question every requirement, delete before you add". Less code means fewer tests, fewer defects, and smaller steps. Laziness applies to the solution only. It never applies to reading, validation, error handling, or safety.

## The ladder: stop at the first rung that holds

1. Does this need to exist? Which requirement ID asks for it? No ID: do not build it.
2. Is it already in the repo? Search first (`graph.sh ask`).
3. Does the Rust standard library do it?
4. Does a vetted crate do it? Only with at least 10000 all-time downloads (`crate-download-filter`).
5. Write the smallest new code. One function, one test, no extra options, no "future use" traits.

Record the rung you reached in the step result: `rung 3: std::iter`.

## Size check per step

```bash
$RUST_AGENT_INFRA_DIR/harness/base-skills/minimal-build/scripts/diff_size.sh
```

More than 150 added lines in one step means: split the step or cut code. Change the limit with `STEP_MAX_ADDED`.

## Review for over-building

Reviewer and Architect roles ask of each hunk: which requirement needs this? Report unused parameters, traits with one implementation and no second planned, config switches nobody asked for, copied helpers.

## Deferred shortcuts

If you leave something out on purpose (for example caching), write it as a line in the wiki page `Technical Debt`: what, why, trigger to revisit. Do not hide it in code.

## With the ponytail plugin installed

Use `/ponytail-review` on a diff, `/ponytail-audit` on the repo, `/ponytail-debt` to list deferred shortcuts. Install: copy the skills from github.com/DietrichGebert/ponytail to `.kilo/skills/`. This skill works without it.
