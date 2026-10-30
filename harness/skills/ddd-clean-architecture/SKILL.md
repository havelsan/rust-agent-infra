---
name: ddd-clean-architecture
description: Define bounded contexts and layers and scaffold a four-layer Cargo workspace with layers.toml. Use when designing project or module structure.
---

# ddd-clean-architecture

Business rules change for business reasons. Databases, protocols, and frameworks change for technical reasons. Keeping them apart means one kind of change does not break the other. The layer rules are in `references/layers.md`. Read them first.

## Procedure

1. Read the requirements. List the domain terms (nouns and rules). Group them into bounded contexts: a context is a group of terms that mean one thing inside it. One context is enough for a small project.
2. Name aggregates (a cluster that changes together and keeps its own rules) and their root entities. Name the value objects. Write them in the wiki page `Domain Model`.
3. List what the domain needs from outside (storage, time, messaging). Each becomes a port trait.
4. Scaffold the workspace for a new project:

```bash
$RUST_AGENT_INFRA_DIR/harness/library/skills/ddd-clean-architecture/scripts/scaffold_workspace.sh my-project ./
```

It creates four crates (`domain`, `application`, `infrastructure`, `interface`) with the dependency direction already set, workspace lints that deny `unwrap`, `expect`, `panic`, and `unsafe`, and a `layers.toml`.
5. For several bounded contexts, repeat the four crates per context or add a module per context inside each layer. Choose the simpler option and record it in an ADR (`architecture-wiki`).
6. Verify with `architecture-assessment` (`arch_snapshot.py`). Expect no violation and no cycle.

## Decisions to record

- Why these contexts and not others.
- Which ports exist and who implements them.
- Any rule you broke on purpose, and why.

## Common mistakes

- Putting `serde` derives or database types in `domain`. Map at the border.
- One `utils` crate that every layer uses. It hides dependencies.
- Anemic domain: all logic in application services, entities as plain data. Move rules into entities and value objects.

## Steps (split points)

Use with `step-protocol`. Steps: list domain terms, choose contexts, name aggregates, list ports, scaffold, verify. One context per step.
