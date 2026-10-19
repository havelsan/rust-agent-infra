---
description: "[Token tools] Code graph (graph.json, GRAPH_REPORT.md) and a short architecture note"
agent: team-leader
---
Run `kctx run graph-build $ARGUMENTS` in the shell and report only its short JSON result. Do not load other files.
Signature: /graph-build [<path>] [--force]
Chain: @software-architect -> @documentation-engineer
Output: Code graph (graph.json, GRAPH_REPORT.md) and a short architecture note. Default gates: review, QA, security.
