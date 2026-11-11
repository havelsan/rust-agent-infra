---
name: architecture-assessment
description: Assess the real Rust workspace architecture against the design - layers, cycles, drift - with severity. Use for Architect checkpoints and structure reviews.
---

# architecture-assessment

Architecture is what the code actually does, not what the diagram says. The assessment compares the two.

## Procedure

1. Read the intended architecture: wiki pages `Architecture Overview`, the `ADR-*` pages, and the requirements (`gitea-wiki`).
2. Take the snapshot of the actual code:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/architecture-assessment/scripts/arch_snapshot.py <workspace-root> [--layers layers.toml]
```

It lists crates, layers, local dependencies, dependency counts, and size. It flags a dependency that points from an inner layer to an outer layer and any dependency cycle. Layer rules come from `layers.toml` (made by `ddd-clean-architecture`).
3. Look beyond the script: modules that do two jobs, domain code that uses I/O types, traits that nobody implements, a crate that grew far beyond the others, external dependencies that skip the planned boundary.
4. Check `principles-check` items that affect structure: SOLID and the project principles.
5. Write the findings as `severity | location | finding | recommended action` to the wiki page `Architecture Status` (see `architecture-wiki`). Use these severities:
   - **high**: boundary broken, cycle, requirement cannot be met.
   - **medium**: drift that gets more expensive each week.
   - **low**: naming, tidiness.
6. Comment on the issue with the counts and the page. Propose follow-up issues but do not create them. The Coordinator does.

## Rules

- A decision that changes the intended architecture needs an ADR and Human approval. Do not silently update the overview page to match the code.
- Say what you could not check.

## Steps (split points)

Use with `step-protocol`. 1. Wiki intent (`gitea-wiki` slices) and `graph.sh report`. 2. Snapshot. 3. One layer or crate group per step, reading only cited lines. 4. Write findings.
