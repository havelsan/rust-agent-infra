---
name: crate-search
description: Find Rust crates for a need on crates.io and drop crates under 10000 all-time downloads. Use for Researcher tasks.
---

# crate-search

Writing code that a mature crate already provides costs time and adds defects. The Researcher finds candidates, and the Architect and Developer decide.

## Procedure

1. Write the need in one sentence from the issue (for example "MQTT client, async, TLS"). Note hard constraints: `no_std`, license, async runtime, platform.
2. Search with two or three different queries (synonyms, the protocol name, the task name):

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/crate-search/scripts/search_crates.py "mqtt client" --sort downloads
```

The script drops every crate with fewer than 10000 "Downloads all time". This is a project rule, not a preference. Do not add a dropped crate to the list, even if it looks good.
3. For each remaining candidate, open the repository and check: last release date, open issues trend, license, `unsafe` use, direct dependencies, and whether it fits the constraints. Use `crate-download-filter` to re-check names you found elsewhere.
4. Report a table: `crate | version | downloads | last update | license | fit | risk`. Give a recommendation and a fallback. If nothing qualifies, say so. "No suitable crate found" is a valid result and the Developer then writes the code.
5. Comment on the issue (see `issue-comment-protocol`). Put long comparisons in the wiki.

## Rules

- Report only data you read. Do not fill in a license or date from memory.
- Prefer fewer dependencies. A crate that pulls in fifty others is a cost.
- Do not edit `Cargo.toml`. Choosing the crate is the Architect's and Developer's job.

## Steps (split points)

Use with `step-protocol`. One step per need or query. Check 3 candidates per step. Last step: the table and recommendation.
