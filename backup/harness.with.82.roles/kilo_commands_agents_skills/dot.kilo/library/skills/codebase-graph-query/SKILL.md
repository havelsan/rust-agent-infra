---
name: codebase-graph-query
description: "Answer structure questions (who calls what, where is X, what depends on Y) from the graphify graph before grepping source files; falls back to a keyword search when no graph exists."
---
Script: `bash .kilo/skills/scripts/graphify_query.sh` (run with --dry-run first). graphify_query.sh runs graphify query against graphify-out/graph.json with a token budget and falls back to rtk grep or grep when the graph is missing
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
Use: graphify query "<q>" --graph graphify-out/graph.json --budget 600; graphify path "A" "B"; graphify explain "X". Edges tagged INFERRED or AMBIGUOUS must be checked in the source before you rely on them.
