---
name: rust-crate-architecture
description: "Design the workspace layout: crate boundaries, layering, visibility, feature flags and dependency direction."
---
Script: `bash .kilo/skills/scripts/crate_graph.sh` (run with --dry-run first). crate_graph.sh runs cargo metadata, draws the crate graph, and flags cycles and layer violations
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
