---
name: graph-memory
description: Find code, modules, requirements, and how they connect by querying a graphify knowledge graph instead of reading files. Use it before opening or grepping source files, when asked how things relate, and after code changes to refresh the graph.
---

# graph-memory

The graph is long-term memory of the project (level L3). A query returns a small subgraph with `file:line` references, so you read only the lines you need.

```bash
GR=$RUST_AGENT_INFRA_DIR/harness/base-skills/graph-memory/scripts/graph.sh
$GR status                      # exists? stale?
$GR report 60                   # first 60 lines: main concepts, god nodes
$GR ask "where is the policy update done" 1500   # 1500 = token budget of the answer
$GR path PolicyNet ReplayBuffer # how two things connect
$GR explain SacAgent            # role of one node
$GR build                       # refresh after code changes (graphify update .)
```

## Procedure

1. At the start of a code task: `status`, then `report` (once per issue).
2. Ask the graph, then open only the cited lines with `rt.sh read` or `mem.py slice`.
3. After you change code or docs: `build`. Reviewer and Architect roles do it before they start.
4. Write what you learn (file, function) into `mem.py note`. Do not paste graph output into notes.

## Rules

- Graph first, grep second. Without a graph, `ask` falls back to a capped grep.
- A graph is a map, not proof. Read the cited code before you change it.
- `needs_update` means stale. Rebuild before you trust relationship answers.
- Build needs the graphify CLI: `uv tool install graphifyy`. If the first build fails, run `/graphify .` once in the assistant.
