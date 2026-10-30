---
name: requirements-wiki-builder
description: Build and update the requirements index in the wiki from requirement lines. Use when the Coordinator asks the Analyzer to build or refresh the requirements wiki.
---

# requirements-wiki-builder

Later roles (Architect, Developer, Tester, Qa) read requirements from the wiki, not from the long issue threads. A clean index lets them cite `REQ-12` instead of copying text.

## Procedure

1. Collect requirement text from the issues and documents named by the Coordinator. Give each requirement a stable ID (`REQ-001`). Never renumber existing IDs. Keep a removed requirement as `status: withdrawn`.
2. Put the requirements in a working file, one per line:

```
REQ-001: The system shall log every command within 1 s. [status: accepted] [source: #12]
```

3. Run `requirements-quality-check` first. Do not publish contradictory text without marking it.
4. Publish:

```bash
python3 $RUST_AGENT_INFRA_DIR/harness/library/skills/requirements-wiki-builder/scripts/build_requirements_wiki.py reqs.md [--by-prefix] [--dry-run]
```

The script writes `Requirements Index` (and `Requirements <PREFIX>` pages with `--by-prefix`).
5. Read the current wiki first (`gitea-wiki get "Requirements Index"`) and merge. The script replaces the whole page, so the working file must contain every existing requirement.
6. Comment on the issue with the page names and the number of requirements added or changed.

## Status values

`draft`, `accepted`, `implemented`, `verified`, `withdrawn`. The Human sets `accepted`. The Analyzer does not.

## Steps (split points)

Use with `step-protocol`. One step per 20 requirements: collect, quality-check. Last step: merge with the current page and publish.
