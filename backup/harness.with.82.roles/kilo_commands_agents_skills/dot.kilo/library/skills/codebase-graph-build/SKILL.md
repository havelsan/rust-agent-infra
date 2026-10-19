---
name: codebase-graph-build
description: "Build or refresh the knowledge graph of the code base with graphify, so agents can query structure instead of reading files."
---
Script: `bash .kilo/skills/scripts/graphify_build.sh` (run with --dry-run first). graphify_build.sh runs the graphify build command on a folder (default graphify update, AST only, no API calls), creates a Rust-friendly .graphifyignore if missing, and reports graph.json node and edge counts
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
graphify update . re-extracts code only (AST, local, no API calls). Docs and PDFs need an LLM backend: graphify extract <dir> --backend <name>. Optional: graphify hook install rebuilds on commit. Commit graphify-out/ but ignore manifest.json and cost.json.
